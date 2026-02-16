# MLflow Integration Guide

This document describes the MLflow integration added to the classification model build pipeline.

## Overview

MLflow tracking has been integrated into the SageMaker pipeline to provide experiment tracking, metrics logging, and artifact management across preprocessing, training, and evaluation steps.

## Components Modified

### 1. Preprocessing Script
**File**: `source_scripts/preprocessing/prepare_bank_data/main.py`

**Changes**:
- Added MLflow tracking initialization
- Logs preprocessing parameters (row counts, database/table info)
- Automatically ends run on completion

**Environment Variables**:
- `MLFLOW_TRACKING_URI`: MLflow tracking server URI
- `MLFLOW_EXPERIMENT_NAME`: Experiment name (optional)
- `MLFLOW_RUN_ID`: Existing run ID to continue (optional)

### 2. Evaluation Script
**File**: `source_scripts/evaluate/evaluate_xgboost/main.py`

**Changes**:
- Added MLflow tracking initialization
- Logs all classification metrics (accuracy, precision, recall, f1, auc)
- Logs evaluation report as artifact
- Automatically ends run on completion

**Environment Variables**: Same as preprocessing

### 3. Pipeline Definition
**File**: `ml_pipelines/training/pipeline.py`

**Changes**:
- Added pipeline parameters for MLflow configuration
- Passes MLflow environment variables to processing steps
- New parameters:
  - `MLflowTrackingUri`: Tracking server URI
  - `MLflowExperimentName`: Experiment name (default: "BankMarketingExperiment")

### 4. Helper Module
**File**: `source_scripts/helpers/mlflow_helper.py`

**Purpose**: Reusable utility for MLflow setup across pipeline steps

**Usage**:
```python
from helpers.mlflow_helper import setup_mlflow

experiment, run = setup_mlflow("step_name")
if run:
    mlflow.log_metric("metric_name", value)
    mlflow.end_run()
```

## Usage

### Running Pipeline with MLflow

When executing the pipeline, provide MLflow parameters:

```python
pipeline.start(
    parameters={
        "MLflowTrackingUri": "arn:aws:sagemaker:region:account:mlflow-tracking-server/name",
        "MLflowExperimentName": "BankMarketingExperiment"
    }
)
```

### Tracked Metrics

**Preprocessing**:
- `total_rows`: Total dataset rows
- `train_rows`: Training set size
- `validation_rows`: Validation set size
- `test_rows`: Test set size
- `database`: Glue database name
- `table`: Glue table name

**Evaluation**:
- `accuracy`: Model accuracy
- `precision`: Precision score
- `recall`: Recall score
- `f1_score`: F1 score
- `auc`: AUC-ROC score

**Artifacts**:
- `evaluation.json`: Complete evaluation report

## Requirements

MLflow has been added to the requirements files:
- `source_scripts/preprocessing/prepare_bank_data/requirements.txt`
- `source_scripts/evaluate/evaluate_xgboost/requirements.txt`

## Optional Configuration

MLflow tracking is optional. If `MLFLOW_TRACKING_URI` is not provided, the pipeline runs without tracking.

## Reference Implementation

The integration follows patterns from:
`/home/ubuntu/projects/amazon-sagemaker-from-idea-to-production/pipeline_steps/`

Key patterns:
- Environment-based configuration
- Nested run support
- Automatic cleanup with try/finally
- Optional tracking (graceful degradation)
