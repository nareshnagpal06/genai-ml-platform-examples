#!/bin/bash
set -e

# Setup GitHub OIDC Role for GitHub Actions
# This is a prerequisite for the SageMaker project template

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMPLATE_DIR="${SCRIPT_DIR}/.."

# Check environment variables
if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$GITHUB_REPO_OWNER" ] || [ -z "$GITHUB_REPO_NAME" ]; then
    echo "Error: Required environment variables not set"
    echo "Please set: AWS_ACCOUNT_ID, GITHUB_REPO_OWNER, GITHUB_REPO_NAME"
    echo ""
    echo "Example:"
    echo "  export AWS_ACCOUNT_ID=123456789012"
    echo "  export GITHUB_REPO_OWNER=your-username"
    echo "  export GITHUB_REPO_NAME=sagemaker-projects-seedcode"
    exit 1
fi

echo "========================================="
echo "Setting up GitHub OIDC Role"
echo "========================================="
echo "Account: $AWS_ACCOUNT_ID"
echo "GitHub Repo: $GITHUB_REPO_OWNER/$GITHUB_REPO_NAME"
echo ""

# Check if OIDC provider exists
echo "Checking OIDC provider..."
OIDC_PROVIDER=$(aws iam list-open-id-connect-providers \
    --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)].Arn' \
    --output text)

if [ -z "$OIDC_PROVIDER" ]; then
    echo "Creating GitHub OIDC provider..."
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
    echo "✓ OIDC provider created"
else
    echo "✓ OIDC provider already exists: $OIDC_PROVIDER"
fi

# Create trust policy
echo ""
echo "Creating trust policy..."
cat > /tmp/github-oidc-trust.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}:*"
        }
      }
    }
  ]
}
EOF

# Check if role exists
ROLE_EXISTS=$(aws iam get-role --role-name GitHubActionsOIDCRole 2>/dev/null || echo "")

if [ -z "$ROLE_EXISTS" ]; then
    echo "Creating GitHubActionsOIDCRole..."
    aws iam create-role \
        --role-name GitHubActionsOIDCRole \
        --assume-role-policy-document file:///tmp/github-oidc-trust.json
    echo "✓ Role created"
else
    echo "✓ Role already exists, updating trust policy..."
    aws iam update-assume-role-policy \
        --role-name GitHubActionsOIDCRole \
        --policy-document file:///tmp/github-oidc-trust.json
fi

# Attach policy
echo ""
echo "Attaching SageMaker GitHub Actions policy..."
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/SageMakerGitHubActionsPolicy"

# Check if policy exists
if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
    aws iam attach-role-policy \
        --role-name GitHubActionsOIDCRole \
        --policy-arn "$POLICY_ARN" 2>/dev/null || echo "Policy already attached"
    echo "✓ Policy attached"
else
    echo "⚠ Warning: Policy $POLICY_ARN not found"
    echo "You need to create this policy first using the infrastructure deployment"
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Add this to your GitHub repository secrets:"
echo "OIDC_ROLE_GITHUB_WORKFLOW=arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsOIDCRole"
echo ""
