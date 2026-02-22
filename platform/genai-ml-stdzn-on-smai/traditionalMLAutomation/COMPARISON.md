# Template Comparison: Classification vs Reference

## File Structure Comparison

| Component | Reference Template | Classification Template | Status |
|-----------|-------------------|------------------------|--------|
| **CloudFormation** | template.yaml | template.yaml | ✅ Created |
| **Lambda Function** | lambda_function.py | lambda_function.py | ✅ Created |
| **Lambda Requirements** | requirements.txt | requirements.txt | ✅ Created |
| **IAM Policies** | GithubActionsMLOpsExecutionPolicy.json | GithubActionsMLOpsExecutionPolicy.json | ✅ Created |
| **IAM Roles** | sagemaker-projects-roles-and-policies.yaml | sagemaker-projects-roles-and-policies.yaml | ✅ Copied |
| **Deployment Script** | deploy-lambda.sh | package-lambda.sh + deploy-template.sh | ✅ Enhanced |
| **Documentation** | README.md | README.md + QUICKSTART.md | ✅ Expanded |

## CloudFormation Parameters

| Parameter | Reference | Classification | Notes |
|-----------|-----------|----------------|-------|
| SageMakerProjectName | ✅ | ✅ | Same |
| SageMakerProjectId | ✅ | ✅ | Same |
| CodeRepositoryName | ✅ | ✅ | Same |
| GitHubRepositoryOwnerName | ✅ | ✅ | Same |
| CodestarConnectionUniqueId | ✅ | ✅ | Same |
| GitHubTokenSecretName | ✅ | ✅ | Same |
| GitHubWorkflowNameForDeployment | ✅ | ✅ | Same |
| LambdaS3Bucket | ✅ | ✅ | Same |
| LambdaS3Key | ✅ | ✅ | Same |
| **GlueDatabaseName** | ❌ | ✅ | **New** |
| **GlueTableName** | ❌ | ✅ | **New** |

## Resources Created

| Resource | Reference | Classification | Differences |
|----------|-----------|----------------|-------------|
| S3 Bucket | ✅ | ✅ | Same naming pattern |
| Lambda Function | ✅ | ✅ | Same logic |
| Lambda IAM Role | ✅ | ✅ | Same permissions |
| EventBridge Rule | ✅ | ✅ | Same pattern matching |
| Lambda Permission | ✅ | ✅ | Same |
| Code Repository | ✅ | ✅ | Same |

## Seed Code Structure

| Component | Reference (Abalone) | Classification (Bank Marketing) |
|-----------|---------------------|--------------------------------|
| **Pipeline Location** | pipelines/abalone/ | ml_pipelines/training/ |
| **Data Source** | S3 CSV | AWS Glue Catalog |
| **Preprocessing** | preprocess.py | prepare_bank_data/main.py |
| **Training** | Built-in XGBoost | Script-mode XGBoost |
| **Evaluation** | evaluate.py | evaluate_xgboost/main.py |
| **Model Type** | Regression | Binary Classification |
| **Features** | 8 numeric | 10 numeric + 10 categorical |
| **Metrics** | MSE, R² | Accuracy, Precision, Recall, F1, AUC |
| **MLflow** | ❌ | ✅ Optional |
| **Helpers** | ❌ | ✅ mlflow_helper, s3_helper, logger |

## GitHub Workflows

### Build Workflow

