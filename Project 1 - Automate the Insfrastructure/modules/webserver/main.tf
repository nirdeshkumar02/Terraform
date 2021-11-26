# Configure Firewall by using default Security Group assign to custom vpc
resource "aws_default_security_group" "myapp-default-sg" {
  vpc_id = var.vpc_id
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
    values = [var.image_name]
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
  subnet_id = var.subnet_id 
  vpc_security_group_ids = [aws_default_security_group.myapp-default-sg.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.myapp-server-key.key_name

  user_data = file("entry-script.sh")

  # # Also, We can execute shell command using 'Provisioners', but before that
  # # we have to connect to remote server using 'connection' 

  # # Note -> Provisioners aren't recommeded by Terraform

  # connection {
  #   type = "ssh"
  #   host = self.public_ip
  #   user = "ec2-user"
  #   private_key = file(var.private_key_location)
  # }

  # provisioner "file" {
  #   source = "entry-script.sh"
  #   destination = "/home/ec2-user/entry-script-ec2.sh"
  # }

  # provisioner "remote-exec" {
  #   # to execute script file, first provide this script 
  #   # in remote server, for that use another provisioner "file"
  #   script = file("entry-script.sh")
  #   # Also, If you don't have script file, you can 
  #   # use inline to execute script command in remote server 
  #   inline = [
  #     "export ENV=dev",
  #     "mkdir newdir"
  #   ]
  # }

  # provisioner "local-exec" {
  #   command = "echo ${self.public_ip} > output.txt"
  # }

  tags = {
    Name: "${var.env_prefix}-server"
  }
}