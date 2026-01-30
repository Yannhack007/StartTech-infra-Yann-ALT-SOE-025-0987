#!/bin/bash
set -e

echo "========================================="
echo "MongoDB Setup on Amazon Linux 2"
echo "========================================="

yum update -y

cat > /etc/yum.repos.d/mongodb-org-6.0.repo << 'EOF'
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

yum install -y mongodb-org

systemctl start mongod
systemctl enable mongod

cat > /etc/mongod.conf << 'EOF'
net:
  port: 27017
  bindIp: 0.0.0.0

security:
  authorization: enabled

storage:
  dbPath: /var/lib/mongo
  engine: wiredTiger

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

processManagement:
  fork: true
EOF

systemctl restart mongod

sleep 5

mongo << 'MONGO'
use admin
db.createUser({
  user: "starttech",
  pwd: "root!",
  roles: [
    { role: "readWrite", db: "much_todo_db" }
  ]
})

use much_todo_db
db.createCollection("init")
MONGO

PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo "========================================="
echo "MongoDB READY"
echo "URI:"
echo "mongodb://starttech:StrongPassword2026!@$PRIVATE_IP:27017/much_todo_db?authSource=admin"
echo "========================================="
