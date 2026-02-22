# Bank Marketing Classification - SageMaker Project Template

This directory has been adapted to work as a SageMaker Project Template with GitHub Actions integration.

## Key Changes Made

### 1. Pipeline Execution (`ml_pipelines/run_pipeline.py`)
- Simplified to match SageMaker project template pattern
- Uses `get_pipeline_driver()` and `get_pipeline_custom_tags()` from `_utils.py`
- Waits for pipeline execution to complete
- Removed MLflow-specific command-line arguments (MLflow still works via pipeline parameters)

### 2. GitHub Actions Workflow (`.github/workflows/build.yml`)
- New simplified workflow matching SageMaker project template pattern
- Uses OIDC role assumption instead of access keys
- Dynamically retrieves project details from SageMaker
- Constructs artifact bucket name: `sagemaker-project-github-{PROJECT_ID}-{REGION}`
- Uses standard `AmazonSageMakerProjectsUseRole` for pipeline execution

### 3. Package Structure
- Added `setup.py` and `setup.cfg` for proper package installation
- Updated `requirements.txt` to install package in editable mode (`-e .`)
- Enables `run-pipeline` and `get-pipeline` console commands

### 4. Pipeline Function Signature
- Added `sagemaker_project_arn` parameter to `get_pipeline()` function
- Required for proper project tagging and integration

## Required GitHub Secrets

When using this as a SageMaker project template, configure these secrets:

- `OIDC_ROLE_GITHUB_WORKFLOW` - IAM role ARN for GitHub Actions OIDC authentication
- `GLUE_DATABASE` - Glue database name containing training data
- `GLUE_TABLE` - Glue table name with training data

## Environment Variables in Workflow

Set in `.github/workflows/build.yml`:
- `AWS_REGION` - AWS region (default: us-east-1)
- `SAGEMAKER_PROJECT_NAME` - Name of the SageMaker project

## How It Works

1. **Trigger**: Push to `main` branch with changes to `ml_pipelines/` or `source_scripts/`
2. **Authentication**: GitHub Actions assumes OIDC role
3. **Project Discovery**: Retrieves SageMaker project ID and ARN
4. **Pipeline Execution**: Runs SageMaker pipeline with proper tagging
5. **Monitoring**: Waits for pipeline completion (max 2 hours)

## Differences from Original SMUS Version

| Aspect | Original SMUS | SageMaker Project Template |
|--------|---------------|----------------------------|
| Authentication | OIDC with custom secrets | OIDC with standard role |
| Project Info | From GitHub secrets | From SageMaker API |
| Bucket Name | Custom secret | Auto-generated pattern |
| Pipeline Role | Custom secret | Standard `AmazonSageMakerProjectsUseRole` |
| Workflow File | `build_sagemaker_pipeline.yml` | `build.yml` |
| Execution Control | `TRIGGER_PIPELINE_EXECUTION` variable | Always executes |
| Monitoring | Custom monitoring step | Built into `run_pipeline.py` |

## Integration with Model Deploy

The model_deploy directory remains unchanged and will be triggered automatically when a model is approved in the Model Registry via EventBridge and Lambda.
