provider "aws" {
  region = "us-east-1"
}

# =============================
# Subnet Lookup (Automatically find any subnet)
# =============================
data "aws_subnets" "all" {}

data "aws_subnet" "selected" {
  id = data.aws_subnets.all.ids[0]
}

# ---------------------------
# Backend - Ubuntu
# ---------------------------
resource "aws_instance" "backend" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.micro"
  key_name               = "my-key"
  subnet_id              = data.aws_subnet.selected.id

  tags = {
    Name = "u21.local"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo hostnamectl set-hostname u21.local
  EOF
}

# ---------------------------
# Frontend - Amazon Linux
# ---------------------------
resource "aws_instance" "frontend" {
  ami                    = "ami-068c0051b15cdb816"
  instance_type          = "t3.micro"
  key_name               = "my-key"
  subnet_id              = data.aws_subnet.selected.id

  tags = {
    Name = "c8.local"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo hostnamectl set-hostname c8.local

    hostname=$(hostname)
    backend_ip="${aws_instance.backend.public_ip}"

    echo "$backend_ip $hostname" | sudo tee -a /et_
