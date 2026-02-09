terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami           = "ami-051f7e7f6c2f40dc1" 
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx git
              systemctl start nginx
              systemctl enable nginx
              git clone ${var.github_repo_url} /tmp/my-repo
              cp -r /tmp/my-repo/* /usr/share/nginx/html/
              rm -rf /tmp/my-repo
              chown -R nginx:nginx /usr/share/nginx/html
              chmod -R 755 /usr/share/nginx/html
              systemctl restart nginx
              EOF

  tags = {
    Name = "${var.project_name}-Server"
  }
}

output "website_url" {
  value = "http://${aws_instance.web_server.public_ip}:80"
}