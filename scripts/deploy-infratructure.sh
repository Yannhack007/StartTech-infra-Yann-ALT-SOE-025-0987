#!/bin/bash
set -e

# Install Docker
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Pull and run container
aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin <YOUR_ECR_URL>
docker pull <YOUR_ECR_URL>/starttech-backend:latest
docker run -d \
  --name backend \
  --restart always \
  -p 8080:8080 \
  --log-driver=awslogs \
  --log-opt awslogs-group=/aws/ec2/starttech-backend \
  --log-opt awslogs-region=eu-north-1 \
  -e MONGODB_URI="${MONGODB_URI}" \
  -e REDIS_ENDPOINT="${REDIS_ENDPOINT}" \
  <YOUR_ECR_URL>/starttech-backend:latest
```

### Secrets GitHub to configure:
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
FRONTEND_BUCKET
CLOUDFRONT_DISTRIBUTION_ID
REACT_APP_API_URL