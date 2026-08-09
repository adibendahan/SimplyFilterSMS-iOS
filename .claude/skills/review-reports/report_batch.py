#!/usr/bin/env python3
"""Paginated fetch/dismiss/archive/delete helpers for reported_messages review."""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    import boto3
except ImportError:
    print("boto3 not installed. Run: .venv/bin/pip install boto3", file=sys.stderr)
    sys.exit(1)

TABLE = "reported_messages"
REGION = "us-east-1"
STATE_FILE = Path(__file__).parent / ".review-state.json"
REPO_ROOT = Path(__file__).resolve().parents[3]
ARCHIVE_DIR = REPO_ROOT / "data"
ARCHIVE_LATEST = ARCHIVE_DIR / "reported_messages_archive.json"


def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"dismissed": [], "cache": [], "cache_synced_at": None, "archived_at": None}


def save_state(state: dict) -> None:
    STATE_FILE.write_text(json.dumps(state, indent=2))


def dismissed_keys(state: dict) -> set[tuple[str, str]]:
    return {(d["uuid"], d["timestamp"]) for d in state.get("dismissed", [])}


def parse_item(item: dict) -> dict:
    return {
        "uuid": item["uuid"]["S"],
        "timestamp": item["timestamp"]["S"],
        "sender": item.get("sender", {}).get("S", ""),
        "body": item.get("body", {}).get("S", ""),
        "type": item.get("type", {}).get("S", ""),
    }


def scan_all() -> list[dict]:
    client = boto3.client("dynamodb", region_name=REGION)
    items: list[dict] = []
    kwargs: dict = {"TableName": TABLE}
    while True:
        response = client.scan(**kwargs)
        items.extend(parse_item(item) for item in response.get("Items", []))
        token = response.get("LastEvaluatedKey")
        if not token:
            break
        kwargs["ExclusiveStartKey"] = token
    items.sort(key=lambda r: int(r["timestamp"]) if r["timestamp"].isdigit() else 0)
    return items


def sync_cache(state: dict, force: bool = False) -> dict:
    if not force and state.get("cache") and state.get("cache_synced_at"):
        return state

    items = scan_all()
    state["cache"] = items
    state["cache_synced_at"] = datetime.now(timezone.utc).isoformat()
    save_state(state)
    return state


def pending_records(state: dict) -> list[dict]:
    dismissed = dismissed_keys(state)
    return [r for r in state.get("cache", []) if (r["uuid"], r["timestamp"]) not in dismissed]


def cmd_count(args: argparse.Namespace) -> None:
    state = sync_cache(load_state(), force=getattr(args, "refresh", False))
    pending = pending_records(state)
    print(f"Total in DynamoDB (cached): {len(state['cache'])}")
    print(f"Dismissed/processed locally: {len(state.get('dismissed', []))}")
    print(f"Pending review: {len(pending)}")
    if state.get("archived_at"):
        print(f"Last archive marked: {state['archived_at']}")
    if ARCHIVE_LATEST.exists():
        meta = json.loads(ARCHIVE_LATEST.read_text())
        print(f"Latest archive file: {ARCHIVE_LATEST} ({meta.get('count', '?')} records)")


def cmd_fetch(args: argparse.Namespace) -> None:
    state = sync_cache(load_state(), force=args.refresh)
    pending = pending_records(state)
    batch = pending[: args.batch_size]
    print(json.dumps({"pending_total": len(pending), "batch": batch}, indent=2, ensure_ascii=False))


def cmd_dismiss(args: argparse.Namespace) -> None:
    """Mark records as processed locally. Does NOT delete from DynamoDB. Keeps cache intact."""
    state = load_state()
    keys = json.loads(args.keys) if args.keys else []
    if args.file:
        keys = json.loads(Path(args.file).read_text())

    dismissed = dismissed_keys(state)
    added = 0
    for key in keys:
        pair = (key["uuid"], key["timestamp"])
        if pair not in dismissed:
            state.setdefault("dismissed", []).append({"uuid": key["uuid"], "timestamp": key["timestamp"]})
            added += 1

    save_state(state)
    # Re-load pending against full cache (do not strip cache)
    state = load_state()
    if not state.get("cache"):
        state = sync_cache(state)
    print(f"Dismissed/processed locally: {added}. Pending: {len(pending_records(state))}")
    print("NOTE: Records remain in DynamoDB. Use archive + delete only with explicit cleanup.")


def cmd_archive(args: argparse.Namespace) -> None:
    """Full-table export. Required before any DynamoDB deletes.

    Never clobber a larger existing archive with a smaller/empty scan unless --force.
    """
    items = scan_all()
    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%M%SZ")
    dated = ARCHIVE_DIR / f"reported_messages_archive_{stamp}.json"

    if ARCHIVE_LATEST.exists() and not args.force:
        try:
            prev = json.loads(ARCHIVE_LATEST.read_text())
            prev_count = int(prev.get("count") or len(prev.get("records") or []))
        except (json.JSONDecodeError, TypeError, ValueError):
            prev_count = 0
        if prev_count > len(items):
            print(
                f"REFUSING TO OVERWRITE archive: existing has {prev_count} records, "
                f"live table has {len(items)}.\n"
                f"Keeping {ARCHIVE_LATEST}\n"
                "Pass --force only if you intentionally want to replace it.",
                file=sys.stderr,
            )
            sys.exit(2)

    payload = {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "source_table": TABLE,
        "region": REGION,
        "count": len(items),
        "records": items,
    }
    text = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    # Always write a unique dated snapshot first (never reuse same filename).
    dated.write_text(text)
    ARCHIVE_LATEST.write_text(text)

    state = load_state()
    state["cache"] = items
    state["cache_synced_at"] = payload["exported_at"]
    state["archived_at"] = payload["exported_at"]
    state["archive_path"] = str(ARCHIVE_LATEST)
    state["archive_count"] = len(items)
    save_state(state)

    print(f"Archived {len(items)} records")
    print(f"  → {dated}")
    print(f"  → {ARCHIVE_LATEST}")
    print(f"  size: {ARCHIVE_LATEST.stat().st_size} bytes")

