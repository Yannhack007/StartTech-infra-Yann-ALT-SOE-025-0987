# Terraform Backend Setup Guide

## Overview

This infrastructure uses **AWS S3 + DynamoDB** to store and manage Terraform state remotely. This is essential for team collaboration and CI/CD pipelines.

## Architecture

```
┌─────────────────────────────────────────┐
│       GitHub Actions Workflow           │
│  (or local terraform init/apply)        │
└────────────────┬────────────────────────┘
                 │
                 ├──────────────────────┐
                 │                      │
            ┌────▼─────┐        ┌──────▼────────┐
            │  S3       │        │  DynamoDB      │
            │  Bucket   │◄──────►│  Lock Table    │
            │  (state)  │        │  (concurrent   │
            │           │        │   access)      │
            └───────────┘        └────────────────┘
```

## Why This Setup?

✅ **Shared State**: All team members and CI/CD pipelines access the same state  
✅ **State Locking**: DynamoDB prevents concurrent modifications  
✅ **Encryption**: S3 bucket encrypts state files  
✅ **Versioning**: Keep history of state changes  
✅ **Backup**: Easy to restore from previous state versions  

## One-Time Setup (First Time Only)

### Prerequisites

```bash
# Ensure AWS credentials are configured
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION="eu-north-1"
```

### Bootstrap the Backend

```bash
# Run once to create S3 bucket and DynamoDB table
bash scripts/bootstrap-backend.sh
```

This will:
1. Create S3 bucket `starttech-terraform-state-prod`
2. Enable versioning
3. Enable encryption
4. Block public access
5. Create DynamoDB table `starttech-terraform-locks`

### Initialize Terraform

```bash
cd terraform
terraform init
```

This will:
1. Detect the backend.tf configuration
2. Create a remote state in S3
3. Set up locking with DynamoDB

## Regular Usage

### Local Development

```bash
# Plan changes
bash scripts/deploy-infrastructure.sh plan

# Review the plan, then apply
bash scripts/deploy-infrastructure.sh apply

# View current state
terraform state list
terraform state show aws_instance.mongodb
```

### GitHub Actions (CI/CD)

The workflow automatically:
1. ✅ Validates Terraform code
2. ✅ Creates a plan
3. ✅ Saves plan as artifact
4. ✅ Comments plan on PRs
5. ✅ **Requires manual approval** before applying
6. ✅ Applies changes to main branch
7. ✅ Saves outputs as artifact

## Important Notes

### State File Contents

The state file contains **sensitive information**:
- Database passwords
- API keys
- Private IP addresses

**Never commit terraform.tfstate to git!**

### Bucket & Table Names

Default names in `terraform/backend.tf`:
- **Bucket**: `starttech-terraform-state-prod`
- **Table**: `starttech-terraform-locks`
- **Region**: `eu-north-1`

⚠️ **Change these values** in `terraform/backend.tf` if needed:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-unique-bucket-name"  # Must be globally unique!
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "your-table-name"
  }
}
```

### Troubleshooting

#### Error: "InvalidBucketName"
The bucket name must be globally unique across all AWS accounts.

**Solution**: Change the bucket name in `terraform/backend.tf`

#### Error: "AccessDenied" to DynamoDB
Your AWS user doesn't have DynamoDB permissions.

**Solution**: Ensure your IAM user has these policies:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": ["arn:aws:s3:::starttech-terraform-state-prod*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/starttech-terraform-locks"
    }
  ]
}
```

#### Error: "State lock failed"
Another process is modifying the state.

**Solution**: Wait for the other process to finish, or:
```bash
terraform force-unlock <LOCK_ID>
```

## State Management Commands

```bash
# View current state
terraform state list

# Show details of a resource
terraform state show aws_lb.this

# Refresh state from AWS
terraform refresh

# Move resource in state (renaming)
terraform state mv aws_instance.old aws_instance.new

# Remove resource from state (but not from AWS)
terraform state rm aws_instance.mongodb
```

## Backup & Disaster Recovery

### Manual Backup

```bash
# Download current state
aws s3 cp s3://starttech-terraform-state-prod/infrastructure/terraform.tfstate ./backup-$(date +%Y%m%d).tfstate

# List all state versions
aws s3api list-object-versions --bucket starttech-terraform-state-prod --prefix infrastructure/
```

### Restore from Backup

```bash
# Restore a previous version
aws s3api get-object \
  --bucket starttech-terraform-state-prod \
  --key infrastructure/terraform.tfstate \
  --version-id <VERSION_ID> \
  ./restored.tfstate

# Use restored state
cp restored.tfstate .terraform/

# Re-apply with restored state
terraform apply
```

## Best Practices

✅ **Always plan before apply**
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

✅ **Use workspaces for multiple environments** (if needed)
```bash
terraform workspace new staging
terraform workspace select staging
terraform apply
```

✅ **Tag resources clearly**
```hcl
tags = {
  Environment = "production"
  ManagedBy   = "terraform"
  CreatedDate = "2026-01-28"
}
```

✅ **Review state regularly**
```bash
terraform state list
terraform show
```

✅ **Lock sensitive outputs**
```hcl
output "database_password" {
  value     = aws_instance.mongodb.password
  sensitive = true  # Hides from logs
}
```

## References

- [Terraform S3 Backend](https://www.terraform.io/language/settings/backends/s3)
- [Terraform State](https://www.terraform.io/language/state)
- [AWS S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
