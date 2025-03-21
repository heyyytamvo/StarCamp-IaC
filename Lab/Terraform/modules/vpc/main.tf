resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    "Name" = var.vpc_name
  }
}

resource "aws_subnet" "private_subnet" {
  for_each          = toset(var.private_subnet)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value
  availability_zone = var.availability_zone[index(var.private_subnet, each.value)]

  tags = {
    Name = "Private Subnet ${index(var.private_subnet, each.value) + 1}"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each                = toset(var.public_subnet)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value
  availability_zone       = var.availability_zone[index(var.public_subnet, each.value)]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet ${index(var.public_subnet, each.value) + 1}"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = var.vpc_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = {
    "Name" = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_subnets_associations" {
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "public" {
  depends_on = [aws_internet_gateway.ig]

  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public_subnet)[0].id

  tags = {
    Name = "NAT Gateway"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public.id
  }

  tags = {
    "Name" = "Private Route Table"
  }
}

## private subnet Association
resource "aws_route_table_association" "private_subnets_associations" {
  for_each       = aws_subnet.private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}