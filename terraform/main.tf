module "networking" {
  source = "./modules/networking"
  project_name              = "starttech"
  vpc_cidr                  = "10.0.0.0/16"
  public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
  private_data_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
}

module "compute" {
  source             = "./modules/compute"
  project_name       = "starttech"
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_app_subnet_ids
  backend_sg_id      = module.networking.backend_sg_id
  alb_sg_id          = module.networking.alb_sg_id
  instance_type      = "t3.micro"
  ami_id             = "ami-0abcdef1234567890" # remplacer par AMI Linux 2 ou Go backend prébuild
}

module "storage" {
  source              = "./modules/storage"
  project_name        = "starttech"
  environment         = "prod"
  frontend_bucket_name = "starttech-frontend-prod"
}

module "caching" {
  source            = "./modules/storage/caching"
  project_name      = "starttech"
  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.private_data_subnet_ids
  security_group_id = module.networking.redis_sg_id
}

module "monitoring" {
  source         = "./modules/monitoring"
  project_name   = "starttech"
  environment    = "prod"
  backend_asg_id = module.compute.asg_id
  alb_arn        = module.compute.alb_arn
  log_retention_days = 30
}

