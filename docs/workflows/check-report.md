Investigate whether the iOS Reporting Extension's network POST to `https://api.ben-dahan.com/report` actually fired after a user reported a message from the TestFlight build.

## Context

The Reporting Extension uses `ILClassificationExtensionNetworkReportDestination`. After the user taps Done, iOS (outside the sandbox) POSTs `{sender, body, type}` to `https://api.ben-dahan.com/report`. This hits API Gateway `j476b01zf3` → `ReportMessage` Lambda → `reported_messages` DynamoDB table.

The test data records (sender: "test", body: "test body") are old manual tests — ignore them if present.

## Investigation steps

**1. Check DynamoDB for new records**

```bash
aws dynamodb scan --table-name reported_messages --region us-east-1
```

Show all records. Highlight any that are NOT the old test records (sender:"test", body:"test body").

**2. Check API Gateway execution logs for POST requests**

```bash
aws logs filter-log-events \
  --log-group-name "API-Gateway-Execution-Logs_j476b01zf3/prod" \
  --region us-east-1 \
  --start-time $(($(date -v-2d +%s) * 1000)) \
  --query 'events[*].{time:timestamp,msg:message}' \
  --output json
```

Look for any `POST` requests to `/report`. Note: AASA `GET /.well-known/apple-app-site-association` hits are expected and normal.

**3. Check Lambda logs**

```bash
aws logs filter-log-events \
  --log-group-name "/aws/lambda/ReportMessage" \
  --region us-east-1 \
  --start-time $(($(date -v-2d +%s) * 1000)) \
  --query 'events[*].{time:timestamp,msg:message}' \
  --output json
```

Look for `Lambda.run REQUEST` log lines — these show the payload received. Ignore invocations with `"body":"test body"`.

## Verdict

Based on the findings, report:

- **If a real POST hit the API and a record is in DynamoDB:** The pipeline works. Show the record and offer to run `/review-reports`.
- **If the Lambda was invoked but no record in DynamoDB:** Lambda ran but failed to write — check for errors in the Lambda logs.
- **If the API Gateway received a POST but Lambda wasn't invoked:** Integration issue between API GW and Lambda.
- **If no POST hit the API at all (only AASA GETs):** iOS never sent the network report. Likely causes:
  1. iOS batches/delays these posts — may arrive later.
  2. `userInfo` format issue in `classificationResponse(for:)`.
  3. AASA app ID mismatch with the TestFlight build.
  4. iOS only sends network reports on App Store / TestFlight builds — confirm the build was distributed via TestFlight (not local dev install via Xcode).
