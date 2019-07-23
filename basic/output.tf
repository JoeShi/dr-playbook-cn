output "vpc" {
  value = aws_vpc.dr.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "app_subnet_ids" {
  value = aws_subnet.app.*.id
}

output "db_subnet_ids" {
  value = aws_subnet.db.*.id
}

output "lb_sg_id" {
  value = aws_security_group.lb.id
}

output "app_sg_id" {
  value = aws_security_group.app.id
}

output "db_sg_id" {
  value = aws_security_group.db.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "db_subnet_group_id" {
  value = aws_db_subnet_group.db.id
}

output "cache_subnet_group_id" {
  value = aws_elasticache_subnet_group.cache.id
}

output "private_route_table" {
  value = aws_default_route_table.private.id
}