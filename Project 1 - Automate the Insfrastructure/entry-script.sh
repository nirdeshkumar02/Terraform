 #!/bin/bash
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker
sudo su
usermod -aG docker ec2-user
su - ec2-user
docker run -d -p 8080:80 --name nginx-webserver nginx
