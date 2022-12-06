variable "cidr_block" {}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_region" "default" {}

resource "aws_vpc" "default" {
  cidr_block = var.cidr_block
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
  depends_on             = [aws_route_table.default]
}

resource "aws_route_table_association" "default" {
  subnet_id      = aws_subnet.default.id
  route_table_id = aws_route_table.default.id
}

module "subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.cidr_block
  networks = [
    {
      name     = "default"
      new_bits = 8
    },
  ]
}

resource "aws_subnet" "default" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = module.subnet_addrs.network_cidr_blocks["default"]
  availability_zone = "${data.aws_region.default.name}a"
}

data "aws_ami" "default-al2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

resource "aws_security_group" "default-ssh" {
  name   = "test"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "default" {
  ami                         = data.aws_ami.default-al2.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.default-ssh.id]
  subnet_id                   = aws_subnet.default.id
}

# Outputs required; used to export data for VPC peering purposes
output "vpc_id" {
  value = aws_vpc.default.id
}

output "route_table_id" {
  value = aws_route_table.default.id
}

output "cidr_block" {
  value = aws_vpc.default.cidr_block
}
