provider "aws" {
  region = "us-east-1"
}

# =====================================
# Automatically generate SSH key pair
# =====================================

resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "my-key"
  public_key = tls_private_key.generated.public_key_openssh

  lifecycle {
    ignore_changes = [public_key]   # prevents DuplicateKey errors
  }
}

resource "local_file" "private_key" {
  content          = tls_private_key.generated.private_key_pem
  filename         = "${path.module}/my-key.pem"
  file_permission  = "0400"
}

# =====================================
# Subnet Lookup (Auto-select first subnet)
# =====================================
data "aws_subnets" "all" {}

data "aws_subnet" "selected" {
  id = data.aws_subnets.all.ids[0]
}

# =====================================
# Backend - Ubuntu EC2
# =====================================

resource "aws_instance" "backend" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = data.aws_subnet.selected.id

  tags = {
    Name = "u21.local"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo hostnamectl set-hostname u21.local
  EOF
}

# =====================================
# Frontend - Amazon Linux EC2
# =====================================

resource "aws_instance" "frontend" {
  ami                    = "ami-068c0051b15cdb816"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.generated_key.key_name
  subnet_id              = data.aws_subnet.selected.id

  tags = {
    Name = "c8.local"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo hostnamectl set-hostname c8.local
    backend_ip="${aws_instance.backend.public_ip}"
    echo "$backend_ip backend" | sudo tee -a /etc/hosts
  EOF

  depends_on = [aws_instance.backend]
}

# =====================================
# Inventory file for Ansible
# =====================================
resource "local_file" "inventory" {
  filename = "./inventory.yaml"

  content = <<EOF
[frontend]
${aws_instance.frontend.public_ip}

[backend]
${aws_instance.backend.public_ip}
EOF
}

# =====================================
# Outputs
# =====================================

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}

output "private_key_location" {
  value = local_file.private_key.filename
}
