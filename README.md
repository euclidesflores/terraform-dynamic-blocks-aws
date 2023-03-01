# Understanding Terraform Dynamic blocks with AWS

## A practical example on Terraform Dynamic blocks and AWS.
In Terraform, Dynamic blocks are expressions that are used to construct repeatable nested blocks.

>A dynamic block acts much like a for expression, but produces nested blocks instead of a complex typed value. It iterates over a given complex value, and generates a nested block for each element of that complex value.

In a AWS Securtiy Group we can use dynamic blocks to create a set of inbound and outbound rules, we could have these rules in a separated file and represented in json (or yaml), like in this example:

```
% cat data.json
{
    "IngressRules": [
        {
            "description": "TLS from VPC",
            "from_port": "443",
            "to_port": "443",
            "protocol": "tcp",
            "cidr_blocks": "0.0.0.0/0"
        },
        {
            "description": "Allow to connect through port 22",
            "from_port": "22",
            "to_port": "22",
            "protocol": "tcp",
            "cidr_blocks": "0.0.0.0/0"
        },
        {
            "description": "HTTP access from anywhere",
            "from_port": "80",
            "to_port": "80",
            "protocol": "tcp",
            "cidr_blocks": "0.0.0.0/0"
        }
    ]
}
```

We use the file and jsondecode functions to read the content of the file with the rules and interpret its content as JSON.

```
locals {
  vpc-name = "${random_pet.prefix.id}-vpc"
  rules    = jsondecode(file("data.json")).IngressRules
}
```

* "ingress" is the label of our dynamic block.

```
resource "aws_security_group" "allow_some_ports" {
  name        = "${module.vpc.name}-sg"
  description = "Allow some ports"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = local.rules
    content {
      description = ingress.value["description"]
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = [ingress.value["cidr_blocks"]]
    }
  }

  tags = {
    Environment = "dev"
  }
}
```







