# StartTech - Architecture Documentation

## Overview

StartTech is a full-stack web application deployed on AWS with a highly available and scalable architecture using AWS managed services.

## Architecture Diagram

```
                                    Internet
                                       |
                                       v
                              ┌─────────────────┐
                              │  CloudFront CDN │
                              │   (Frontend)    │
                              └────────┬────────┘
                                       |
                    ┌──────────────────┴──────────────────┐
                    |                                     |
            ┌───────▼─────────┐              ┌──────────▼──────────┐
            │  S3 Bucket      │              │ Application Load    │
            │  (Static Site)  │              │   Balancer (ALB)    │
            └─────────────────┘              └──────────┬──────────┘
                                                        |
                            ┌───────────────────────────┼───────────────────────────┐
                            |                           |                           |
                    ┌───────▼─────────┐         ┌──────▼────────┐         ┌───────▼─────────┐
                    │  EC2 Instance   │         │ EC2 Instance  │         │  EC2 Instance   │
                    │  (Backend ASG)  │         │ (Backend ASG) │         │   (MongoDB)     │
                    │  AZ-1           │         │  AZ-2         │         │   Private       │
                    └────────┬────────┘         └───────┬───────┘         └────────┬────────┘
                             |                          |                          |
                             └──────────────┬───────────┘                          |
                                            |                                      |
                                    ┌───────▼────────┐                            |
                                    │  ElastiCache   │◄───────────────────────────┘
                                    │  Redis Cluster │
                                    │  (Caching)     │
                                    └────────────────┘
```

## Network Architecture

### VPC Configuration
- **CIDR Block**: 10.0.0.0/16
- **Region**: eu-north-1 (Stockholm)
- **Availability Zones**: 2 (High Availability)

### Subnet Design

#### Public Subnets (2)
- **CIDR**: 10.0.1.0/24, 10.0.2.0/24
- **Purpose**: Application Load Balancer
- **Route**: Internet Gateway
- **Resources**: ALB

#### Private App Subnets (2)
- **CIDR**: 10.0.11.0/24, 10.0.12.0/24
- **Purpose**: Backend EC2 instances
- **Route**: NAT Gateway
- **Resources**: Auto Scaling Group (EC2)

#### Private Data Subnets (2)
- **CIDR**: 10.0.21.0/24, 10.0.22.0/24
- **Purpose**: Database and cache layers
- **Route**: NAT Gateway (for updates)
- **Resources**: MongoDB EC2, ElastiCache Redis

### Network Components

#### Internet Gateway
- Enables public internet access for ALB
- Attached to VPC

#### NAT Gateways (2)
- **Location**: One per AZ in public subnets
- **Purpose**: Outbound internet for private instances
- **Elastic IPs**: 2 static IPs

#### Route Tables
- **Public Route Table**: Routes 0.0.0.0/0 → IGW
- **Private App Route Table**: Routes 0.0.0.0/0 → NAT
- **Private Data Route Table**: Routes 0.0.0.0/0 → NAT

## 🔒 Security Architecture

### Security Groups

#### ALB Security Group
```
Inbound:
- Port 80 (HTTP): 0.0.0.0/0
- Port 443 (HTTPS): 0.0.0.0/0

Outbound:
- All traffic to Backend SG
```

#### Backend Security Group
```
Inbound:
- Port 8080: ALB Security Group only
- Port 22 (SSH): VPC CIDR (for SSM)

Outbound:
- Port 6379: Redis Security Group
- Port 27017: MongoDB Security Group
- Port 443: 0.0.0.0/0 (AWS APIs, ECR)
```

#### Redis Security Group
```
Inbound:
- Port 6379: Backend Security Group only

Outbound:
- None required
```

#### MongoDB Security Group
```
Inbound:
- Port 27017: Backend Security Group only
- Port 22 (SSH): VPC CIDR

Outbound:
- Port 443: 0.0.0.0/0 (updates)
```

### IAM Roles & Policies

#### Backend EC2 Role
**Policies:**
1. **CloudWatch Logs**: Write application logs
2. **CloudWatch Agent**: Publish metrics
3. **ECR Access**: Pull Docker images
4. **SSM Access**: Session Manager for secure shell access

## Compute Layer

### Application Load Balancer
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Listeners**: 
  - HTTP:80 → Backend Target Group
  - HTTPS:443 → Backend Target Group (requires ACM certificate)
- **Health Check**: GET /health every 30s

### Auto Scaling Group (Backend)
- **Min Size**: 2 instances
- **Desired Capacity**: 2 instances
- **Max Size**: 4 instances
- **Instance Type**: t3.micro
- **AMI**: Amazon Linux 2023
- **Launch Template**: User data script for Docker setup
- **Scaling Policies**: CPU-based (CloudWatch alarms)

### MongoDB Instance
- **Type**: Standalone EC2 instance
- **Instance Type**: t3.small
- **AMI**: Amazon Linux 2023
- **Storage**: EBS volume
- **Setup**: Automated via user-data script
- **Backup**: Managed separately

## Storage & Content Delivery

### S3 Bucket (Frontend)
- **Name**: starttech-frontend-prod-yann-biko
- **Purpose**: React/Vue.js static files
- **Configuration**:
  - Static website hosting enabled
  - Public access blocked
  - Access via CloudFront only (OAI)
- **Index Document**: index.html
- **Error Document**: index.html (SPA routing)

### CloudFront Distribution
- **Origin**: S3 bucket
- **Origin Access Identity**: Restricts S3 access to CloudFront
- **Cache Behavior**: 
  - Compress objects
  - Redirect HTTP → HTTPS
  - Cache policy: Managed-CachingOptimized
