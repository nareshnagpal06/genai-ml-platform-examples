# MLflow Integration - Changes Summary

## Files Modified

### 1. source_scripts/preprocessing/prepare_bank_data/main.py
- **Added imports**: `mlflow`, `strftime`, `gmtime`
- **Added MLflow setup**: Reads environment variables and initializes tracking
- **Added logging**: Logs preprocessing parameters (row counts, database/table)
- **Added cleanup**: Ensures MLflow run ends properly with try/finally

### 2. source_scripts/evaluate/evaluate_xgboost/main.py
- **Added imports**: `mlflow`, `strftime`, `gmtime`
- **Added MLflow setup**: Reads environment variables and initializes tracking
- **Added metrics logging**: Logs accuracy, precision, recall, f1_score, auc
- **Added artifact logging**: Logs evaluation.json report
- **Added cleanup**: Ensures MLflow run ends properly with try/finally

### 3. ml_pipelines/training/pipeline.py
- **Added parameters**: 
  - `mlflow_tracking_uri` (ParameterString)
  - `mlflow_experiment_name` (ParameterString, default: "BankMarketingExperiment")
- **Updated preprocessing step**: Added environment variables for MLflow
- **Updated evaluation step**: Added environment variables for MLflow
- **Updated pipeline definition**: Included new MLflow parameters

## Files Created

### 1. source_scripts/helpers/mlflow_helper.py
- Reusable utility function for MLflow setup
- Handles environment variable reading
- Provides consistent initialization pattern

### 2. source_scripts/preprocessing/prepare_bank_data/requirements.txt
- Added `mlflow` dependency
- Added `boto3` dependency

### 3. source_scripts/evaluate/evaluate_xgboost/requirements.txt
- Added `mlflow` dependency
- Added `boto3` dependency

### 4. MLFLOW_INTEGRATION.md
- Complete documentation of MLflow integration
- Usage examples
- Configuration guide
- Tracked metrics reference

### 5. MLFLOW_CHANGES_SUMMARY.md (this file)
- Summary of all changes made

## Key Features

1. **Optional Tracking**: MLflow is only activated when `MLFLOW_TRACKING_URI` is provided
2. **Environment-Based Config**: Uses environment variables for flexibility
3. **Nested Runs**: Supports nested run structure for pipeline organization
4. **Comprehensive Logging**: Tracks parameters, metrics, and artifacts
5. **Error Handling**: Proper cleanup with try/finally blocks

## Testing

To test the integration:

1. Set up an MLflow tracking server (SageMaker MLflow or standalone)
2. Run the pipeline with MLflow parameters:
   ```python
   pipeline.start(
       parameters={
           "MLflowTrackingUri": "your-tracking-uri",
           "MLflowExperimentName": "TestExperiment"
       }
   )
   ```
3. Check MLflow UI for logged metrics and artifacts

## Backward Compatibility

All changes are backward compatible. The pipeline works without MLflow configuration - tracking is simply skipped if not configured.
