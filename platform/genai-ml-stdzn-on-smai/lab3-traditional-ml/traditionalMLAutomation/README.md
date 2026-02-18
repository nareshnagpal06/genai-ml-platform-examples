# Bank Marketing Classification - S3-Based SageMaker Project Template

MLOps template for Bank Marketing Classification using Amazon SageMaker Pipelines, GitHub Actions, and AWS Glue Catalog integration.

## Overview

This S3-based SageMaker project template automates the complete ML lifecycle for bank marketing classification:
- **Data ingestion** from AWS Glue Catalog
- **Feature engineering** with AWS Data Wrangler
- **Model training** using XGBoost
- **Model evaluation** with comprehensive metrics
- **Model registration** in SageMaker Model Registry
- **Automated deployment** to staging and production via GitHub Actions
- **Optional MLflow tracking** for experiment management

## Architecture

```
┌─────────────────┐
│ SageMaker Studio│
│  Create Project │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│   CloudFormation Stack                  │
│  ┌─────────────────────────────────┐   │
│  │ S3 Bucket (Artifacts)           │   │
│  │ Lambda (GitHub Trigger)         │   │
│  │ EventBridge (Model Approval)    │   │
│  │ SageMaker Code Repository       │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│   GitHub Repository (Seed Code)         │
│  ┌─────────────────────────────────┐   │
│  │ model_build/                    │   │
│  │  ├── ml_pipelines/              │   │
│  │  ├── source_scripts/            │   │
│  │  └── .github/workflows/         │   │
│  │       └── build.yml             │   │
│  │                                 │   │
│  │ model_deploy/                   │   │
│  │  ├── deploy_endpoint/           │   │
│  │  └── .github/workflows/         │   │
│  │       └── deploy.yml            │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│   Push to main → Build Workflow        │
│   ├── Preprocessing (Glue → S3)        │
│   ├── Training (XGBoost)               │
│   ├── Evaluation (Metrics)             │
│   └── Register Model (if accuracy≥0.7) │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│   Manual Model Approval                 │
│   (SageMaker Model Registry)            │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│   EventBridge → Lambda → GitHub         │
│   Triggers Deploy Workflow              │
│   ├── Deploy to Staging                 │
│   ├── Test Staging                      │
│   └── Deploy to Production              │
└─────────────────────────────────────────┘
```

## Prerequisites

### 1. Environment Variables

```bash
export AWS_REGION=$(aws configure get region)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export BUCKET_NAME="sagemaker-projects-templates-${AWS_ACCOUNT_ID}-${AWS_REGION}"
export DOMAIN_ID="<your-sagemaker-domain-id>"
```

### 2. GitHub Repository

Create a GitHub repository with name starting with `sagemaker-` (e.g., `sagemaker-bank-classification`).

### 3. AWS CodeConnection

Create a CodeConnection to GitHub:
```bash
# Follow: https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-create-github.html
# Tag the connection:
aws codestar-connections tag-resource \
  --resource-arn <connection-arn> \
  --tags key=sagemaker,value=true
```

### 4. GitHub Personal Access Token

Create a fine-grained token with permissions:
- **Actions**: Read and write
- **Contents**: Read and write
- **Workflows**: Read and write

Store in Secrets Manager:
```bash
aws secretsmanager create-secret \
  --name sagemaker-github-token \
  --description "GitHub token for SageMaker Classification MLOps" \
  --secret-string '{"token":"<your-github-token>"}'
```

### 5. IAM Roles (One-time Setup)

```bash
export SAGEMAKER_EXECUTION_ROLE_ARN=$(aws sagemaker describe-domain \
  --domain-id $DOMAIN_ID \
  --query 'DefaultUserSettings.ExecutionRole' \
  --output text)

aws cloudformation deploy \
  --template-file iam/sagemaker-projects-roles-and-policies.yaml \
  --stack-name sagemaker-projects-roles-policies \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides SageMakerExecutionRoleArn=$SAGEMAKER_EXECUTION_ROLE_ARN \
  --region $AWS_REGION
```

Add PassRole permission:
```bash
cat > /tmp/pass-role-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "iam:PassRole",
    "Resource": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonSageMakerProjectsLaunchRole"
  }]
}
EOF

aws iam put-role-policy \
  --role-name $(echo $SAGEMAKER_EXECUTION_ROLE_ARN | cut -d'/' -f2) \
  --policy-name SageMakerProjectsPassRolePolicy \
  --policy-document file:///tmp/pass-role-policy.json

aws iam put-role-policy \
  --role-name $(echo $SAGEMAKER_EXECUTION_ROLE_ARN | cut -d'/' -f2) \
  --policy-name SageMakerProjectsCreateCFNTemplates \
  --policy-document file://iam/cfn-stack-sm-projects.json
```

### 6. IAM User for GitHub Actions

```bash
aws iam create-user --user-name sagemaker-github-actions-user

aws iam create-policy \
  --policy-name SageMakerGitHubActionsPolicy \
  --policy-document file://iam/GithubActionsMLOpsExecutionPolicy.json

aws iam attach-user-policy \
  --user-name sagemaker-github-actions-user \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/SageMakerGitHubActionsPolicy

aws iam create-access-key --user-name sagemaker-github-actions-user
```

Save the access key and secret for GitHub secrets.

## Deployment Steps

### 1. Package Lambda Function

```bash
cd scripts
./package-lambda.sh
```

This creates `build/lambda-github-workflow-trigger.zip`.

### 2. Upload Template and Lambda to S3

