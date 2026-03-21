# Multi-Message Reporting Extension — Implementation Plan

## Goal
Support selecting multiple messages in iOS Messages and reporting them all at once via the Reporting Extension. All messages are from the same sender, so the UI shows the sender once and lists all message bodies. Each body is stored as a separate DynamoDB record.

## Current State (as of 2026-03-19)

### What's working
- Reporting Extension is live on TestFlight
- `ILClassificationExtensionNetworkReportDestination` pipeline is fully working end-to-end
- iOS POSTs to `https://api.ben-dahan.com/report` in this format:
  ```json
  {
    "classification": {
      "sender": "+972542228188",
      "body": "Test",
      "type": "allow"
    },
    "app": { "version": "..." },
    "_version": 1
  }
  ```
- API Gateway `j476b01zf3 POST /report` Velocity template correctly maps:
  ```velocity
  #set($r = $input.path("$"))
  {
      "sender": "$r.classification.sender",
      "body": "$r.classification.body",
      "type": "$r.classification.type"
  }
  ```
- Lambda `ReportMessage` writes one record per report to `reported_messages` DynamoDB table

### What's missing
- `prepare(for:)` only reads `messageCommunications.first` — ignores additional selected messages
- UI only shows one message body
- Lambda only accepts a single `body` string, not an array

---

## Architecture Decision

**New Lambda for `/report`, leave existing Lambda untouched.**

| API Gateway | Route | Lambda | Used by |
|---|---|---|---|
| `qezcp0b7pc` (authenticated) | `POST /ReportMessage` | `ReportMessage` | Main app `ReportMessageService` — DO NOT TOUCH |
| `j476b01zf3` (public) | `POST /report` | `ClassificationReport` ← NEW | Reporting Extension network report |

---

## Part 1 — New Lambda: `ClassificationReport`

### Location
Create a new folder: `Classification Report Lambda/` alongside `Report Message Lambda/` in the repo root.

### Package.swift
Identical to `Report Message Lambda/Package.swift` — just rename the product and target:
```swift
// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "Classification Report Lambda",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .executable(name: "Classification Report Lambda", targets: ["Classification Report Lambda"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from:"0.3.0")),
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "Classification Report Lambda",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSDynamoDB", package: "aws-sdk-swift"),
                .product(name: "Logging", package: "swift-log")
            ])
    ]
)
```

### Sources/Classification Report Lambda/main.swift
```swift
import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import AWSDynamoDB
import ClientRuntime
import AWSClientRuntime
import Logging


//MARK: - Lambda -
Lambda.run { (context,
              input: ClassificationReportRequest,
              callback: @escaping (Result<APIGateway.V2.Response, Error>) -> ()) in

    let logger = Logger(label: "com.grizz.apps.dev.Simply-Filter-SMS.ClassificationReportLambda")
    logger.info("Lambda.run REQUEST: \(input.rawValue ?? "nil")")

    Task(operation: {
        do {
            let dynamoDbClient = try DynamoDbClient(region: "us-east-1")
            for body in input.bodies {
                let item = ClassificationReportItem(sender: input.sender, body: body, type: input.type)
                let _ = try await dynamoDbClient.putItem(input: PutItemInput(
                    item: item.values,
                    returnValues: DynamoDbClientTypes.ReturnValue.none,
                    tableName: "reported_messages"
                ))
            }
            callback(.success(APIGateway.V2.Response(statusCode: .ok)))
        }
        catch {
            logger.error("Lambda.run error: \(error.localizedDescription) request: \(input.rawValue ?? "nil")")
            callback(.success(APIGateway.V2.Response(statusCode: .badRequest)))
        }
    })
}


//MARK: - Structs -
struct ClassificationReportRequest: Codable {
    let sender: String
    let bodies: [String]
    let type: String

    var rawValue: String? {
        try? String(decoding: JSONEncoder().encode(self), as: Unicode.UTF8.self)
    }
}

struct ClassificationReportItem {
    let uuid: DynamoDbClientTypes.AttributeValue
    let timestamp: DynamoDbClientTypes.AttributeValue
    let sender: DynamoDbClientTypes.AttributeValue
    let body: DynamoDbClientTypes.AttributeValue
    let type: DynamoDbClientTypes.AttributeValue

    init(sender: String, body: String, type: String) {
        self.uuid = DynamoDbClientTypes.AttributeValue.s(UUID().uuidString)
        self.timestamp = DynamoDbClientTypes.AttributeValue.s("\(Int64(Date().timeIntervalSince1970 * 1000))")
        self.sender = DynamoDbClientTypes.AttributeValue.s(sender)
        self.body = DynamoDbClientTypes.AttributeValue.s(body)
        self.type = DynamoDbClientTypes.AttributeValue.s(type)
    }

    var values: [String: DynamoDbClientTypes.AttributeValue] {
        return [
            "uuid": self.uuid,
            "timestamp": self.timestamp,
            "sender": self.sender,
            "body": self.body,
            "type": self.type
        ]
    }
}
```

