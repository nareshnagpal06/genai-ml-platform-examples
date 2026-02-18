# Deployment Checklist

Use this checklist to ensure successful deployment of the Classification MLOps template.

## Pre-Deployment

### AWS Account Setup
- [ ] AWS CLI configured with appropriate credentials
- [ ] Account has SageMaker domain created
- [ ] Domain ID noted: `d-_______________`
- [ ] Region selected: `_______________`

### GitHub Setup
- [ ] GitHub account/organization ready
- [ ] Repository created (name starts with `sagemaker-`)
- [ ] Repository name: `_______________`
- [ ] Fine-grained personal access token created
- [ ] Token has Actions, Contents, Workflows permissions

### Data Setup
- [ ] Glue database exists
- [ ] Glue database name: `_______________`
- [ ] Glue table exists with training data
- [ ] Glue table name: `_______________`
- [ ] Table schema verified (numeric + categorical columns)

## IAM Setup (One-Time)

- [ ] SageMaker execution role ARN obtained
- [ ] Deployed `sagemaker-projects-roles-and-policies.yaml` stack
- [ ] Added PassRole permission to SageMaker execution role
- [ ] Added CloudFormation stack creation permission
- [ ] Created GitHub Actions IAM user
- [ ] Created access key for GitHub Actions user
- [ ] Attached `SageMakerGitHubActionsPolicy` to user

## Secrets and Connections

- [ ] GitHub token stored in Secrets Manager
  - Secret name: `_______________`
  - Verified secret retrieval works
- [ ] CodeStar connection created to GitHub
  - Connection ARN: `_______________`
  - Connection ID (last part): `_______________`
  - Tagged with `sagemaker=true`
  - Connection status: Available

## Template Deployment

### Environment Variables
```bash
export AWS_REGION=_______________
export AWS_ACCOUNT_ID=_______________
export BUCKET_NAME=_______________
export DOMAIN_ID=_______________
```

- [ ] Environment variables set
- [ ] Variables verified with `echo $AWS_REGION` etc.

### Lambda Packaging
- [ ] Ran `./scripts/package-lambda.sh`
- [ ] Verified `build/lambda-github-workflow-trigger.zip` created
- [ ] Zip file size reasonable (~1-2 MB)

### S3 Upload
- [ ] S3 bucket created or exists
- [ ] CORS policy applied to bucket
- [ ] Lambda zip uploaded to S3
- [ ] Template uploaded to S3
- [ ] Template tagged with `sagemaker:studio-visibility=true`
- [ ] Verified tag with `aws s3api get-object-tagging`

### Domain Configuration
- [ ] Domain tagged with `sagemaker:projectS3TemplatesLocation`
- [ ] Tag value: `s3://${BUCKET_NAME}/templates/`
- [ ] Verified tag with `aws sagemaker list-tags`

## Template Visibility Check

- [ ] Logged into SageMaker Studio
- [ ] Navigated to Projects → Create project
- [ ] Clicked "Organization templates" tab
- [ ] Template "Bank Marketing Classification MLOps" visible
- [ ] Template description displays correctly

## Project Creation Test

### Create Test Project
- [ ] Clicked "Create project" on template
- [ ] Filled in parameters:
  - Project Name: `_______________`
  - GitHub Owner: `_______________`
  - Repository Name: `_______________`
  - Connection ID: `_______________`
  - Token Secret: `_______________`
  - Glue Database: `_______________`
  - Glue Table: `_______________`
  - Lambda S3 Bucket: `_______________`
- [ ] Clicked "Create project"
- [ ] Project creation started

### Verify CloudFormation
- [ ] CloudFormation stack created
- [ ] Stack name: `sagemaker-${PROJECT_NAME}-${PROJECT_ID}`
- [ ] Stack status: CREATE_COMPLETE
- [ ] All resources created successfully:
  - [ ] S3 bucket
  - [ ] Lambda function
  - [ ] Lambda IAM role
  - [ ] EventBridge rule
  - [ ] Lambda permission
  - [ ] Code repository

### Verify Resources
```bash
# Check S3 bucket
aws s3 ls sagemaker-project-github-${PROJECT_ID}-${REGION}

# Check Lambda function
aws lambda get-function --function-name ${PROJECT_NAME}-github-trigger

# Check EventBridge rule
aws events describe-rule --name ${PROJECT_NAME}-model-approval

# Check Code Repository
aws sagemaker describe-code-repository --code-repository-name ${PROJECT_NAME}-${PROJECT_ID}
```

- [ ] S3 bucket accessible
- [ ] Lambda function exists and configured
- [ ] EventBridge rule enabled
- [ ] Code repository linked

## GitHub Repository Setup

### Copy Seed Code
- [ ] Cloned GitHub repository locally
- [ ] Copied `model_build/` from seed code
- [ ] Copied `model_deploy/` from seed code
- [ ] Committed and pushed to `main` branch

### Configure Secrets
In GitHub repo → Settings → Secrets and variables → Actions:

- [ ] Added `OIDC_ROLE_GITHUB_WORKFLOW`
  - Value: `arn:aws:iam::${ACCOUNT}:role/_______________`
