#!/bin/bash

sh "./Report Message Lambda/Resources/scripts/build-lambda.sh"
sh "./Report Message Lambda/Resources/scripts/package-lambda.sh"
sh "./Report Message Lambda/Resources/scripts/deploy-lambda.sh"
