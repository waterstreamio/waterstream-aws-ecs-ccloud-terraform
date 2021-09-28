data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_vpc" "aws-vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
}

#Required for fetching from Dockerhub
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.aws-vpc.id
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.aws-vpc.id
  cidr_block = cidrsubnet(aws_vpc.aws-vpc.cidr_block, 8, 10)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.azs.names[0]
  tags = {
    PublicSubnet = "1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.aws-vpc.id
  cidr_block = cidrsubnet(aws_vpc.aws-vpc.cidr_block, 8, 11)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.azs.names[1]
  tags = {
    PublicSubnet = "2"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id = aws_vpc.aws-vpc.id
  cidr_block = cidrsubnet(aws_vpc.aws-vpc.cidr_block, 8, 12)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.azs.names[2]
  tags = {
    PublicSubnet = "3"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.aws-vpc.id
  cidr_block = cidrsubnet(aws_vpc.aws-vpc.cidr_block, 8, 2)
  availability_zone = data.aws_availability_zones.azs.names[0]
  tags = {
    PrivateSubnet = "1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.aws-vpc.id
  cidr_block = cidrsubnet(aws_vpc.aws-vpc.cidr_block, 8, 3)
  availability_zone = data.aws_availability_zones.azs.names[1]
  tags = {
    PrivateSubnet = "2"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id = aws_vpc.aws-vpc.id
  cidr_block = cidrsubnet(aws_vpc.aws-vpc.cidr_block, 8, 4)
  availability_zone = data.aws_availability_zones.azs.names[2]
  tags = {
    PrivateSubnet = "3"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id = aws_subnet.public_subnet_1.id
}

resource "aws_route_table" "internet_routing_table" {
  vpc_id = aws_vpc.aws-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.internet_routing_table.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.internet_routing_table.id
}

resource "aws_route_table_association" "public_assoc_3" {
  subnet_id = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.internet_routing_table.id
}

resource "aws_route_table" "private_subnet_table" {
  vpc_id = aws_vpc.aws-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_route_1" {
  subnet_id = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_subnet_table.id
}

resource "aws_route_table_association" "private_route_2" {
  subnet_id = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_subnet_table.id
}

resource "aws_route_table_association" "private_route_3" {
  subnet_id = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_subnet_table.id
}