### Build & Deploy
Follow the same process used to deploy `ReportMessage` Lambda:
```bash
# From Classification Report Lambda/ directory
swift build -c release --triple aarch64-unknown-linux-gnu
# Zip the binary
zip lambda.zip .build/release/Classification\ Report\ Lambda
# Create Lambda in AWS Console or CLI:
aws lambda create-function \
  --function-name ClassificationReport \
  --runtime provided.al2 \
  --role <same IAM role as ReportMessage Lambda> \
  --handler bootstrap \
  --architectures arm64 \
  --zip-file fileb://lambda.zip \
  --region us-east-1
# Add permission for API Gateway j476b01zf3 to invoke it
aws lambda add-permission \
  --function-name ClassificationReport \
  --statement-id apigateway-public-classification-report \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:033810010201:j476b01zf3/prod/POST/report" \
  --region us-east-1
```

---

## Part 2 — Update API Gateway Velocity Template

Update `j476b01zf3 POST /report` integration to point to `ClassificationReport` Lambda and use new template:

```velocity
#set($r = $input.path("$"))
#set($bodies = $r.classification.bodies)
{
    "sender": "$r.classification.sender",
    "bodies": $input.json("$.classification.bodies"),
    "type": "$r.classification.type"
}
```

**Note:** `$input.json("$.classification.bodies")` outputs the array as raw JSON (e.g. `["body1","body2"]`), which is what we need for the `[String]` array in the Lambda.

Also update the Lambda integration target from `ReportMessage` to `ClassificationReport`.

### AWS CLI commands
```bash
# 1. Update integration to point to new Lambda
# (Do this in AWS Console: API Gateway → j476b01zf3 → /report → POST → Integration Request → change Lambda function to ClassificationReport)

# 2. Update Velocity template
aws apigateway update-integration \
  --rest-api-id j476b01zf3 \
  --resource-id uhl5lx \
  --http-method POST \
  --region us-east-1 \
  --cli-input-json '{
    "httpMethod":"POST",
    "resourceId":"uhl5lx",
    "restApiId":"j476b01zf3",
    "patchOperations":[{
      "op":"replace",
      "path":"/requestTemplates/application~1json",
      "value":"#set($r = $input.path(\"$\"))\n{\n    \"sender\": \"$r.classification.sender\",\n    \"bodies\": $input.json(\"$.classification.bodies\"),\n    \"type\": \"$r.classification.type\"\n}"
    }]
  }'

# 3. Deploy
aws apigateway create-deployment \
  --rest-api-id j476b01zf3 \
  --stage-name prod \
  --region us-east-1
```

---

## Part 3 — iOS: ReportingExtensionViewController.swift

Replace `pendingBody: String` with `pendingBodies: [String]`. Read ALL communications in `prepare(for:)`. Pass array to ViewModel and userInfo.

