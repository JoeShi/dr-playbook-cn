resource "aws_security_group" "bastion" {
  vpc_id = aws_vpc.dr.id
  name = "Bastion_SG"

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

}

resource "aws_security_group" "lb" {
  vpc_id = aws_vpc.dr.id
  name = "LB_SG"

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "LB SG"
  }
}

resource "aws_security_group" "app" {
  vpc_id = aws_vpc.dr.id
  name = "APP_SG"

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    security_groups = [aws_security_group.lb.id]
    description = "Allow From Load Balancer"
  }

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    security_groups = [aws_security_group.bastion.id]
  }

  # Allow internal communication between Apps
  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    self = true
    description = "Allow from Self"
  }

  tags = {
    Name = "App SG"
  }

}

resource "aws_security_group" "db" {
  vpc_id = aws_vpc.dr.id
  name = "DB_SG"

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3306
    protocol = "tcp"
    to_port = 3306
    security_groups = [aws_security_group.app.id]
    description = "MySQL"
  }

  ingress {
    from_port = 6379
    protocol = "tcp"
    to_port = 6379
    security_groups = [aws_security_group.app.id]
    description = "Redis"
  }

  tags = {
    Name = "DB SG"
  }

}

