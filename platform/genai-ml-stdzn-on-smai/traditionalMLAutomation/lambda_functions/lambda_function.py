import json
import os
import boto3
import urllib3

def lambda_handler(event, context):
    """Trigger GitHub workflow when SageMaker model is approved."""
    
    print(f"Received event: {json.dumps(event)}")
    
    # Get environment variables
    secret_name = os.environ['GITHUB_TOKEN_SECRET_NAME']
    repo_owner = os.environ['GITHUB_REPO_OWNER']
    repo_name = os.environ['GITHUB_REPO_NAME']
    workflow_name = os.environ['GITHUB_WORKFLOW_NAME']
    
    # Get GitHub token from Secrets Manager
    secrets_client = boto3.client('secretsmanager')
    try:
        secret_response = secrets_client.get_secret_value(SecretId=secret_name)
        secret_data = json.loads(secret_response['SecretString'])
        github_token = secret_data['token']
    except Exception as e:
        print(f"Error retrieving GitHub token: {e}")
        raise
    
    # Extract model package details from event
    detail = event.get('detail', {})
    model_package_arn = detail.get('ModelPackageArn', '')
    model_package_group_name = detail.get('ModelPackageGroupName', '')
    model_approval_status = detail.get('ModelApprovalStatus', '')
    
    print(f"Model Package ARN: {model_package_arn}")
    print(f"Model Package Group: {model_package_group_name}")
    print(f"Approval Status: {model_approval_status}")
    
    # Trigger GitHub workflow
    http = urllib3.PoolManager()
    
    github_api_url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/workflows/{workflow_name}/dispatches"
    
    headers = {
        'Accept': 'application/vnd.github.v3+json',
        'Authorization': f'token {github_token}',
        'Content-Type': 'application/json'
    }
    
    payload = {
        'ref': 'main',
        'inputs': {
            'model_package_arn': model_package_arn,
            'model_package_group_name': model_package_group_name
        }
    }
    
    try:
        response = http.request(
            'POST',
            github_api_url,
            body=json.dumps(payload).encode('utf-8'),
            headers=headers
        )
        
        print(f"GitHub API response status: {response.status}")
        print(f"GitHub API response: {response.data.decode('utf-8')}")
        
        if response.status == 204:
            return {
                'statusCode': 200,
                'body': json.dumps('Successfully triggered GitHub workflow')
            }
        else:
            raise Exception(f"GitHub API returned status {response.status}")
            
    except Exception as e:
        print(f"Error triggering GitHub workflow: {e}")
        raise
