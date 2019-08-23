# 必须改！AWS Profile
variable "profile" {
  default = "zhy"
}

variable "region" {
  default = "cn-north-1"
}

# 必须改！WordPress Media 文件 S3 Bucket
variable "app_s3" {
  default = "dr-wp-bjs"
}

# 必须改！
variable "db_endpoint" {
  default = "dr-demo.c7gghk4aijib.rds.cn-north-1.amazonaws.com.cn"
}

# 必须改! EC2 SSH Key name, 请登陆 AWS 控制台查看或者创建
variable "ec2_key_name" {
  default = "aws"
}

# 数据库用户名
variable "db_username" {
  default = "root"
}

# 数据库密码
variable "db_password" {
  default = "rootroot"
}

variable "app_max_capacity" {
  default = 20
}

variable "app_desired_capacity" {
  default = 2
}

# WordPress AMI
variable "app_ami" {
  type = "map"

  default = {
    cn-north-1 = "ami-0eebef1aaa174c852"
    cn-northwest-1 = "ami-0cbbf10eaeaf0f9c3"
  }
}



