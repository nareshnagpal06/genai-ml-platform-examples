#!/bin/bash
set -e

# Deploy Classification MLOps Template to S3
# Usage: ./deploy-template.sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMPLATE_DIR="${SCRIPT_DIR}/.."

# Check environment variables
if [ -z "$AWS_REGION" ] || [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$BUCKET_NAME" ]; then
    echo "Error: Required environment variables not set"
    echo "Please set: AWS_REGION, AWS_ACCOUNT_ID, BUCKET_NAME"
    echo ""
    echo "Example:"
    echo "  export AWS_REGION=us-east-1"
    echo "  export AWS_ACCOUNT_ID=123456789012"
    echo "  export BUCKET_NAME=sagemaker-projects-templates-123456789012-us-east-1"
    echo "  export SAGEMAKER_EXECUTION_ROLE_NAME=AmazonSageMaker-ExecutionRole-20260215T152111"
    exit 1
fi

if [ -z "$SAGEMAKER_EXECUTION_ROLE_NAME" ]; then
    echo "Warning: SAGEMAKER_EXECUTION_ROLE_NAME not set. Skipping IAM permission setup."
    echo "You'll need to manually add s3:GetObjectTagging permission to your SageMaker execution role."
    SKIP_IAM_SETUP=true
fi

echo "========================================="
echo "Deploying Classification MLOps Template"
echo "========================================="
echo "Region: $AWS_REGION"
echo "Account: $AWS_ACCOUNT_ID"
echo "Bucket: $BUCKET_NAME"
echo ""

# Step 1: Package Lambda function
echo "Step 1: Packaging Lambda function..."
cd "${SCRIPT_DIR}"
./package-lambda.sh

# Step 2: Create S3 bucket if it doesn't exist
echo ""
echo "Step 2: Checking S3 bucket..."
if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Creating S3 bucket: ${BUCKET_NAME}"
    aws s3 mb "s3://${BUCKET_NAME}" --region "${AWS_REGION}"
else
    echo "Bucket already exists: ${BUCKET_NAME}"
fi

# Step 3: Configure CORS
echo ""
echo "Step 3: Configuring CORS policy..."
CORS_FILE="${TEMPLATE_DIR}/../cors-policy.json"
if [ ! -f "$CORS_FILE" ]; then
    echo "Creating CORS policy file..."
    cat > "$CORS_FILE" << 'EOF'
{
    "CORSRules": [
        {
            "AllowedHeaders": ["*"],
            "AllowedMethods": ["POST", "PUT", "GET", "HEAD", "DELETE"],
            "AllowedOrigins": ["https://*.sagemaker.aws"],
            "ExposeHeaders": [
                "ETag",
                "x-amz-delete-marker",
                "x-amz-id-2",
                "x-amz-request-id",
                "x-amz-server-side-encryption",
                "x-amz-version-id"
            ]
        }
    ]
}
EOF
fi

aws s3api put-bucket-cors \
    --bucket "${BUCKET_NAME}" \
    --cors-configuration "file://${CORS_FILE}"

# Step 4: Upload Lambda package
echo ""
echo "Step 4: Uploading Lambda package..."
aws s3 cp "${SCRIPT_DIR}/../build/lambda-github-workflow-trigger.zip" \
    "s3://${BUCKET_NAME}/lambda/lambda-github-workflow-trigger.zip"

# Step 5: Upload template
echo ""
echo "Step 5: Uploading CloudFormation template..."
aws s3 cp "${TEMPLATE_DIR}/template.yaml" \
    "s3://${BUCKET_NAME}/templates/classification-mlops.yaml"

# Step 6: Tag template for visibility
echo ""
echo "Step 6: Tagging template for SageMaker Studio visibility..."
aws s3api put-object-tagging \
    --bucket "${BUCKET_NAME}" \
    --key "templates/classification-mlops.yaml" \
    --tagging 'TagSet=[{Key=sagemaker:studio-visibility,Value=true}]'

# Step 7: Verify upload
echo ""
echo "Step 7: Verifying deployment..."
echo "Template URL: s3://${BUCKET_NAME}/templates/classification-mlops.yaml"
echo "Lambda URL: s3://${BUCKET_NAME}/lambda/lambda-github-workflow-trigger.zip"

# Check tags
TAGS=$(aws s3api get-object-tagging \
    --bucket "${BUCKET_NAME}" \
    --key "templates/classification-mlops.yaml" \
    --query 'TagSet[?Key==`sagemaker:studio-visibility`].Value' \
    --output text)

if [ "$TAGS" == "true" ]; then
    echo "✓ Template is tagged for Studio visibility"
else
    echo "✗ Warning: Template visibility tag not found"
fi

# Step 8: Configure SageMaker execution role permissions
echo ""
echo "Step 8: Creating GitHub Actions policy..."

# Create GitHub Actions policy if it doesn't exist
POLICY_EXISTS=$(aws iam get-policy --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/SageMakerGitHubActionsPolicy 2>/dev/null || echo "")

if [ -z "$POLICY_EXISTS" ]; then
    echo "Creating SageMakerGitHubActionsPolicy..."
    aws iam create-policy \
        --policy-name SageMakerGitHubActionsPolicy \
        --policy-document "file://${TEMPLATE_DIR}/iam/GithubActionsMLOpsExecutionPolicy.json"
    echo "✓ Policy created"
else
    echo "✓ Policy already exists"
fi

if [ "$SKIP_IAM_SETUP" != "true" ]; then
    echo ""
    echo "Configuring SageMaker execution role permissions..."
    
    echo "Adding S3 tagging permission..."
    aws iam put-role-policy \
        --role-name "${SAGEMAKER_EXECUTION_ROLE_NAME}" \
        --policy-name S3TemplateTaggingPolicy \
        --policy-document "file://${TEMPLATE_DIR}/iam/s3-tagging-policy.json"
    
    echo "Adding S3 bucket permissions..."
    aws iam put-role-policy \
        --role-name "${SAGEMAKER_EXECUTION_ROLE_NAME}" \
        --policy-name S3BucketPermissions \
        --policy-document "file://${TEMPLATE_DIR}/iam/s3-bucket-permissions.json"
    
    echo "Adding CloudFormation stack creation permission..."
    aws iam put-role-policy \
        --role-name "${SAGEMAKER_EXECUTION_ROLE_NAME}" \
        --policy-name SageMakerProjectsCreateCFNTemplates \
        --policy-document "file://${TEMPLATE_DIR}/iam/cfn-stack-sm-projects.json"
    
    echo "Adding IAM role creation permission..."
    aws iam put-role-policy \
        --role-name "${SAGEMAKER_EXECUTION_ROLE_NAME}" \
        --policy-name SageMakerProjectsIAMPermissions \
        --policy-document "file://${TEMPLATE_DIR}/iam/iam-create-role-policy.json"
    
    echo "Adding Lambda permissions..."
    aws iam put-role-policy \
        --role-name "${SAGEMAKER_EXECUTION_ROLE_NAME}" \
        --policy-name LambdaPermissions \
        --policy-document "file://${TEMPLATE_DIR}/iam/lambda-permissions.json"
    
    echo "Adding S3 Lambda read permission..."
    aws iam put-role-policy \
        --role-name "${SAGEMAKER_EXECUTION_ROLE_NAME}" \
        --policy-name S3LambdaReadPermission \
        --policy-document "file://${TEMPLATE_DIR}/iam/s3-lambda-read-policy.json"
    
    echo "Adding EventBridge permissions..."
    aws iam put-role-policy \
        --role-name "${SAGEMAKER_EXECUTION_ROLE_NAME}" \
        --policy-name EventBridgePermissions \
        --policy-document "file://${TEMPLATE_DIR}/iam/eventbridge-permissions.json"
    
    echo "Adding SageMaker Code Repository permissions..."
    aws iam put-role-policy \
        --role-name "${SAGEMAKER_EXECUTION_ROLE_NAME}" \
        --policy-name SageMakerCodeRepoPermissions \
        --policy-document "file://${TEMPLATE_DIR}/iam/sagemaker-code-repo-permissions.json"
    
    echo "✓ All permissions added successfully"
else
    echo ""
    echo "Step 8: Skipped (SAGEMAKER_EXECUTION_ROLE_NAME not provided)"
fi

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Configure SageMaker domain (if not already done):"
echo "   export DOMAIN_ID=<your-domain-id>"
echo "   aws sagemaker add-tags \\"
echo "     --resource-arn arn:aws:sagemaker:${AWS_REGION}:${AWS_ACCOUNT_ID}:domain/\$DOMAIN_ID \\"
echo "     --tags Key=sagemaker:projectS3TemplatesLocation,Value=s3://${BUCKET_NAME}/templates/"
echo ""
echo "2. Copy seed code to your GitHub repository from:"
echo "   /home/ubuntu/projects/genai-ml-platform-examples/platform/genai-ml-stdzn-on-smai/seed-code/MLAutomation/"
echo ""
echo "3. Create a project in SageMaker Studio using the template"
