data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "dr" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "DR"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dr.id
  tags = {
    Name = "DR IGW"
  }
}

# public subnets
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)
  cidr_block = cidrsubnet(aws_vpc.dr.cidr_block, 8, count.index + 0)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.dr.id
  tags = {
    name = "Public Subnet ${count.index + 1}"
  }
}

# application subnets
resource "aws_subnet" "app" {
  count = length(data.aws_availability_zones.available.names)
  cidr_block = cidrsubnet(aws_vpc.dr.cidr_block, 8, count.index + 100)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id = aws_vpc.dr.id
  tags = {
    name = "App Subnet ${count.index + 1}"
  }
}

# database subnets
resource "aws_subnet" "db" {
  count = length(data.aws_availability_zones.available.names)
  cidr_block = cidrsubnet(aws_vpc.dr.cidr_block, 8, count.index + 200)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id = aws_vpc.dr.id
  tags = {
    name = "DB Subnet ${count.index + 1}"
  }
}

resource "aws_default_route_table" "private" {
  default_route_table_id = aws_vpc.dr.default_route_table_id

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dr.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }


  tags = {
    Name = "public"
  }

}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public.*.id)
  route_table_id = aws_route_table.public.id
  subnet_id = aws_subnet.public.*.id[count.index]
}


# database subnet group
resource "aws_db_subnet_group" "db" {
  subnet_ids = aws_subnet.db.*.id
  name = "db-group"
  description = "Database subnet group"
}

# cache subnet group
resource "aws_elasticache_subnet_group" "cache" {
  name = "cache-group"
  subnet_ids = aws_subnet.db.*.id
  description = "Cache subnet group"
}
