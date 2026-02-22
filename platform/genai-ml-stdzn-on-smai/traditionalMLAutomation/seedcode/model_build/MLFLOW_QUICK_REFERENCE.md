# Quick Reference: MLflow Integration

## Environment Variables

Each processing step accepts these environment variables:

```bash
MLFLOW_TRACKING_URI       # Required: MLflow tracking server URI
MLFLOW_EXPERIMENT_NAME    # Optional: Experiment name
MLFLOW_RUN_ID            # Optional: Existing run ID to continue
```

## Pipeline Parameters

```python
{
    "MLflowTrackingUri": "arn:aws:sagemaker:region:account:mlflow-tracking-server/name",
    "MLflowExperimentName": "BankMarketingExperiment"  # Default provided
}
```

## Logged Metrics

### Preprocessing Step
- `total_rows`: Total dataset size
- `train_rows`: Training set size  
- `validation_rows`: Validation set size
- `test_rows`: Test set size
- `database`: Glue database name
- `table`: Glue table name

### Evaluation Step
- `accuracy`: Classification accuracy
- `precision`: Precision score
- `recall`: Recall score
- `f1_score`: F1 score
- `auc`: AUC-ROC score

### Artifacts
- `evaluation.json`: Complete evaluation report

## Code Pattern

```python
# Setup
tracking_uri = os.environ.get("MLFLOW_TRACKING_URI")
if tracking_uri:
    mlflow.set_tracking_uri(tracking_uri)
    experiment = mlflow.set_experiment(experiment_name=experiment_name)
    run = mlflow.start_run(run_name=f"step-{suffix}", nested=True)

try:
    # Your processing code
    mlflow.log_params({"param": value})
    mlflow.log_metrics({"metric": value})
    mlflow.log_artifact("file.json")
finally:
    if tracking_uri:
        mlflow.end_run()
```

## Testing Without MLflow

Simply omit the MLflow parameters - the pipeline will run normally without tracking:

```python
pipeline.start(
    parameters={
        "GlueDatabase": "my_database",
        "GlueTable": "my_table"
    }
)
```

## Files to Review

1. `MLFLOW_INTEGRATION.md` - Full documentation
2. `MLFLOW_CHANGES_SUMMARY.md` - Change details
3. `example_mlflow_pipeline_run.py` - Usage example
4. `source_scripts/helpers/mlflow_helper.py` - Helper utility
