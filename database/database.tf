
resource "aws_db_parameter_group" "mysql56" {
  family = "mysql5.6"
  name_prefix = "dr-demo-db"
}

resource "aws_db_instance" "mysql56" {
  identifier = "dr-demo"
  name = "demo"
  instance_class = "db.r4.large"
  allocated_storage = 20
  max_allocated_storage = 1000
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "5.6"
  username = var.db_username
  password = var.db_password
  db_subnet_group_name = data.terraform_remote_state.basic.outputs.db_subnet_group_id
  vpc_security_group_ids = [data.terraform_remote_state.basic.outputs.db_sg_id]
  multi_az = false
  publicly_accessible = false
  deletion_protection = false
  apply_immediately = true
  skip_final_snapshot = true
  backup_retention_period = 2
  parameter_group_name = aws_db_parameter_group.mysql56.name
}


output "db_endpoint" {
  value = split(":", aws_db_instance.mysql56.endpoint)[0]
}




