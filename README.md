# terraform-aws-vpc-test

In this example, we're using Terraform modules to create basic network configurations and an EC2 instance in three AWS regions + peering them all together.

Tested using:
```
# terraform version
Terraform v1.3.6
```

For the purpose of this test, AWS credentials are injected via `~/.aws/credentials`

---

Creating test resources in a specific region:

```
provider "aws" {
  alias  = "london"
  region = "eu-west-2"
}

module "london" {
  source     = "./modules/test-network"
  cidr_block = {{ENTER CIDR RANGE}} // e.g. "10.0.0.0/16"
  providers  = { aws = aws.london }
}
```

---

Peering two networks together:
```
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
```

---

Useful outputs that provide the EC2 instance ID and private IPs:
```
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

aws_instance_id_ireland = "i-09ddb408286b8ddd9"
aws_instance_id_london = "i-000677f1c6e576b21"
aws_instance_id_paris = "i-05dcc8f6f84ba1dbf"
aws_instance_private_ip_ireland = "10.1.0.16"
aws_instance_private_ip_london = "10.0.0.240"
aws_instance_private_ip_paris = "10.2.0.142"
```


Example connection; runs `ping` from the EC2 instance in the Ireland region to the EC2 instance in the London region
```
# export EC2_ID_IRELAND=$(terraform output --raw aws_instance_id_ireland)
# export EC2_IP_LONDON=$(terraform output --raw aws_instance_private_ip_london)

# mssh -r eu-west-1 $EC2_ID_IRELAND 'ping $EC2_IP_LONDON -c 1 | head -n 2 | tail -1'

64 bytes from 10.0.0.240: icmp_seq=1 ttl=255 time=13.8 ms
```