```swift
class ReportingExtensionViewController: ILClassificationUIExtensionViewController {

    private let confirmationViewModel = ReportingConfirmationView.ViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var pendingSender: String = ""
    private var pendingBodies: [String] = []

    // viewDidLoad() — unchanged

    override func prepare(for classificationRequest: ILClassificationRequest) {
        if let messageRequest = classificationRequest as? ILMessageClassificationRequest,
           let first = messageRequest.messageCommunications.first {
            pendingSender = first.sender ?? ""
            pendingBodies = messageRequest.messageCommunications.compactMap { $0.messageBody }.filter { !$0.isEmpty }
            confirmationViewModel.sender = pendingSender
            confirmationViewModel.bodies = pendingBodies
        }
    }

    override func classificationResponse(for request: ILClassificationRequest) -> ILClassificationResponse {
        guard let reportType = confirmationViewModel.selectedReportType else {
            return ILClassificationResponse(action: .none)
        }

        let action: ILClassificationAction
        switch reportType {
        case .junk:            action = .reportJunk
        case .notJunk:         action = .reportNotJunk
        case .junkAndBlockSender: action = .reportJunkAndBlockSender
        }

        let response = ILClassificationResponse(action: action)
        response.userInfo = [
            "sender": pendingSender,
            "bodies": pendingBodies,
            "type": reportType.type
        ]
        return response
    }
}
```

---

## Part 4 — iOS: ReportingConfirmationView.swift

Change ViewModel `body: String` → `bodies: [String]`. Update the message preview section to show all bodies separated by dividers.

**ViewModel:**
```swift
class ViewModel: ObservableObject {
    @Published var selectedReportType: ReportType?
    @Published var sender: String = ""
    @Published var bodies: [String] = []
}
```

**Message preview section** (replace the existing Section with sender/body):
```swift
Section {
    VStack(alignment: .leading, spacing: 0) {
        if !model.sender.isEmpty {
            Label(model.sender, systemImage: "person.fill")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .padding(.bottom, model.bodies.isEmpty ? 0 : 10)
        }
        ForEach(Array(model.bodies.enumerated()), id: \.offset) { index, body in
            if !model.sender.isEmpty || index > 0 {
                Divider()
                    .padding(.bottom, 10)
            }
            Text("Message \(model.bodies.count > 1 ? "\(index + 1)" : "")")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 2)
            Text(body)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(4)
                .padding(.bottom, index < model.bodies.count - 1 ? 10 : 0)
        }
    }
    .padding(.vertical, 4)
} header: {
    Text("reportingExtension_classifyTitle"~)
        .font(.headline)
        .foregroundColor(.primary)
        .textCase(nil)
        .padding(.bottom, 4)
}
```

**Note:** When there is only one message, label it "Message" (no number). When there are multiple, label them "Message 1", "Message 2", etc.

---

## Order of Operations

1. Write Lambda code → build → deploy `ClassificationReport` to AWS
2. Update API Gateway integration target + Velocity template → deploy stage
3. Test with a single message report — verify new Lambda receives `{"sender":"...","bodies":["..."],"type":"..."}` and writes correctly
4. Update iOS code (`ReportingExtensionViewController` + `ReportingConfirmationView`)
5. Build TestFlight → test multi-message selection

---

## Key Facts to Remember

- iOS wraps our `userInfo` under `classification` key: `{"classification": {...}, "app": {...}, "_version": 1}`
- API Gateway resource ID for `/report` on `j476b01zf3`: **`uhl5lx`**
- AWS account: `033810010201`, region: `us-east-1`
- DynamoDB table: `reported_messages` (partition key: `uuid`, sort key: `timestamp`, both String)
- Existing `ReportMessage` Lambda + `qezcp0b7pc` API Gateway: **DO NOT TOUCH**
- Lambda IAM role: same as existing `ReportMessage` (has DynamoDB PutItem permission on `reported_messages`)
