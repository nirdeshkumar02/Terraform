# Here we will learn, How to use 'provider', 'resource', 'data' etc
# by Creating VPC, Subnet, Tagging.

# 1. Ist we need to define the provider, then use "terraform init to apply"
provider "aws" {
  region = "ap-south-1"
}

variable "subnet_cidr_block" {
  description = "subnet cidr block"
  # default = "10.0.10.0/24" # This value will be taken by default, If no value is provided to it.
  type = list(string)
  # type = list(object({
  #   cidr_block = string
  #   name = string
  # }))
}

variable "vpc_cidr_block" {
  description = "vpc cidr block"
}

variable "environment" {
  description = "deployment environment"
}

resource "aws_vpc" "development-vpc" {
  cidr_block = var.vpc_cidr_block
  # cidr_block = var.vpc_cidr_block[0].cidr_block
  tags = {
    Name = var.environment
    # Name = var.cidr_block[0].name
  }
}

# subnet is applied on vpc which we are creating so, we can't assign
# the subnet before creating it. so we can perform this task, whenever
# vpc is created
resource "aws_subnet" "development-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = var.subnet_cidr_block #if list is passed use like var.subnet_cidr_block[0]
  availability_zone = "ap-south-1a"
  tags = {
    Name = "subnet-1-dev",
    vpc_env: "dev" # we want to remove it then you should only remove this line and apply.
  }
}

# Notes - There is two ways to delete any configuration - 
# 1. By Deleting the resource and apply using terraform apply
# 2. By terraform command - "terraform destroy -target aws_subnet.dev-subnet-2"


# 2. use "data" to fetch details from existing resource you create
# we are fetching default vpc id and use that to create another subnet
# inside default vpc.

data "aws_vpc" "existing_vpc" {
  default = true
}

resource "aws_subnet" "dev-subnet-2" {
  vpc_id = data.aws_vpc.existing_vpc.id
  cidr_block = "172.31.48.0/20"
  availability_zone = "ap-south-1a"
}

# We can directly use output which we want to check first
output "dev-vpc-id" {
  value = aws_vpc.development-vpc.id
}

output "dev-subnet-id" {
  value = aws_subnet.development-subnet-1.id
}

