terraform {
  backend "s3" {
    bucket         = "starttech-terraform-state-prod"
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "starttech-terraform-locks"
  }
}
