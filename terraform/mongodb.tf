# MongoDB EC2 Instance (Option 1: Self-hosted)
# Note: For production, consider using MongoDB Atlas instead

resource "aws_security_group" "mongodb" {
  name_prefix = "${var.project_name}-mongodb-sg-"
  description = "Security group for MongoDB"
  vpc_id      = module.networking.vpc_id

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [module.networking.backend_sg_id]
    description     = "MongoDB from backend"
  }

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [module.networking.backend_sg_id]
    description     = "MongoDB from backend"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-mongodb-sg"
  }
}

# MongoDB EC2 Instance
resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.small"
  subnet_id              = module.networking.private_data_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.mongodb.id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 100
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(file("${path.root}/../scripts/setup-mongodb.sh"))

  tags = {
    Name = "${var.project_name}-mongodb"
  }

  monitoring = true
}

# MongoDB Private IP as output
output "mongodb_endpoint" {
  description = "MongoDB instance private IP"
  value       = aws_instance.mongodb.private_ip
}
