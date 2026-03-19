# AWS Setup — Reporting Extension

## Domain

**ben-dahan.com** — registered on Namecheap
**api.ben-dahan.com** — subdomain used for the public classification report API

### Namecheap DNS records
| Type  | Host | Value |
|-------|------|-------|
| CNAME | `api` | `d-agrg5rqg3j.execute-api.us-east-1.amazonaws.com` |
| CNAME | `_83a4e66a18bcb9d4abe4a2811014c528.api` | `_7a529f1aacce2112729cf1628790eef1.jkddzztszm.acm-validations.aws` |

---

## ACM Certificate

- **ARN:** `arn:aws:acm:us-east-1:033810010201:certificate/91838967-25fc-447c-bfe2-dc36d696790d`
- **Domain:** `api.ben-dahan.com`
- **Region:** `us-east-1`
- **Validation:** DNS (CNAME record above)
- **Status:** ISSUED

---

## API Gateway

### Existing API — authenticated (original)
- **ID:** `qezcp0b7pc`
- **Stage:** `prod`
- **Endpoint:** `https://qezcp0b7pc.execute-api.us-east-1.amazonaws.com/prod`
- **Auth:** API key required (`x-api-key` header)
- **Routes:** `POST /ReportMessage`
- **Usage:** Main app `ReportMessageService` (sends reports from in-app reporting UI)

### New API — public (for extension)
- **ID:** `j476b01zf3`
- **Name:** `ClassificationReport`
- **Stage:** `prod`
- **Endpoint:** `https://j476b01zf3.execute-api.us-east-1.amazonaws.com/prod`
- **Custom domain:** `https://api.ben-dahan.com`
- **Auth:** None (no API key required)
- **CloudWatch logging:** INFO level enabled

#### Routes

| Method | Path | Integration |
|--------|------|-------------|
| `POST` | `/report` | Lambda: `ClassificationReport` (Python 3.13) — handles `bodies: [String]` array |
| `GET`  | `/.well-known/apple-app-site-association` | MOCK — returns AASA JSON |

> **Note:** The main app `ReportMessageService` also now uses `api.ben-dahan.com/report` (no auth). The authenticated `qezcp0b7pc` API Gateway is no longer used by the app.

#### AASA response
```json
{
  "classificationreport": {
    "apps": [
      "AL28LDR9PU.com.grizz.apps.dev.Simply-Filter-SMS",
      "AL28LDR9PU.com.grizz.apps.dev.Simply-Filter-SMS.Simply-Filter-SMS-Report-Extension"
    ]
  }
}
```

### Custom Domain mapping
- **Domain:** `api.ben-dahan.com`
- **Regional endpoint:** `d-agrg5rqg3j.execute-api.us-east-1.amazonaws.com`
- **Base path mapping:** `(none)` → `j476b01zf3/prod`

---

## Lambda

- **Function:** `ClassificationReport`
- **Runtime:** Python 3.13
- **Region:** `us-east-1`
- **DynamoDB table:** `reported_messages`
- **Source:** `Classification Report Lambda/lambda_function.py` in repo root
- **Deploy:** `Classification Report Lambda/deploy.sh` — zips and creates/updates via AWS CLI (no Docker needed)
- **Permissions:** `apigateway-public-classification-report` — allows `j476b01zf3/prod/POST/report` to invoke the function
- **Handles:** Both `bodies: [String]` (multi-message, from extension) and `body: String` (single message, from in-app)

> **Replaced:** The original `ReportMessage` Swift Lambda (`provided.al2`) was removed from the repo and is no longer used by `j476b01zf3`. It remains deployed in AWS as it is used by `qezcp0b7pc` — DO NOT DELETE.

### Velocity template (`j476b01zf3 POST /report`)
```velocity
#set($r = $input.path("$"))
{
    "sender": "$r.classification.sender",
    "bodies": $input.json("$.classification.bodies"),
    "type": "$r.classification.type"
}
```

---

## Extension configuration

### Info.plist
```xml
<key>ILClassificationExtensionNetworkReportDestination</key>
<string>https://api.ben-dahan.com/report</string>
```

### Reporting Extension.entitlements
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>classificationreport:api.ben-dahan.com</string>
</array>
```

### classificationResponse(for:)
Sets `response.userInfo = ["sender": ..., "bodies": [...], "type": ...]` so iOS POSTs
that data to `https://api.ben-dahan.com/report` after the user taps Done.
iOS wraps userInfo under `classification` key: `{"classification": {"sender":..., "bodies":[...], "type":...}, "app":{...}, "_version":1}`.

---

## How it works (production)

1. User long-presses one or more messages in iOS Messages → "Report Messages"
2. Extension UI appears — shows sender + all selected message bodies; offers Junk / Junk & Block Sender / Not Junk
3. User selects an option → taps Done
4. `classificationResponse(for:)` returns `ILClassificationResponse` with `action` + `userInfo = {sender, bodies, type}`
5. iOS system (outside sandbox) POSTs `{"classification": {sender, bodies, type}, ...}` to `https://api.ben-dahan.com/report`
6. API Gateway Velocity template extracts `sender`, `bodies`, `type` → passes to `ClassificationReport` Lambda
7. Lambda writes one DynamoDB record per body to `reported_messages` table
8. Records are reviewed via `/review-reports` skill and used to improve `automatic_filters.json`

**Verified end-to-end:** Network reporting pipeline confirmed working on TestFlight build (2026-03-19).
