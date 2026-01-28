# IAM Role for EC2 Backend Instances
resource "aws_iam_role" "backend" {
  name = "${var.project_name}-backend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-backend-role"
  }
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.project_name}-backend-cloudwatch-logs"
  role = aws_iam_role.backend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Policy for CloudWatch Agent
resource "aws_iam_role_policy" "cloudwatch_agent" {
  name = "${var.project_name}-backend-cloudwatch-agent"
  role = aws_iam_role.backend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for ECR Access (pulling images)
resource "aws_iam_role_policy" "ecr_access" {
  name = "${var.project_name}-backend-ecr-access"
  role = aws_iam_role.backend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for SSM (Systems Manager - for debugging/access)
resource "aws_iam_role_policy" "ssm_access" {
  name = "${var.project_name}-backend-ssm-access"
  role = aws_iam_role.backend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:AcknowledgeMessage",
          "ssmmessages:GetEndpoint",
          "ssmmessages:GetMessages",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "backend" {
  name = "${var.project_name}-backend-profile"
  role = aws_iam_role.backend.name
}