- [ ] Added `GLUE_DATABASE`
  - Value: `_______________`
- [ ] Added `GLUE_TABLE`
  - Value: `_______________`

### Update Workflow
- [ ] Edited `.github/workflows/build.yml`
- [ ] Updated `AWS_REGION` if needed
- [ ] Updated `SAGEMAKER_PROJECT_NAME` to match project name
- [ ] Committed changes

## First Pipeline Run

### Trigger Build
- [ ] Pushed changes to `main` branch OR
- [ ] Manually triggered workflow in GitHub Actions

### Monitor Execution
- [ ] GitHub Actions workflow started
- [ ] Workflow step "Configure AWS Credentials" succeeded
- [ ] Workflow step "Build SageMaker Pipeline" succeeded
- [ ] SageMaker Pipeline created in AWS Console
- [ ] Pipeline execution started

### Check Pipeline
```bash
# List pipeline executions
aws sagemaker list-pipeline-executions \
  --pipeline-name ${PROJECT_NAME}-${PROJECT_ID}

# Get execution ARN and check status
aws sagemaker describe-pipeline-execution \
  --pipeline-execution-arn ${EXECUTION_ARN}
```

- [ ] Pipeline execution status: Executing → Succeeded
- [ ] All steps completed:
  - [ ] PreprocessBankMarketingData
  - [ ] TrainBankMarketingModel
  - [ ] EvaluateBankMarketingModel
  - [ ] CheckAccuracyBankMarketingEvaluation
  - [ ] RegisterBankMarketingModel (if accuracy ≥ 0.7)

### Verify Model Registration
- [ ] Model registered in Model Registry
- [ ] Model package group: `${PROJECT_NAME}-${PROJECT_ID}`
- [ ] Model status: PendingManualApproval
- [ ] Model metrics visible

## Test Deployment Flow

### Approve Model
- [ ] Opened SageMaker Console → Model Registry
- [ ] Found model package group
- [ ] Selected latest model version
- [ ] Clicked "Update status" → "Approve"
- [ ] Status changed to "Approved"

### Verify Lambda Trigger
- [ ] EventBridge rule triggered
- [ ] Lambda function invoked
- [ ] Check Lambda logs:
```bash
aws logs tail /aws/lambda/${PROJECT_NAME}-github-trigger --follow
```
- [ ] Lambda successfully triggered GitHub workflow

### Monitor Deployment
- [ ] GitHub deployment workflow started
- [ ] Staging deployment succeeded
- [ ] Staging tests passed
- [ ] Production deployment succeeded (after approval)
- [ ] Endpoint created and InService

### Test Endpoint
```bash
# Get endpoint name
aws sagemaker list-endpoints --name-contains ${PROJECT_NAME}

# Test inference (use appropriate payload)
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name ${ENDPOINT_NAME} \
  --body '{"instances": [...]}' \
  --content-type application/json \
  output.json
```

- [ ] Endpoint responds successfully
- [ ] Predictions returned

## Post-Deployment

### Documentation
- [ ] Updated project README with specific details
- [ ] Documented Glue table schema
- [ ] Documented any customizations made
- [ ] Created runbook for team

### Monitoring
- [ ] CloudWatch alarms configured (optional)
- [ ] Model monitoring enabled (optional)
- [ ] Data quality monitoring enabled (optional)

### Clean Up Test Resources (if needed)
- [ ] Deleted test endpoints
- [ ] Deleted test model packages
- [ ] Cleaned up S3 test artifacts

## Troubleshooting Reference

### Template Not Visible
```bash
# Check template tag
aws s3api get-object-tagging \
  --bucket $BUCKET_NAME \
  --key templates/classification-mlops-github.yaml

# Check domain tag
aws sagemaker list-tags \
  --resource-arn arn:aws:sagemaker:$AWS_REGION:$AWS_ACCOUNT_ID:domain/$DOMAIN_ID
```

### CloudFormation Fails
- Check CloudFormation events in AWS Console
- Verify all parameters are correct
- Check IAM permissions for launch role

### GitHub Workflow Fails
- Check GitHub Actions logs
- Verify OIDC role trust policy
- Verify GitHub secrets are set
- Check Glue database/table exist

### Pipeline Fails
- Check CloudWatch logs: `/aws/sagemaker/ProcessingJobs`
- Check CloudWatch logs: `/aws/sagemaker/TrainingJobs`
- Verify Glue permissions
- Verify data in Glue table

### Lambda Doesn't Trigger
- Check EventBridge rule is enabled
- Check Lambda permissions
- Check Lambda logs
- Verify GitHub token in Secrets Manager

## Sign-Off

- [ ] All checklist items completed
- [ ] Template deployed successfully
- [ ] Test project created and working
- [ ] Pipeline executed end-to-end
- [ ] Deployment flow tested
- [ ] Documentation updated
- [ ] Team trained on usage

**Deployed by:** _______________  
**Date:** _______________  
**Environment:** ☐ Dev  ☐ Test  ☐ Prod  
**Notes:** _______________________________________________
