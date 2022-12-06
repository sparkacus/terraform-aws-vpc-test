# terraform-aws-vpc-test

In this example, we're using Terraform modules to create basic network configurations and an EC2 instance in two AWS regions + peering them together.

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

aws_instance_id_ireland = "i-07be1acb1e60c4d8e"
aws_instance_id_london = "i-0df7453e1647f53a4"
aws_instance_private_ip_ireland = "10.1.0.145"
aws_instance_private_ip_london = "10.0.0.64"
```


Example connection; runs `ping` from the EC2 instance in the Ireland region to the EC2 instance in the London region
```
# export EC2_ID_IRELAND=$(terraform output --raw aws_instance_id_ireland)
# export EC2_ID_LONDON=$(terraform output --raw aws_instance_id_london)
# export EC2_IP_IRELAND=$(terraform output --raw aws_instance_private_ip_ireland)
# export EC2_IP_LONDON=$(terraform output --raw aws_instance_private_ip_london)

# mssh -r eu-west-1 $EC2_ID_IRELAND 'ping $EC2_IP_LONDON -c 1 | head -n 2 | tail -1'

64 bytes from 10.0.0.64: icmp_seq=1 ttl=255 time=12.8 ms


# mssh -r eu-west-2 $EC2_ID_LONDON 'ping $EC2_IP_IRELAND -c 1 | head -n 2 | tail -1'

64 bytes from 10.1.0.145: icmp_seq=1 ttl=255 time=11.3 ms
```
