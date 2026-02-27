
terraform {
  backend "s3" {
    bucket         = "vcthriee-terraform-states"
    key            = "infra-modules/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}