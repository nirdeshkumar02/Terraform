# In this file, I write the code with modules, but code is same
# as in main.tf. If you want to perform all code at a place
# refer to main.tf or if you want to perform in modules refer
# to moduled_main.tf. all code will be same.
# with this file, modules folder will be included.  

# Declare the provider which I used.
provider "aws" {
  region = "ap-south-1"
}


/*
Declaring Resources which we need and use variable (don't use hardcode value)
When we create a vpc - route table, nacl, security group, are automatic
created so, you have option you can go through this default or create new one
and assign to vpc which you created. 
*/

# Creating Custom VPC
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

# Creating Custom Subnet
module "myapp-subnet" {
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}

# Creating Instance
module "myapp-server" {
  source = "./modules/webserver"
  vpc_id = aws_vpc.myapp-vpc.id
  env_prefix = var.env_prefix
  image_name = var.image_name
  public_key_location = var.public_key_location
  instance_type = var.instance_type
  subnet_id = module.myapp-subnet.subnet.id
  avail_zone = var.avail_zone
}