def _require_archive_or_exit(force: bool) -> dict:
    if force:
        print("WARNING: --force bypasses archive check. Deletes are permanent.", file=sys.stderr)
        return {}
    if not ARCHIVE_LATEST.exists():
        print(
            "REFUSING TO DELETE: no archive at data/reported_messages_archive.json\n"
            "Run: report_batch.py archive\n"
            "Then re-run delete with --i-know-this-is-permanent",
            file=sys.stderr,
        )
        sys.exit(2)
    meta = json.loads(ARCHIVE_LATEST.read_text())
    live = scan_all()
    if meta.get("count") != len(live):
        print(
            f"REFUSING TO DELETE: archive count ({meta.get('count')}) != live table ({len(live)}).\n"
            "Re-run: report_batch.py archive",
            file=sys.stderr,
        )
        sys.exit(2)
    return meta


def cmd_delete(args: argparse.Namespace) -> None:
    """Permanent DynamoDB delete. Requires archive + explicit flag."""
    if not args.i_know_this_is_permanent:
        print(
            "REFUSING TO DELETE: pass --i-know-this-is-permanent after archiving.\n"
            "Deletes cannot be undone (PITR may be disabled).",
            file=sys.stderr,
        )
        sys.exit(2)

    _require_archive_or_exit(force=args.force)

    keys = json.loads(args.keys) if args.keys else []
    if args.file:
        keys = json.loads(Path(args.file).read_text())
    if args.all:
        keys = [{"uuid": r["uuid"], "timestamp": r["timestamp"]} for r in scan_all()]
    if not keys:
        print("No keys to delete.", file=sys.stderr)
        sys.exit(1)

    client = boto3.client("dynamodb", region_name=REGION)
    delete_keys = {(k["uuid"], k["timestamp"]) for k in keys}
    requests = [
        {"DeleteRequest": {"Key": {"uuid": {"S": uuid}, "timestamp": {"S": ts}}}}
        for uuid, ts in delete_keys
    ]

    deleted = 0
    for i in range(0, len(requests), 25):
        chunk = requests[i : i + 25]
        client.batch_write_item(RequestItems={TABLE: chunk})
        deleted += len(chunk)
        print(f"  deleted {deleted}/{len(requests)}")

    state = load_state()
    state["cache"] = [
        r for r in state.get("cache", []) if (r["uuid"], r["timestamp"]) not in delete_keys
    ]
    state["dismissed"] = [
        d for d in state.get("dismissed", []) if (d["uuid"], d["timestamp"]) not in delete_keys
    ]
    save_state(state)
    print(f"Deleted {deleted} record(s) from DynamoDB. Pending: {len(pending_records(state))}")


def cmd_reset(_: argparse.Namespace) -> None:
    if STATE_FILE.exists():
        STATE_FILE.unlink()
    print("Local review state cleared. (Archive files under data/ were not touched.)")


def main() -> None:
    parser = argparse.ArgumentParser(description="Paginated reported_messages review helper")
    sub = parser.add_subparsers(dest="command", required=True)

    p_count = sub.add_parser("count", help="Show total / pending counts")
    p_count.add_argument("--refresh", action="store_true", help="Re-scan DynamoDB")
    p_count.set_defaults(func=cmd_count)

    p_fetch = sub.add_parser("fetch", help="Fetch next batch as JSON")
    p_fetch.add_argument("--batch-size", type=int, default=100)
    p_fetch.add_argument("--refresh", action="store_true", help="Force re-sync from DynamoDB")
    p_fetch.set_defaults(func=cmd_fetch)

    p_dismiss = sub.add_parser(
        "dismiss",
        help="Mark records processed locally (does NOT delete from DynamoDB)",
    )
    p_dismiss.add_argument("--keys", help='JSON array, e.g. [{"uuid":"...","timestamp":"..."}]')
    p_dismiss.add_argument("--file", help="Path to JSON file with keys array")
    p_dismiss.set_defaults(func=cmd_dismiss)

    p_archive = sub.add_parser("archive", help="Export full table to data/reported_messages_archive.json")
    p_archive.add_argument(
        "--force",
        action="store_true",
        help="Allow overwriting a larger existing archive with a smaller live scan",
    )
    p_archive.set_defaults(func=cmd_archive)

    p_delete = sub.add_parser(
        "delete",
        help="PERMANENT delete from DynamoDB (requires archive + --i-know-this-is-permanent)",
    )
    p_delete.add_argument("--keys", help='JSON array, e.g. [{"uuid":"...","timestamp":"..."}]')
    p_delete.add_argument("--file", help="Path to JSON file with keys array")
    p_delete.add_argument("--all", action="store_true", help="Delete every row currently in the table")
    p_delete.add_argument(
        "--i-know-this-is-permanent",
        action="store_true",
        help="Required acknowledgment that deletes cannot be undone",
    )
    p_delete.add_argument(
        "--force",
        action="store_true",
        help="Bypass archive count check (dangerous; still requires --i-know-this-is-permanent)",
    )
    p_delete.set_defaults(func=cmd_delete)

    p_reset = sub.add_parser("reset", help="Clear local review state only")
    p_reset.set_defaults(func=cmd_reset)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
