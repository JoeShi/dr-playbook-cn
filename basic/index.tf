terraform {
  required_version = "~> 0.12.3"

  backend "s3" {
    bucket = "tf-state"                           # 修改成预先创建的 Terraform S3 backend bucket
    key = "lab798-dr-basic/terraform.tfstate"
    dynamodb_table = "tf-state"
    region = "cn-northwest-1"                     # 修改成 backend 所在的 region
    profile = "zhy"                               # 修改成本地的 AWS Profile
  }
}

provider "aws" {
  profile = var.profile
  region = var.region
  version = "~> 2.20.0"
}

