// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Report Message Lambda",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
      .executable(name: "Report Message Lambda", targets: ["Report Message Lambda"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from:"0.3.0")),
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "Report Message Lambda",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSDynamoDB", package: "aws-sdk-swift"),
                .product(name: "Logging", package: "swift-log")
            ])
    ]
)
