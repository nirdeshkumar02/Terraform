
# Getting Output for the aws public ip
output "ec2_public_ip" {
  value = module.myapp-server.instance.public_ip
}