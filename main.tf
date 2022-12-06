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

provider "aws" {
  alias  = "paris"
  region = "eu-west-3"
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

# Create network + EC2 instance in the Paris region
module "paris" {
  source     = "./modules/test-network"
  cidr_block = "10.2.0.0/16"
  providers  = { aws = aws.paris }
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

# Peer the London and Paris networks
module "peering-london-paris" {
  source = "./modules/test-peering"

  vpc_id      = module.london.vpc_id
  peer_vpc_id = module.paris.vpc_id

  cidr_block_requester = module.london.cidr_block
  cidr_block_accepter  = module.paris.cidr_block

  route_table_id_requester = module.london.route_table_id
  route_table_id_accepter  = module.paris.route_table_id

  providers = {
    aws.accepter  = aws.paris
    aws.requester = aws.london
  }
}

# Peer the Ireland and Paris networks
module "peering-ireland-paris" {
  source = "./modules/test-peering"

  vpc_id      = module.ireland.vpc_id
  peer_vpc_id = module.paris.vpc_id

  cidr_block_requester = module.ireland.cidr_block
  cidr_block_accepter  = module.paris.cidr_block

  route_table_id_requester = module.ireland.route_table_id
  route_table_id_accepter  = module.paris.route_table_id

  providers = {
    aws.accepter  = aws.paris
    aws.requester = aws.ireland
  }
}