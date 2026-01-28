#!/bin/bash
set -e

# Bootstrap script to create S3 bucket and DynamoDB table for Terraform state management
# This should be run manually ONCE before deploying infrastructure

BUCKET_NAME="starttech-terraform-state-prod"
TABLE_NAME="starttech-terraform-locks"
REGION="eu-north-1"

echo "========================================="
echo "Terraform Backend Bootstrap"
echo "========================================="
echo ""
echo "Region: $REGION"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $TABLE_NAME"
echo ""

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured"
    exit 1
fi

echo "AWS credentials found"
echo ""

# Create S3 bucket if it doesn't exist
if aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
    echo "S3 bucket already exists: $BUCKET_NAME"
else
    echo "Creating S3 bucket: $BUCKET_NAME"
    aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled \
        --region "$REGION"
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }' \
        --region "$REGION"
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
        --region "$REGION"
    
    echo " S3 bucket created with encryption and versioning enabled"
fi

echo ""

# Create DynamoDB table if it doesn't exist
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
    echo "DynamoDB table already exists: $TABLE_NAME"
else
    echo "Creating DynamoDB table: $TABLE_NAME"
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION"
    
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$REGION"
    echo "DynamoDB table created"
fi

echo ""
echo "========================================="
echo "Bootstrap Complete!"
echo "========================================="
echo ""
echo "Terraform backend is ready to use."
echo "You can now run: terraform init"
echo ""
