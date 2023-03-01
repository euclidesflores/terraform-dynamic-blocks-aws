terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.20"
    }

  }
  required_version = "~>1.3.0"
}

provider "aws" {
  region = "us-east-2"
}

resource "random_pet" "prefix" {}

variable "private_subnet_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24",
    "10.0.7.0/24",
    "10.0.8.0/24"
  ]
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24",
    "10.0.105.0/24",
    "10.0.106.0/24",
    "10.0.107.0/24",
    "10.0.108.0/24"
  ]
}

locals {
  vpc-name = "${random_pet.prefix.id}-vpc"
  rules    = jsondecode(file("data.json")).IngressRules
}

data "aws_availability_zones" "availables" {
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name = local.vpc-name
  cidr = "10.0.0.0/16"

  private_subnets = slice(var.private_subnet_cidr_blocks, 0, length(data.aws_availability_zones.availables.names))
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, length(data.aws_availability_zones.availables.names))
  azs             = data.aws_availability_zones.availables.names


  enable_nat_gateway = true
  enable_vpn_gateway = true
  tags = {
    Environment = "dev"
  }
}

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

output "current_workspace_name" {
  value = terraform.workspace
}

output "list_ingress_rules" {
  value = [for o in aws_security_group.allow_some_ports.ingress : o]
}