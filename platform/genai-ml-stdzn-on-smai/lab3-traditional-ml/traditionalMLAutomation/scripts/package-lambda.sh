#!/bin/bash
set -e

# Package Lambda function
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LAMBDA_DIR="${SCRIPT_DIR}/../lambda_functions"
BUILD_DIR="${SCRIPT_DIR}/../build"

echo "Creating build directory..."
mkdir -p "${BUILD_DIR}"

echo "Installing Lambda dependencies..."
pip install -r "${LAMBDA_DIR}/requirements.txt" -t "${BUILD_DIR}"

echo "Copying Lambda function..."
cp "${LAMBDA_DIR}/lambda_function.py" "${BUILD_DIR}/"

echo "Creating Lambda deployment package..."
cd "${BUILD_DIR}"
zip -r lambda-github-workflow-trigger.zip .

echo "Lambda package created: ${BUILD_DIR}/lambda-github-workflow-trigger.zip"
echo "Upload this to your S3 bucket for the template to use"
