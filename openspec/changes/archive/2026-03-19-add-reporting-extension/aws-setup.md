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
| `POST` | `/report` | Lambda: `ReportMessage` (same Velocity template as `/ReportMessage`) |
| `GET`  | `/.well-known/apple-app-site-association` | MOCK — returns AASA JSON |

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

- **Function:** `ReportMessage`
- **Runtime:** Swift (`provided.al2`)
- **Region:** `us-east-1`
- **DynamoDB table:** `reported_messages`
- **Permissions added:**
  - `apigateway-public-report` — allows `j476b01zf3/prod/POST/report` to invoke the function

### Velocity template (both APIs use the same mapping)
```velocity
#set($inputRoot = $input.path('$'))
{
    "sender": "$inputRoot.sender",
    "body": "$inputRoot.body",
    "type": "$inputRoot.type"
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
Sets `response.userInfo = ["sender": ..., "body": ..., "type": ...]` so iOS POSTs
that data to `https://api.ben-dahan.com/report` after the user taps Done.

---

## How it works (production)

1. User long-presses a message in iOS Messages → "Report Messages"
2. Extension UI appears (Junk / Junk & Block Sender / Not Junk)
3. User selects an option → taps Done
4. `classificationResponse(for:)` returns `ILClassificationResponse` with `action` + `userInfo`
5. iOS system (outside sandbox) POSTs `userInfo` JSON to `https://api.ben-dahan.com/report`
6. API Gateway passes `{sender, body, type}` to `ReportMessage` Lambda
7. Lambda writes record to `reported_messages` DynamoDB table
8. Records are reviewed via `/review-reports` skill and used to improve `automatic_filters.json`

---

## Pending verification

- **Network reporting requires TestFlight/App Store build.** Confirmed that domain verification works (AASA fetched successfully in dev builds), but the system POST to `/report` is only triggered in production distribution. Verify after next TestFlight release.
