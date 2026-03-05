terraform {
  backend "s3" {
    bucket         = "cloudthrieesecurity-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}