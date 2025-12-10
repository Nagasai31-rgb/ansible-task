provider "aws" {
  region = "us-east-1"
}

# ---------------------------
# Backend - Ubuntu
# ---------------------------
resource "aws_instance" "backend" {
  ami                    = "ami-0ecb62995f68bb549"  
  instance_type          = "t3.micro"
  key_name               = "my-key"   
  subnet                 = "subnet-0293f00eab2b610e4"
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
  ami                    = "ami-068c0051b15cdb816"   # Amazon Linux
  instance_type          = "t3.micro"
  key_name               = "my-key"
  tags = {
    Name = "c8.local"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo hostnamectl set-hostname c8.local

    hostname=$(hostname)
    backend_ip="${aws_instance.backend.public_ip}"

    echo "$backend_ip $hostname" | sudo tee -a /etc/hosts
  EOF

  depends_on = [aws_instance.backend]
}

# ---------------------------
# Inventory file
# ---------------------------
resource "local_file" "inventory" {
  filename = "./inventory.yaml"

  content = <<EOF
[frontend]
${aws_instance.frontend.public_ip}

[backend]
${aws_instance.backend.public_ip}
EOF
}

# ---------------------------
# Outputs
# ---------------------------
output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}
