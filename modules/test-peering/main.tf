variable "vpc_id" {}
variable "peer_vpc_id" {}
variable "route_table_id_requester" {}
variable "route_table_id_accepter" {}
variable "cidr_block_requester" {}
variable "cidr_block_accepter" {}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.requester, aws.accepter]
    }
  }
}

data "aws_region" "default" { provider = aws.accepter }

resource "aws_vpc_peering_connection" "default" {
  provider    = aws.requester
  vpc_id      = var.vpc_id
  peer_vpc_id = var.peer_vpc_id
  peer_region = data.aws_region.default.name
}

resource "aws_vpc_peering_connection_accepter" "default" {
  provider                  = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id
  auto_accept               = true
}

resource "aws_route" "default-requester" {
  provider                  = aws.requester
  route_table_id            = var.route_table_id_requester
  destination_cidr_block    = var.cidr_block_accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id
  depends_on                = [aws_vpc_peering_connection_accepter.default]
}

resource "aws_route" "default-accepter" {
  provider                  = aws.accepter
  route_table_id            = var.route_table_id_accepter
  destination_cidr_block    = var.cidr_block_requester
  vpc_peering_connection_id = aws_vpc_peering_connection.default.id
  depends_on                = [aws_vpc_peering_connection_accepter.default]
}