- **SSL Certificate**: CloudFront default (*.cloudfront.net)

### ElastiCache Redis
- **Engine**: Redis 7
- **Node Type**: cache.t3.micro
- **Nodes**: 1 (single node)
- **Parameter Group**: default.redis7
- **Use Cases**:
  - Session storage
  - API response caching
  - Rate limiting

### ECR Repository
- **Name**: starttech-backend
- **Image Scanning**: Enabled on push
- **Lifecycle Policy**:
  - Keep last 10 tagged images
  - Remove untagged after 7 days

## Monitoring & Logging

### CloudWatch Logs
- **Backend Log Group**: /starttech/prod/backend (30 days retention)
- **ALB Log Group**: /starttech/prod/alb (30 days retention)

### CloudWatch Metrics & Alarms

#### Backend High CPU Alarm
- **Metric**: CPUUtilization (EC2)
- **Threshold**: > 80%
- **Evaluation**: 2 periods of 5 minutes
- **Action**: SNS notification

#### ALB 5xx Errors Alarm
- **Metric**: HTTPCode_Target_5XX_Count
- **Threshold**: > 5 errors
- **Evaluation**: 1 period of 5 minutes
- **Action**: SNS notification

### CloudWatch Dashboard
- **Widgets**:
  - Backend CPU utilization graph
  - ALB 5xx error count
  - Custom metrics from application

### SNS Topic
- **Name**: starttech-prod-alarms
- **Purpose**: Email notifications for alarms
- **Subscribers**: Operations team

## Data Flow

### Frontend Request Flow
1. User requests `https://xxxxxx.cloudfront.net`
2. CloudFront checks cache
3. If miss, fetches from S3 bucket
4. Returns static assets (HTML, CSS, JS)

### API Request Flow
1. Browser sends API request to ALB DNS
2. ALB performs health check and routes to healthy instance
3. EC2 instance receives request
4. Application checks Redis cache
5. If cache miss, queries MongoDB
6. Response sent back through ALB
7. CloudWatch logs request metrics

### Deployment Flow
1. Developer builds Docker image
2. Push image to ECR repository
3. Update EC2 instances via:
   - Manual: SSH/SSM + docker pull
   - Automated: New Launch Template + ASG instance refresh

## Security Best Practices

### Network Security
- EC2 instances in private subnets
- No direct internet access to databases
- Security groups with least privilege
- NACLs default allow (SG-based control)

### Access Control
- IAM roles with minimal permissions
- No hardcoded credentials
- SSM Session Manager (no SSH keys)
- S3 bucket public access blocked

### Data Security
- HTTPS enforcement (CloudFront)
- Encryption in transit (TLS)
- ECR image scanning
- CloudWatch log encryption

### Compliance
- All resources tagged (Environment, Project)
- Centralized logging
- Automated monitoring
- Infrastructure as Code (Terraform)

## Scalability & High Availability

### High Availability
- Multi-AZ deployment (2 zones)
- Redundant NAT Gateways
- Auto Scaling Group for backend
- ALB health checks

### Scalability
- **Horizontal**: ASG scales 2→4 instances based on CPU
- **Vertical**: Instance types can be upgraded
- **Caching**: Redis reduces database load
- **CDN**: CloudFront reduces origin requests

### Limitations
- MongoDB single instance (no replica set)
- Redis single node (no cluster mode)
- ElastiCache not multi-AZ

### Recommended Improvements
1. MongoDB: Migrate to DocumentDB or MongoDB Atlas
2. Redis: Enable cluster mode or replica
3. Add RDS for relational data
4. Implement auto-scaling policies
5. Add Route53 for custom domain
6. Add WAF for security
7. Implement blue-green deployments

## Cost Optimization

### Current Estimated Monthly Costs (eu-north-1)
- **EC2 Instances**: ~$30 (3 × t3.micro/small)
- **ALB**: ~$20
- **NAT Gateways**: ~$60 (2 × $30)
- **ElastiCache**: ~$15
- **S3**: ~$1
- **CloudFront**: ~$5
- **Data Transfer**: ~$10
- **Total**: ~$141/month

### Optimization Strategies
- Use Reserved Instances for predictable workloads
- Single NAT Gateway for non-production
- S3 Intelligent-Tiering
- CloudFront caching optimization
- Rightsizing instances based on metrics

## Disaster Recovery

### Backup Strategy
- **MongoDB**: Snapshot via EBS or mongodump
- **Terraform State**: S3 versioning enabled
- **Application Code**: Git repository
- **Docker Images**: ECR with lifecycle policy

### Recovery Time Objectives (RTO/RPO)
- **RTO**: < 1 hour (re-deploy with Terraform)
- **RPO**: Depends on MongoDB backup frequency

### Disaster Scenarios
1. **AZ Failure**: ASG launches new instances in healthy AZ
2. **Region Failure**: Manual deployment to new region
3. **Data Loss**: Restore from MongoDB backup

## Technology Stack

### Infrastructure
- **IaC**: Terraform
- **Cloud Provider**: AWS
- **Container Registry**: ECR

### Application
- **Frontend**: React/Vue.js (Static S3 + CloudFront)
- **Backend**: Node.js/Python (Docker on EC2)
- **Database**: MongoDB
- **Cache**: Redis
- **Load Balancer**: ALB

### Monitoring
- **Logs**: CloudWatch Logs
- **Metrics**: CloudWatch Metrics
- **Alerts**: CloudWatch Alarms + SNS

---

**Version**: 1.0  
**Last Updated**: January 28, 2026  
**Author**: Yann BIKO (ALT-SOE-025-0987)
