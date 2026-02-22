# Quick Start Guide - Classification MLOps Template

## 5-Minute Setup

### 1. Set Environment Variables
```bash
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export BUCKET_NAME="sagemaker-projects-templates-${AWS_ACCOUNT_ID}-${AWS_REGION}"
export DOMAIN_ID="d-xxxxxxxxxx"  # Your SageMaker domain ID
```

### 2. Deploy Template
```bash
cd /home/ubuntu/projects/sagemaker-custom-project-templates/s3_templates/classification-mlops-github/scripts
./deploy-template.sh
```

### 3. Configure SageMaker Domain
```bash
aws sagemaker add-tags \
  --resource-arn arn:aws:sagemaker:${AWS_REGION}:${AWS_ACCOUNT_ID}:domain/${DOMAIN_ID} \
  --tags Key=sagemaker:projectS3TemplatesLocation,Value=s3://${BUCKET_NAME}/templates/
```

### 4. Create GitHub Repository
- Name must start with `sagemaker-` (e.g., `sagemaker-bank-classification`)
- Copy seed code from: `/home/ubuntu/projects/genai-ml-platform-examples/platform/genai-ml-stdzn-on-smai/seed-code/MLAutomation/`

### 5. Setup GitHub Token
```bash
# Create fine-grained token with Actions, Contents, Workflows permissions
# Then store it:
aws secretsmanager create-secret \
  --name sagemaker-github-token \
  --secret-string '{"token":"ghp_xxxxxxxxxxxxx"}'
```

### 6. Create CodeConnection
- Go to AWS Console → Developer Tools → Connections
- Create connection to GitHub
- Tag it: `sagemaker=true`
- Note the connection ID (last part of ARN)

### 7. Create Project in SageMaker Studio
- Projects → Create project → Organization templates
- Select "Bank Marketing Classification MLOps"
- Fill in:
  - Project Name: `bank-marketing-test`
  - GitHub Owner: `your-username`
  - Repository: `sagemaker-bank-classification`
  - Connection ID: `abc123...` (from step 6)
  - Token Secret: `sagemaker-github-token`
  - Glue Database: `your_database`
  - Glue Table: `your_table`

### 8. Configure GitHub Secrets
In your GitHub repo → Settings → Secrets:
```
OIDC_ROLE_GITHUB_WORKFLOW=arn:aws:iam::ACCOUNT:role/GitHubActionsRole
GLUE_DATABASE=your_database
GLUE_TABLE=your_table
```

### 9. Trigger Pipeline
```bash
# Push to main branch
git push origin main

# Or manually trigger in GitHub Actions
```

## Verification Checklist

- [ ] Template visible in SageMaker Studio
- [ ] Project created successfully
- [ ] CloudFormation stack deployed
- [ ] S3 bucket created
- [ ] Lambda function deployed
- [ ] EventBridge rule active
- [ ] GitHub workflow runs
- [ ] Pipeline executes
- [ ] Model registered

## Common Issues

**Template not visible:**
```bash
# Check template tag
aws s3api get-object-tagging --bucket $BUCKET_NAME --key templates/classification-mlops-github.yaml

# Check domain tag
aws sagemaker list-tags --resource-arn arn:aws:sagemaker:$AWS_REGION:$AWS_ACCOUNT_ID:domain/$DOMAIN_ID
```

**GitHub workflow fails:**
- Verify OIDC role exists and has correct trust policy
- Check GitHub secrets are set correctly
- Ensure Glue database/table exist

**Pipeline fails:**
- Check CloudWatch logs: `/aws/sagemaker/ProcessingJobs`
- Verify IAM role has Glue permissions
- Confirm Glue table schema matches expected format

## Next Steps

- Customize pipeline in `ml_pipelines/training/pipeline.py`
- Modify preprocessing in `source_scripts/preprocessing/`
- Add MLflow tracking URI to pipeline parameters
- Configure model monitoring
- Set up multi-environment deployment
