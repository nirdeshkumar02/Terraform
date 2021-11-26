# Project - 1 => Automate AWS Insfrastructure - 

# Title - Run an EC2 Instance and deploy a nginx docker container on it through Terraform.

# Steps =>    1. Create custom vpc
#             2. Create custom subnet
#             3. Create Route Table & Internet Gateway
#             4. Provision Ec2 Instance
#             5. Deploy nginx docker container 
#             6. Create Security Group (Firewall)

# ----------------------------------------------------------- #

# Note - You can put Variables, Providers, Outputs 
# in other file, for example : I've copy some data 
# from main.tf to related .tf file. 

# You can refer it from main.tf file or also from them. 




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
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

# Now, Apply the above infrastructure.

# Create Internet Gateway
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name: "${var.env_prefix}-igw"
  }
}

# If you want to use default route table which is created 
# by your custom vpc, Check This -
resource "aws_default_route_table" "myapp-default-route-table" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-default-rtb"
  }
}

/* 
# Or, if you want to Create a New Route Table for your custom vpc, Then
# you also need to associate subnet to that route table. Check This -
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-rtb"
  }
}

# Associating subnet with Created Route Table
resource "aws_route_table_association" "myapp-rtb-association" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}
*/

# Now, Apply the above infrastructure

# Configure Firewall by using default Security Group assign to custom vpc
resource "aws_default_security_group" "myapp-default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name: "${var.env_prefix}-default-sg"
  }
}

/*
# Configure Firewall by creating new Security Group which assign to custom vpc
resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name: "${var.env_prefix}-sg"
  }
}
*/

# Fetching latest ec2-instance ami through data 
data "aws_ami" "myapp-server-ami" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

# Creating Key Pair for ec2-instance
resource "aws_key_pair" "myapp-server-key" {
  key_name = "myapp-server-key"
  public_key = file(var.public_key_location)
}

# Creating EC2 Instance
resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.myapp-server-ami.id
  instance_type = var.instance_type
  # these are optional (you choose default). If you wanna overwrite
  # use as like below
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.myapp-default-sg.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.myapp-server-key.key_name

  # user_data = file("entry-script.sh")

  # Also, We can execute shell command using 'Provisioners', but before that
  # we have to connect to remote server using 'connection' 

  # Note -> Provisioners aren't recommeded by Terraform

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
  }

  provisioner "file" {
    source = "entry-script.sh"
    destination = "/home/ec2-user/entry-script-ec2.sh"
  }

  provisioner "remote-exec" {
    # to execute script file, first provide this script 
    # in remote server, for that use another provisioner "file"
    script = file("entry-script.sh")
    # Also, If you don't have script file, you can 
    # use inline to execute script command in remote server 
    inline = [
      "export ENV=dev",
      "mkdir newdir"
    ]
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > output.txt"
  }

  tags = {
    Name: "${var.env_prefix}-server"
  }
}













