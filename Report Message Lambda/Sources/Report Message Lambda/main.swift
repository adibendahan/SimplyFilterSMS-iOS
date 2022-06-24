import Foundation
import AWSLambdaRuntime
import AWSLambdaEvents
import AWSDynamoDB
import ClientRuntime
import AWSClientRuntime
import Logging


//MARK: - Lambda -
Lambda.run { (context,
              input: ReportMessageRequest,
              callback: @escaping (Result<APIGateway.V2.Response, Error>) -> ()) in

    let logger = Logger(label: "com.grizz.apps.dev.Simply-Filter-SMS.ReportMessageLambda")
    logger.info("Lambda.run REQUEST: \(input.rawValue ?? "nil")")

    Task(operation: {
        do {
            let dynamoDbClient = try DynamoDbClient(region: "us-east-1")
            let newItem = ReportMessageItem(request: input)
            let _ = try await dynamoDbClient.putItem(input: PutItemInput(item: newItem.values,
                                                                         returnValues: DynamoDbClientTypes.ReturnValue.none,
                                                                         tableName: "reported_messages"))
            callback(.success(APIGateway.V2.Response(statusCode: .ok)))
        }
        catch {
            logger.error("Lambda.run error: \(error.localizedDescription) request: \(input.rawValue ?? "nil")")
            callback(.success(APIGateway.V2.Response(statusCode: .badRequest)))
        }
    })
}



//MARK: - Structs -
struct ReportMessageRequest: Codable {
    let sender: String
    let body: String
    let type: String
    
    var rawValue: String? {
        try? String(decoding: JSONEncoder().encode(self), as: Unicode.UTF8.self)
    }
}

struct ReportMessageItem {
    let uuid: DynamoDbClientTypes.AttributeValue
    let timestamp: DynamoDbClientTypes.AttributeValue
    let sender: DynamoDbClientTypes.AttributeValue
    let body: DynamoDbClientTypes.AttributeValue
    let type: DynamoDbClientTypes.AttributeValue
    
    
    init(request: ReportMessageRequest) {
        self.uuid = DynamoDbClientTypes.AttributeValue.s(UUID().uuidString)
        self.timestamp = DynamoDbClientTypes.AttributeValue.s("\(Int64(Date().timeIntervalSince1970 * 1000))")
        self.sender = DynamoDbClientTypes.AttributeValue.s(request.sender)
        self.body = DynamoDbClientTypes.AttributeValue.s(request.body)
        self.type = DynamoDbClientTypes.AttributeValue.s(request.type)
    }
    
    var values: [String : DynamoDbClientTypes.AttributeValue] {
        return [ "uuid" : self.uuid,
                 "timestamp" : self.timestamp,
                 "sender" : self.sender,
                 "body" : self.body,
                 "type" : self.type ]
    }
}
