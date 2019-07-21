terraform {
  required_version = "~> 0.12.3"

  backend "s3" {
    bucket = "tf-state"
    key = "lab798-dr-prod/terraform.tfstate"
    dynamodb_table = "tf-state"
    region = "cn-northwest-1"
    profile = "zhy"
  }
}
