variable "profile" {
  default = "zhy"
}

variable "region" {
  default = "cn-north-1"
}

variable "db_username" {
  default = "root"
}

variable "db_password" {
  default = "rootroot"
}

variable "ec2_key_name" {
  default = "aws"
}

variable "app_max_capacity" {
  default = 20
}

variable "app_desired_capacity" {
  default = 1
}

variable "app_domain" {
  default = "wp.joeshi.net"
}

# wordpress_ami
variable "app_ami" {
  type = "map"

  default = {
    cn-north-1 = "ami-0eebef1aaa174c852"
    cn-northwest-1 = "ami-0cbbf10eaeaf0f9c3"
  }
}

variable "app_s3" {
  default = "dr-wp-bjs"
}

variable "db_endpoint" {
  default = "dr-demo-prod.c7gghk4aijib.rds.cn-north-1.amazonaws.com.cn"
}