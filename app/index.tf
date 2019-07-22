provider "aws" {
  profile = var.profile
  region = var.region
  version = "~> 2.20.0"
}

data "terraform_remote_state" "basic" {
  backend = "s3"
  workspace = terraform.workspace
  config = {
    bucket = "tf-state"
    key = "lab798-dr-basic/terraform.tfstate"
    region = "cn-northwest-1"
    profile = "zhy"
  }
}

output "alb_cname" {
  value = aws_lb.main.dns_name
}
