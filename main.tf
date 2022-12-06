terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.45.0"
    }
  }
}

provider "aws" {
  alias  = "london"
  region = "eu-west-2"
}

provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}

# Create network + EC2 instance in the London region
module "london" {
  source     = "./modules/test-network"
  cidr_block = "10.0.0.0/16"
  providers  = { aws = aws.london }
}

# Create network + EC2 instance in the Ireland region
module "ireland" {
  source     = "./modules/test-network"
  cidr_block = "10.1.0.0/16"
  providers  = { aws = aws.ireland }
}

# Peer the London and Ireland networks
module "peering-london-ireland" {
  source = "./modules/test-peering"

  vpc_id      = module.london.vpc_id
  peer_vpc_id = module.ireland.vpc_id

  cidr_block_requester = module.london.cidr_block
  cidr_block_accepter  = module.ireland.cidr_block

  route_table_id_requester = module.london.route_table_id
  route_table_id_accepter  = module.ireland.route_table_id

  providers = {
    aws.accepter  = aws.ireland
    aws.requester = aws.london
  }
}

output "aws_instance_id_london" { value = module.london.aws_instance.id }
output "aws_instance_private_ip_london" { value = module.london.aws_instance.private_ip }
output "aws_instance_id_ireland" { value = module.ireland.aws_instance.id }
output "aws_instance_private_ip_ireland" { value = module.ireland.aws_instance.private_ip }