| Aspect | Reference | Classification |
|--------|-----------|----------------|
| **Trigger Paths** | pipelines/** | ml_pipelines/**, source_scripts/** |
| **Python Version** | 3.10 | 3.10 |
| **Auth Method** | Access Keys | OIDC (same) |
| **Pipeline Module** | pipelines.abalone.pipeline | training.pipeline |
| **Install Command** | pip install --upgrade . | pip install -r requirements.txt |
| **Console Command** | run-pipeline | python ml_pipelines/run_pipeline.py |
| **Extra Params** | - | glue_database_name, glue_table_name |

### Deploy Workflow

| Aspect | Reference | Classification |
|--------|-----------|----------------|
| **Trigger** | workflow_dispatch | workflow_dispatch (same) |
| **Environments** | Staging → Production | Staging → Production (same) |
| **Deployment Tool** | CloudFormation | CDK |
| **Config Files** | staging-config.json, prod-config.json | endpoint-config.yml |

## IAM Permissions

### Additional Permissions in Classification

```json
{
  "Effect": "Allow",
  "Action": [
    "glue:GetDatabase",
    "glue:GetTable",
    "glue:GetPartitions",
    "glue:GetPartition",
    "glue:BatchGetPartition"
  ],
  "Resource": "*"
}
```

## Pipeline Steps Comparison

| Step | Reference | Classification |
|------|-----------|----------------|
| **1. Preprocessing** | SKLearnProcessor | FrameworkProcessor (sklearn) |
| **2. Training** | Built-in XGBoost | Script-mode XGBoost |
| **3. Evaluation** | ScriptProcessor | FrameworkProcessor (sklearn) |
| **4. Condition** | MSE < threshold | Accuracy ≥ 0.7 |
| **5. Registration** | RegisterModel | RegisterModel |

## Key Enhancements in Classification Template

1. **Glue Catalog Integration**
   - Direct data access from Glue tables
   - No need to upload CSV files
   - Dynamic schema handling

2. **AWS Data Wrangler**
   - Efficient data loading from Glue
   - Pandas-like interface
   - Automatic type conversion

3. **MLflow Integration**
   - Optional experiment tracking
   - Nested run support
   - Automatic metric logging

4. **Enhanced Preprocessing**
   - Feature engineering pipeline
   - One-hot encoding for categoricals
   - Standard scaling for numerics
   - Train/validation/test splits

5. **Comprehensive Evaluation**
   - Multiple classification metrics
   - Confusion matrix support
   - ROC-AUC calculation

6. **Better Documentation**
   - QUICKSTART.md for fast setup
   - IMPLEMENTATION_SUMMARY.md
   - SAGEMAKER_PROJECT_CHANGES.md in seed code

## Migration Path

To migrate from reference template to classification:

1. **Update CloudFormation**: Add Glue parameters
2. **Update Lambda**: No changes needed (same logic)
3. **Update IAM**: Add Glue permissions
4. **Replace Seed Code**: Use classification seed code
5. **Update Workflows**: Change module paths and add Glue params
6. **Test**: Verify Glue access and pipeline execution

## Compatibility Matrix

| AWS Service | Reference | Classification |
|-------------|-----------|----------------|
| SageMaker Pipelines | ✅ | ✅ |
| SageMaker Processing | ✅ | ✅ |
| SageMaker Training | ✅ | ✅ |
| SageMaker Model Registry | ✅ | ✅ |
| SageMaker Endpoints | ✅ | ✅ |
| EventBridge | ✅ | ✅ |
| Lambda | ✅ | ✅ |
| S3 | ✅ | ✅ |
| GitHub Actions | ✅ | ✅ |
| CodeStar Connections | ✅ | ✅ |
| **AWS Glue** | ❌ | ✅ |
| **MLflow** | ❌ | ✅ (optional) |

## Cost Comparison

Both templates have similar cost structures:

| Service | Reference | Classification | Notes |
|---------|-----------|----------------|-------|
| S3 Storage | ~$0.023/GB | ~$0.023/GB | Same |
| Lambda Invocations | ~$0.20/1M | ~$0.20/1M | Same |
| EventBridge | Free tier | Free tier | Same |
| SageMaker Processing | ~$0.056/hr (ml.m5.xlarge) | ~$0.056/hr (ml.m5.xlarge) | Same |
| SageMaker Training | ~$0.056/hr (ml.m5.xlarge) | ~$0.056/hr (ml.m5.xlarge) | Same |
| **Glue Catalog** | N/A | Free (metadata) | New |
| **Data Transfer** | Minimal | Minimal (Glue→S3) | Similar |

## Deployment Time

| Phase | Reference | Classification |
|-------|-----------|----------------|
| Template Upload | ~1 min | ~1 min |
| Project Creation | ~2-3 min | ~2-3 min |
| First Pipeline Run | ~15-20 min | ~15-20 min |
| Model Registration | ~1 min | ~1 min |
| Deployment | ~10-15 min | ~10-15 min |
| **Total** | **~30-40 min** | **~30-40 min** |

---

**Conclusion:** The classification template maintains full compatibility with the SageMaker Projects framework while adding Glue Catalog integration and enhanced ML capabilities.
