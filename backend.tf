terraform {
  backend "s3" {
    bucket         = "storing-state-for-infra"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
