resource "aws_eip" "nat" {}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = data.terraform_remote_state.basic.outputs.public_subnet_ids.0
}

resource "aws_route" "nat" {
  route_table_id = data.terraform_remote_state.basic.outputs.private_route_table
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_lb" "main" {
  name = "main"
  internal = false
  load_balancer_type = "application"
  security_groups = [data.terraform_remote_state.basic.outputs.lb_sg_id]
  subnets = data.terraform_remote_state.basic.outputs.public_subnet_ids

  tags = {
    Environment = "DR"
  }
}

# Direct to WP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

}

