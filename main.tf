###############################################################
# PROVIDER
###############################################################
provider "aws" {
  region = var.aws_region
}

###############################################################
# DATA SOURCES (Required for AMI Lookup)
###############################################################

# Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Ubuntu 20.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

###############################################################
# SSH KEY FOR ANSIBLE
###############################################################
resource "tls_private_key" "ansible_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  filename        = "${path.module}/ansible-key.pem"
  content         = tls_private_key.ansible_key.private_key_pem
  file_permission = "0400"
}

resource "aws_key_pair" "ansible_keypair" {
  key_name   = "ansible-key"
  public_key = tls_private_key.ansible_key.public_key_openssh
}

###############################################################
# EC2 FRONTEND (Amazon Linux)
###############################################################
resource "aws_instance" "frontend" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ansible_keypair.key_name

  tags = {
    Name = "frontend-amazonlinux"
  }
}

###############################################################
# EC2 BACKEND (Ubuntu)
###############################################################
resource "aws_instance" "backend" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ansible_keypair.key_name

  tags = {
    Name = "backend-ubuntu"
  }
}

###############################################################
# INVENTORY FILE FOR ANSIBLE
###############################################################
resource "local_file" "inventory" {
  filename = "${path.module}/inventory.yaml"
  content = templatefile("${path.module}/inventory.tpl", {
    frontend_ip = aws_instance.frontend.public_ip
    backend_ip  = aws_instance.backend.public_ip
  })
}
