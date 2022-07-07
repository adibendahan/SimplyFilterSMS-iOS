#!/bin/bash

aws lambda update-function-code --function-name ReportMessage --zip-file "fileb://$PWD/Report Message Lambda/.build/lambda/Report Message Lambda/lambda.zip"
