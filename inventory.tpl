all:
  hosts:
    frontend:
      ansible_host: ${frontend_ip}
      ansible_user: ec2-user
      ansible_ssh_private_key_file: ansible-key.pem

      backend_ip: ${backend_ip}

    backend:
      ansible_host: ${backend_ip}
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ansible-key.pem
