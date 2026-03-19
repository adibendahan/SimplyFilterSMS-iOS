#!/bin/bash

set -eu

FUNCTION_NAME="ClassificationReport"
ROLE_ARN="arn:aws:iam::033810010201:role/service-role/ReportMessage-role-u9eqz3n5"
REGION="us-east-1"
DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$DIR"
zip lambda.zip lambda_function.py

if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" > /dev/null 2>&1; then
    echo "Updating existing function..."
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://lambda.zip \
        --region "$REGION"
else
    echo "Creating new function..."
    aws lambda create-function \
        --function-name "$FUNCTION_NAME" \
        --runtime python3.13 \
        --role "$ROLE_ARN" \
        --handler lambda_function.lambda_handler \
        --zip-file fileb://lambda.zip \
        --region "$REGION"

    echo "Adding API Gateway permission..."
    aws lambda add-permission \
        --function-name "$FUNCTION_NAME" \
        --statement-id apigateway-public-classification-report \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:us-east-1:033810010201:j476b01zf3/prod/POST/report" \
        --region "$REGION"
fi

rm lambda.zip
echo "Done."
