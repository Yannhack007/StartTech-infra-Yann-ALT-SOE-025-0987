#!/bin/bash
set -e

echo "========================================="
echo "MongoDB Setup on Amazon Linux 2"
echo "========================================="

# Update system
yum update -y

# Install MongoDB Community Edition
echo "📦 Installing MongoDB..."
cat > /etc/yum.repos.d/mongodb-org-6.0.repo << 'EOF'
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

yum install -y mongodb-org

# Start MongoDB
systemctl start mongod
systemctl enable mongod

# Allow remote connections from private subnet
echo "🔧 Configuring MongoDB..."
cat > /etc/mongod.conf << 'EOF'
# mongod.conf for StartTech Backend

# network interface
net:
  port: 27017
  bindIp: 0.0.0.0

# storage
storage:
  dbPath: /var/lib/mongo
  engine: wiredTiger

# logging
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# operationProfiling
operationProfiling:
  mode: slowOp
  slowOpThresholdMs: 100

# process management
processManagement:
  fork: true
EOF

# Restart MongoDB with new config
systemctl restart mongod

# Create application user
mongo admin << 'MONGO'
db.createUser({
  user: "starttech",
  pwd: "startech2026",
  roles: [{role: "root", db: "admin"}]
})
MONGO

echo "MongoDB setup complete!"
echo "Connection: mongodb://starttech:startech2026@$(hostname -I | awk '{print $1}'):27017/admin"
