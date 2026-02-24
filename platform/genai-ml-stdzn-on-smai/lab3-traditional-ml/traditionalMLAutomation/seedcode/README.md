# SageMaker MLOps Project - Seed Code

This repository contains the seed code for a SageMaker MLOps project with GitHub Actions integration.

## Quick Start

### 1. Setup GitHub OIDC Role

This allows GitHub Actions to authenticate to AWS without access keys.

```bash
export AWS_ACCOUNT_ID=006230620263
export GITHUB_REPO_OWNER=nareshnagpal06
export GITHUB_REPO_NAME=sagemaker-projects-seedcode

./setup-github-oidc.sh
```

This creates an IAM role: `GitHubActionsOIDCRole`

### 2. Configure GitHub Secrets

Go to: https://github.com/nareshnagpal06/sagemaker-projects-seedcode/settings/secrets/actions

Add these secrets:
- `OIDC_ROLE_GITHUB_WORKFLOW` = `arn:aws:iam::006230620263:role/GitHubActionsOIDCRole`
- `GLUE_DATABASE` = Your Glue database name
- `GLUE_TABLE` = Your Glue table name

### 3. Update Project Name

Edit `model_build/.github/workflows/build.yml`:
```yaml
env:
  AWS_REGION: us-west-2
  SAGEMAKER_PROJECT_NAME: your-project-name  # Change this
```

### 4. Push to Trigger Pipeline

```bash
git add .
git commit -m "Configure project"
git push origin main
```

This triggers the GitHub Actions workflow → creates SageMaker Pipeline → trains model.

## Project Structure

```
.
├── model_build/              # Model training pipeline
│   ├── .github/workflows/
│   │   └── build.yml        # Build workflow
│   ├── ml_pipelines/
│   │   ├── training/
│   │   │   └── pipeline.py  # SageMaker Pipeline definition
│   │   └── run_pipeline.py  # Pipeline execution script
│   ├── source_scripts/
│   │   ├── preprocessing/   # Data preprocessing
│   │   ├── training/        # Model training
│   │   └── evaluate/        # Model evaluation
│   ├── setup.py
│   └── requirements.txt
│
├── model_deploy/             # Model deployment
│   ├── .github/workflows/
│   │   └── deploy.yml       # Deployment workflow
│   ├── deploy_endpoint/     # CDK deployment stacks
│   └── config/              # Environment configs
│
└── setup-github-oidc.sh     # OIDC role setup script
```

## How It Works

### Build Pipeline (Automatic on Push)
1. Push changes to `main` branch
2. GitHub Actions workflow triggers
3. Workflow runs `ml_pipelines/run_pipeline.py`
4. SageMaker Pipeline executes:
   - Reads data from Glue Catalog
   - Preprocesses with AWS Data Wrangler
   - Trains XGBoost model
   - Evaluates model
   - Registers model if accuracy ≥ 0.7

### Deployment Pipeline (Automatic on Model Approval)
1. Approve model in SageMaker Model Registry
2. EventBridge detects approval
3. Lambda triggers GitHub deployment workflow
4. Workflow deploys to staging → production

## Prerequisites

- SageMaker project created from template
- AWS Glue database and table with training data
- GitHub repository with this seed code
- GitHub OIDC role configured
- GitHub secrets configured

## Customization

### Change Data Source
Edit `model_build/ml_pipelines/training/pipeline.py`:
- Update `glue_database_name` and `glue_table_name` parameters

### Change Model
Edit `model_build/source_scripts/training/xgboost/train.py`:
- Modify hyperparameters
- Change model type

### Change Evaluation Criteria
Edit `model_build/ml_pipelines/training/pipeline.py`:
- Update condition threshold (currently accuracy ≥ 0.7)

## Troubleshooting

### GitHub Actions Fails
- Check GitHub secrets are set correctly
- Verify OIDC role has correct trust policy
- Check Glue database/table exist

### Pipeline Fails
- Check CloudWatch logs: `/aws/sagemaker/ProcessingJobs`
- Verify Glue permissions
- Check data in Glue table

### Deployment Fails
- Check Lambda logs
- Verify EventBridge rule is enabled
- Check GitHub token in Secrets Manager

## Next Steps

1. Customize the pipeline for your use case
2. Add MLflow tracking (optional)
3. Configure model monitoring
4. Set up multi-environment deployment
