# StartTech - Operations Runbook

## Purpose

This runbook provides operational procedures for deploying, monitoring, troubleshooting, and maintaining the StartTech infrastructure on AWS.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Deployment](#initial-deployment)
3. [Daily Operations](#daily-operations)
4. [Monitoring and Alerts](#monitoring-and-alerts)
5. [Troubleshooting](#troubleshooting)
6. [Maintenance](#maintenance)
7. [Emergency Procedures](#emergency-procedures)

---

## Prerequisites

### Required Tools
```bash
# AWS CLI
aws --version  # >= 2.x

# Terraform
terraform version  # >= 1.0

# Docker (pour build images)
docker --version

# jq (pour parsing JSON)
jq --version
```

### Permissions IAM Requises
- `ec2:*` (VPC, EC2, ALB, ASG)
- `s3:*` (S3 buckets)
- `ecr:*` (Container registry)
- `elasticache:*` (Redis)
- `cloudwatch:*` (Logs, metrics, alarms)
- `iam:*` (Roles, policies)
- `cloudfront:*` (CDN)

### Configuration AWS CLI
```bash
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: eu-north-1
# Default output format: json
```

---

## 🚀 Déploiement Initial

### 1. Cloner le Repository
```bash
git clone <repository-url>
cd starttech-infra
```

### 2. Configurer le Backend Terraform
```bash
cd scripts
./bootstrap-backend.sh
# Crée: S3 bucket pour state + DynamoDB table pour locks
```

### 3. Configurer les Variables
```bash
cd ../terraform
cp terraform.tfvars.example terraform.tfvars

# Éditer les valeurs
nano terraform.tfvars
```

**Variables à personnaliser:**
```hcl
aws_region                   = "eu-north-1"
project_name                 = "starttech"
environment                  = "prod"
frontend_bucket_name         = "starttech-frontend-prod-<unique-suffix>"
backend_instance_type        = "t3.micro"
backend_asg_min_size         = 2
backend_asg_max_size         = 4
backend_asg_desired_capacity = 2
```

### 4. Initialiser Terraform
```bash
terraform init
```

### 5. Planifier le Déploiement
```bash
terraform plan -out=tfplan
# Vérifier les 46 ressources à créer
```

### 6. Appliquer l'Infrastructure
```bash
terraform apply tfplan
# Durée estimée: 10-15 minutes
```

### 7. Récupérer les Outputs
```bash
terraform output
# Note: ALB DNS, CloudFront domain, ECR URL, etc.
```

---

## 📅 Opérations Quotidiennes

### Vérifier l'État de l'Infrastructure

#### Vérifier les Instances EC2
```bash
aws ec2 describe-instances \
  --region eu-north-1 \
  --filters "Name=tag:Name,Values=starttech-backend*" \
  --query "Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]" \
  --output table
```

#### Vérifier l'Auto Scaling Group
```bash
aws autoscaling describe-auto-scaling-groups \
  --region eu-north-1 \
  --auto-scaling-group-names starttech-backend \
  --query "AutoScalingGroups[].[AutoScalingGroupName,DesiredCapacity,MinSize,MaxSize]" \
  --output table
```

#### Vérifier le Load Balancer
```bash
aws elbv2 describe-target-health \
  --region eu-north-1 \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --region eu-north-1 \
    --names starttech-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)
```

#### Vérifier Redis
```bash
aws elasticache describe-cache-clusters \
  --region eu-north-1 \
  --cache-cluster-id starttech-redis \
  --show-cache-node-info
```

### Déployer une Nouvelle Version Backend

#### 1. Build Docker Image
```bash
cd backend-app
docker build -t starttech-backend:v1.2.3 .
```

#### 2. Tag et Push vers ECR
```bash
# Login ECR
aws ecr get-login-password --region eu-north-1 | \
  docker login --username AWS --password-stdin \
  631059079661.dkr.ecr.eu-north-1.amazonaws.com

# Tag image
docker tag starttech-backend:v1.2.3 \
  631059079661.dkr.ecr.eu-north-1.amazonaws.com/starttech-backend:v1.2.3

docker tag starttech-backend:v1.2.3 \
  631059079661.dkr.ecr.eu-north-1.amazonaws.com/starttech-backend:latest

# Push
docker push 631059079661.dkr.ecr.eu-north-1.amazonaws.com/starttech-backend:v1.2.3
docker push 631059079661.dkr.ecr.eu-north-1.amazonaws.com/starttech-backend:latest
```

#### 3. Mettre à Jour les Instances
```bash
# Option A: Rolling update via SSM
aws ssm send-command \
  --region eu-north-1 \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Name,Values=starttech-backend-instance" \
  --parameters 'commands=["docker pull 631059079661.dkr.ecr.eu-north-1.amazonaws.com/starttech-backend:latest","docker stop backend || true","docker run -d --name backend -p 8080:8080 631059079661.dkr.ecr.eu-north-1.amazonaws.com/starttech-backend:latest"]'

# Option B: Instance refresh (zero-downtime)
aws autoscaling start-instance-refresh \
  --region eu-north-1 \
  --auto-scaling-group-name starttech-backend
```

### Déployer Frontend (S3 + CloudFront)

#### 1. Build Frontend
```bash
cd frontend-app
npm run build
# Output: dist/ ou build/
```

#### 2. Sync vers S3
```bash
aws s3 sync ./dist/ s3://starttech-frontend-prod-yann-biko/ \
  --delete \
  --cache-control "max-age=31536000" \
  --exclude "index.html"

# index.html avec cache court
aws s3 cp ./dist/index.html s3://starttech-frontend-prod-yann-biko/ \
  --cache-control "max-age=300"
```

#### 3. Invalider le Cache CloudFront
```bash
DISTRIBUTION_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Origins.Items[0].DomainName=='starttech-frontend-prod-yann-biko.s3.eu-north-1.amazonaws.com'].Id" \
  --output text)

aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"
```

---

## 📊 Surveillance et Alertes

### CloudWatch Dashboards

#### Accéder au Dashboard
```bash
# URL console
echo "https://eu-north-1.console.aws.amazon.com/cloudwatch/home?region=eu-north-1#dashboards:name=starttech-prod-dashboard"
```

#### Métriques Clés à Surveiller
1. **Backend CPU**: Moyenne < 60%, Max < 80%
2. **ALB 5xx Errors**: < 5 par période de 5 min
3. **ALB Response Time**: < 500ms p95
4. **Target Health**: 100% healthy
5. **Redis Memory**: < 80% utilisé

### CloudWatch Logs

#### Consulter les Logs Backend
```bash
aws logs tail /starttech/prod/backend \
  --region eu-north-1 \
  --follow
```

#### Rechercher des Erreurs
```bash
aws logs filter-log-events \
  --region eu-north-1 \
  --log-group-name /starttech/prod/backend \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000
```

#### Logs Insights Queries
```bash
# Top 10 erreurs
aws logs start-query \
  --region eu-north-1 \
  --log-group-name /starttech/prod/backend \
  --start-time $(date -d '24 hours ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | stats count() by @message | sort count desc | limit 10'
```

### Alertes SNS

#### S'Abonner aux Alertes
```bash
aws sns subscribe \
  --region eu-north-1 \
  --topic-arn arn:aws:sns:eu-north-1:631059079661:starttech-prod-alarms \
  --protocol email \
  --notification-endpoint your-email@example.com

# Confirmer via email
```

---

## 🔍 Dépannage

### Problème: Instances Backend Unhealthy

#### Diagnostic
```bash
# Vérifier target health
aws elbv2 describe-target-health \
  --region eu-north-1 \
  --target-group-arn <TG_ARN>

# Vérifier logs
aws logs tail /starttech/prod/backend --region eu-north-1 --since 30m
```

#### Solutions
1. **Health check échoue**:
   ```bash
   # SSH via SSM
   aws ssm start-session --target <instance-id>
   
   # Tester health endpoint
   curl http://localhost:8080/health
   
   # Vérifier Docker
   docker ps
   docker logs <container-id>
   ```

2. **Redémarrer l'instance**:
   ```bash
   aws ec2 reboot-instances --instance-ids <instance-id>
   ```

3. **Remplacer l'instance**:
   ```bash
   aws autoscaling terminate-instance-in-auto-scaling-group \
     --instance-id <instance-id> \
     --should-decrement-desired-capacity false
   ```

### Problème: High CPU sur Backend

#### Diagnostic
```bash
# Métriques CloudWatch
aws cloudwatch get-metric-statistics \
  --region eu-north-1 \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=starttech-backend \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

#### Solutions
1. **Scaler temporairement**:
   ```bash
   aws autoscaling set-desired-capacity \
     --auto-scaling-group-name starttech-backend \
     --desired-capacity 4
   ```

2. **Analyser les logs**:
   ```bash
   aws logs tail /starttech/prod/backend --follow
   ```

3. **Upgrade instance type** (si persistant):
   ```bash
   # Modifier variables.tf
   backend_instance_type = "t3.small"
   
   # Appliquer
   terraform apply
   ```

### Problème: Erreurs 5xx du ALB

#### Diagnostic
```bash
# Logs ALB
aws logs tail /starttech/prod/alb --region eu-north-1 --since 10m

# Métriques
aws cloudwatch get-metric-statistics \
  --region eu-north-1 \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=<ALB_ARN_SUFFIX> \
  --start-time $(date -u -d '15 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

#### Solutions
1. Vérifier les logs backend
2. Vérifier MongoDB/Redis connectivity
3. Rollback vers version précédente si déploiement récent

### Problème: MongoDB Inaccessible

#### Diagnostic
```bash
# Se connecter à l'instance MongoDB
aws ssm start-session --target <mongodb-instance-id>

# Vérifier le service
sudo systemctl status mongod

# Vérifier les logs
sudo tail -f /var/log/mongodb/mongod.log
```

#### Solutions
1. **Redémarrer MongoDB**:
   ```bash
   sudo systemctl restart mongod
   ```

2. **Vérifier l'espace disque**:
   ```bash
   df -h
   ```

3. **Vérifier le Security Group**:
   ```bash
   aws ec2 describe-security-groups \
     --group-ids <mongodb-sg-id>
   ```

### Problème: Redis Connection Timeout

#### Diagnostic
```bash
# Vérifier le cluster
aws elasticache describe-cache-clusters \
  --cache-cluster-id starttech-redis \
  --show-cache-node-info

# Depuis une instance backend
aws ssm start-session --target <backend-instance-id>
redis-cli -h <redis-endpoint> ping
```

#### Solutions
1. Vérifier Security Group
2. Redémarrer le cluster (downtime!)
3. Vérifier memory usage

### Problème: CloudFront Serving Stale Content

#### Solutions
```bash
# Invalider le cache
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"

# Vérifier invalidation
aws cloudfront get-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --id <INVALIDATION_ID>
```

---

## 🛠️ Maintenance

### Mise à Jour Terraform

#### 1. Backup State
```bash
aws s3 cp s3://starttech-terraform-state/prod/terraform.tfstate \
  ./backup-$(date +%Y%m%d-%H%M%S).tfstate
```

#### 2. Tester les Changements
```bash
terraform plan -out=tfplan
```

#### 3. Appliquer
```bash
terraform apply tfplan
```

### Rotation des Secrets

#### ECR Login Token (auto-renew)
```bash
aws ecr get-login-password --region eu-north-1 | \
  docker login --username AWS --password-stdin \
  631059079661.dkr.ecr.eu-north-1.amazonaws.com
```

#### Renouveler MongoDB Credentials
```bash
# Se connecter à MongoDB
aws ssm start-session --target <mongodb-instance-id>

# Mongo shell
mongosh
use admin
db.updateUser("appuser", {pwd: "NEW_SECURE_PASSWORD"})

# Mettre à jour dans backend app config
```

### Nettoyage des Ressources

#### Supprimer Anciennes Images ECR
```bash
# Liste images
aws ecr list-images \
  --repository-name starttech-backend \
  --region eu-north-1

# Supprimer image spécifique
aws ecr batch-delete-image \
  --repository-name starttech-backend \
  --region eu-north-1 \
  --image-ids imageTag=old-tag
```

#### Nettoyer les Logs CloudWatch
```bash
# Définir retention (déjà configuré à 30 jours)
aws logs put-retention-policy \
  --log-group-name /starttech/prod/backend \
  --retention-in-days 30
```

### Backup MongoDB

#### Manuel
```bash
# SSH vers MongoDB
aws ssm start-session --target <mongodb-instance-id>

# Dump database
mongodump --out /backup/$(date +%Y%m%d)

# Upload vers S3
aws s3 sync /backup/ s3://starttech-backups/mongodb/
```

#### Automatisé (cron)
```bash
# Ajouter crontab sur MongoDB instance
0 2 * * * /usr/local/bin/mongodb-backup.sh
```

---

## 🚨 Procédures d'Urgence

### Incident: Total Outage

#### 1. Évaluation Rapide
```bash
# Vérifier status AWS
curl https://status.aws.amazon.com/

# Vérifier ALB
curl -I http://<ALB_DNS>

# Vérifier toutes les instances
aws ec2 describe-instance-status --region eu-north-1
```

#### 2. Escalade
- Notifier l'équipe ops
- Vérifier dashboard CloudWatch
- Consulter CloudWatch Alarms

#### 3. Recovery
```bash
# Si ASG problématique, forcer new instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name starttech-backend \
  --desired-capacity 0

sleep 30

aws autoscaling set-desired-capacity \
  --auto-scaling-group-name starttech-backend \
  --desired-capacity 2
```

### Rollback Application

#### Backend
```bash
# Revenir à version précédente
docker pull 631059079661.dkr.ecr.eu-north-1.amazonaws.com/starttech-backend:v1.2.2

# Déployer via SSM
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Name,Values=starttech-backend-instance" \
  --parameters 'commands=["docker stop backend","docker run -d --name backend -p 8080:8080 631059079661.dkr.ecr.eu-north-1.amazonaws.com/starttech-backend:v1.2.2"]'
```

#### Frontend
```bash
# Re-upload version précédente
aws s3 sync ./previous-build/ s3://starttech-frontend-prod-yann-biko/ --delete

# Invalidate
aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"
```

### Rollback Infrastructure
```bash
# Revenir à version Terraform précédente
git checkout <previous-commit>
terraform init
terraform apply
```

### Disaster Recovery

#### Scénario: Perte Totale de la Région
1. Modifier `aws_region` dans variables.tf
2. Déployer dans nouvelle région:
   ```bash
   terraform apply -var="aws_region=eu-west-1"
   ```
3. Restaurer MongoDB depuis backup S3
4. Mettre à jour DNS/endpoints

---

## 📞 Contacts & Escalade

### Niveaux d'Escalade
1. **L1**: DevOps Engineer (monitoring, logs)
2. **L2**: Senior DevOps/SRE (infrastructure changes)
3. **L3**: AWS Support (AWS service issues)

### Ressources Utiles
- **AWS Support**: https://console.aws.amazon.com/support
- **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **CloudWatch Dashboard**: [Link from outputs]

---

## 📝 Checklist Maintenance Mensuelle

- [ ] Vérifier CloudWatch metrics trends
- [ ] Analyser CloudWatch Logs Insights
- [ ] Vérifier coûts AWS (Cost Explorer)
- [ ] Tester backup/restore MongoDB
- [ ] Mettre à jour AMIs (security patches)
- [ ] Réviser Security Groups rules
- [ ] Audit IAM permissions
- [ ] Tester procédures disaster recovery
- [ ] Mettre à jour documentation

---

**Version**: 1.0  
**Last Updated**: January 28, 2026  
**Maintained by**: Yann BIKO (ALT-SOE-025-0987)  
**On-call**: [Phone/Email]