```bash
# Create S3 bucket if needed
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION

# Configure CORS
aws s3api put-bucket-cors \
  --bucket $BUCKET_NAME \
  --cors-configuration file://../cors-policy.json

# Upload Lambda package
aws s3 cp build/lambda-github-workflow-trigger.zip \
  s3://$BUCKET_NAME/lambda/

# Upload template
aws s3 cp ../template.yaml \
  s3://$BUCKET_NAME/templates/classification-mlops-github.yaml

# Tag template for visibility
aws s3api put-object-tagging \
  --bucket $BUCKET_NAME \
  --key templates/classification-mlops-github.yaml \
  --tagging 'TagSet=[{Key=sagemaker:studio-visibility,Value=true}]'
```

### 3. Configure SageMaker Domain

```bash
aws sagemaker add-tags \
  --resource-arn arn:aws:sagemaker:$AWS_REGION:$AWS_ACCOUNT_ID:domain/$DOMAIN_ID \
  --tags Key=sagemaker:projectS3TemplatesLocation,Value=s3://$BUCKET_NAME/templates/
```

### 4. Copy Seed Code to GitHub Repository

Copy the contents of `/home/ubuntu/projects/genai-ml-platform-examples/platform/genai-ml-stdzn-on-smai/seed-code/MLAutomation/` to your GitHub repository.

## Creating a Project

### In SageMaker Studio:

1. Navigate to **Projects** → **Create project**
2. Select **Organization templates** tab
3. Choose **Bank Marketing Classification MLOps**
4. Fill in parameters:
   - **Project Name**: e.g., `bank-marketing-prod`
   - **GitHub Owner**: Your GitHub username/org
   - **Repository Name**: Your repo name (must start with `sagemaker-`)
   - **CodeStar Connection ID**: From step 3 of prerequisites
   - **GitHub Token Secret**: `sagemaker-github-token`
   - **Glue Database**: Your Glue database name
   - **Glue Table**: Your Glue table name
   - **Lambda S3 Bucket**: `$BUCKET_NAME`
5. Click **Create project**

### Configure GitHub Secrets:

In your GitHub repository, add these secrets:
```
OIDC_ROLE_GITHUB_WORKFLOW=arn:aws:iam::<account>:role/<role-name>
GLUE_DATABASE=<your-database>
GLUE_TABLE=<your-table>
```

## Usage

### Trigger Model Training:

Push changes to `main` branch affecting `ml_pipelines/` or `source_scripts/`:
```bash
git add ml_pipelines/
git commit -m "Update pipeline"
git push origin main
```

Or manually trigger via GitHub Actions UI.

### Approve Model for Deployment:

1. Go to **SageMaker Console** → **Model Registry**
2. Find your model package group
3. Select the latest model version
4. Click **Update status** → **Approve**

This automatically triggers the deployment workflow via EventBridge → Lambda → GitHub.

## Template Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| SageMakerProjectName | Project name | - |
| SageMakerProjectId | Auto-generated project ID | - |
| CodeRepositoryName | GitHub repo name | - |
| GitHubRepositoryOwnerName | GitHub username/org | - |
| CodestarConnectionUniqueId | CodeStar connection ID | - |
| GitHubTokenSecretName | Secrets Manager secret name | - |
| GitHubWorkflowNameForDeployment | Deploy workflow filename | deploy.yml |
| GlueDatabaseName | Glue database name | "" |
| GlueTableName | Glue table name | "" |
| LambdaS3Bucket | S3 bucket with Lambda zip | - |
| LambdaS3Key | Lambda zip S3 key | lambda-github-workflow-trigger.zip |

## Resources Created

- **S3 Bucket**: `sagemaker-project-github-{PROJECT_ID}-{REGION}`
- **Lambda Function**: `{PROJECT_NAME}-github-trigger`
- **EventBridge Rule**: `{PROJECT_NAME}-model-approval`
- **IAM Role**: `{PROJECT_NAME}-lambda-role`
- **SageMaker Code Repository**: `{PROJECT_NAME}-{PROJECT_ID}`
- **Model Package Group**: `{PROJECT_NAME}-{PROJECT_ID}`

## Troubleshooting

### Template not visible in Studio:
```bash
# Check tag
aws s3api get-object-tagging \
  --bucket $BUCKET_NAME \
  --key templates/classification-mlops-github.yaml

# Check domain tag
aws sagemaker list-tags \
  --resource-arn arn:aws:sagemaker:$AWS_REGION:$AWS_ACCOUNT_ID:domain/$DOMAIN_ID
```

### Lambda deployment fails:
```bash
# Check Lambda logs
aws logs tail /aws/lambda/<project-name>-github-trigger --follow
```

### Pipeline execution fails:
```bash
# Check pipeline status
aws sagemaker list-pipeline-executions \
  --pipeline-name <project-name>-<project-id>

# Check failed steps
aws sagemaker list-pipeline-execution-steps \
  --pipeline-execution-arn <execution-arn> \
  --query 'PipelineExecutionSteps[?StepStatus==`Failed`]'
```

## Features

✅ Glue Catalog integration for data access  
✅ AWS Data Wrangler for preprocessing  
✅ XGBoost classification model  
✅ Comprehensive evaluation metrics  
✅ Conditional model registration (accuracy ≥ 0.7)  
✅ Optional MLflow experiment tracking  
✅ Automated deployment on approval  
✅ Multi-environment deployment (staging/prod)  
✅ GitHub Actions CI/CD  
✅ EventBridge-driven automation  

## Clean Up

```bash
# Delete SageMaker project (via Studio UI or CLI)
aws sagemaker delete-project --project-name <project-name>

# Delete CloudFormation stack (if needed)
aws cloudformation delete-stack --stack-name <stack-name>

# Delete S3 artifacts
aws s3 rm s3://sagemaker-project-github-<project-id>-<region> --recursive
aws s3 rb s3://sagemaker-project-github-<project-id>-<region>
```

## License

MIT-0
