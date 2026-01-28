#!/bin/bash
set -e

echo "========================================="
echo "StartTech Backend Instance Setup"
echo "========================================="

# Update system
yum update -y

# Install Docker
echo "📦 Installing Docker..."
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install CloudWatch agent
echo "📊 Installing CloudWatch Agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch Logs
echo "📝 Configuring CloudWatch Logs..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/docker-backend.log",
            "log_group_name": "/aws/ec2/starttech-backend",
            "log_stream_name": "{instance_id}/backend"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Note: ECR login and docker run will be done by deployment pipeline
# This script only sets up the instance

echo "Instance setup complete!"
echo "Waiting for backend deployment from CI/CD pipeline..."