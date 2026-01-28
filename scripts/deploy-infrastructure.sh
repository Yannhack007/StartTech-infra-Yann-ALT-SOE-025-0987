#!/bin/bash
set -e

# Deploy infrastructure using Terraform
# Usage: ./deploy-infrastructure.sh [plan|apply|destroy]

COMMAND="${1:-plan}"
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform" && pwd)"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "StartTech Infrastructure Deployment"
echo "========================================="
echo ""
echo "Command: $COMMAND"
echo "Terraform Directory: $TERRAFORM_DIR"
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed"
    echo "Install from: https://www.terraform.io/downloads"
    exit 1
fi

TERRAFORM_VERSION=$(terraform version | head -n 1)
echo "✅ $TERRAFORM_VERSION"
echo ""

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured"
    echo "Run: aws configure"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
echo "AWS Account: $AWS_ACCOUNT"
echo "AWS Region: $AWS_REGION"
echo ""

# Check if terraform.tfvars exists
if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found"
    echo "Copy and configure terraform.tfvars.example:"
    echo "  cp $TERRAFORM_DIR/terraform.tfvars.example $TERRAFORM_DIR/terraform.tfvars"
    exit 1
fi

echo "terraform.tfvars found"
echo ""

cd "$TERRAFORM_DIR"

case "$COMMAND" in
    plan)
        echo "Running terraform plan..."
        terraform init
        terraform plan -out=tfplan
        echo ""
        echo "Plan complete!"
        echo "Review the plan above and run: ./deploy-infrastructure.sh apply"
        ;;
    
    apply)
        echo "Applying infrastructure changes..."
        if [ ! -f tfplan ]; then
            echo "Error: No plan file found"
            echo "Run: ./deploy-infrastructure.sh plan"
            exit 1
        fi
        terraform apply tfplan
        
        echo ""
        echo "========================================="
        echo "INFRASTRUCTURE DEPLOYMENT COMPLETE!"
        echo "========================================="
        echo ""
        echo "Outputs:"
        echo "--------"
        terraform output -no-color
        echo ""
        echo "Next steps:"
        echo "1. Copy the outputs above to your .env or config files"
        echo "2. Deploy the backend application"
        echo "3. Deploy the frontend application"
        echo ""
        ;;
    
    destroy)
        echo "WARNING: This will destroy all infrastructure!"
        read -p "Are you sure? Type 'yes' to confirm: " CONFIRM
        
        if [ "$CONFIRM" != "yes" ]; then
            echo "Aborted"
            exit 0
        fi
        
        echo ""
        echo "Destroying infrastructure..."
        terraform destroy
        echo ""
        echo "Infrastructure destroyed"
        ;;
    
    output)
        echo "Terraform outputs:"
        terraform output -no-color
        ;;
    
    *)
        echo "Usage: $0 [plan|apply|destroy|output]"
        echo ""
        echo "Commands:"
        echo "  plan    - Show what will be created/changed/destroyed"
        echo "  apply   - Apply the planned changes (after plan)"
        echo "  destroy - Destroy all infrastructure (CAREFUL!)"
        echo "  output  - Show terraform outputs"
        exit 1
        ;;
esac

echo ""
