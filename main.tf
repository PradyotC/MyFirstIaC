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

# Use Ubuntu 22.04 LTS (Jammy)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "common_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH, Web, and Tailscale traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Tailscale UDP (Optional but recommended for performance)
  ingress {
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 1. LLM Server (Brain) ---
resource "aws_instance" "llm_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "m7i-flex.large"
  
  vpc_security_group_ids = [aws_security_group.common_sg.id]
  
  tags = {
    Name = "${var.project_name}-Brain"
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -e

              # 1. Install Tailscale & Setup Cleanup
              curl -fsSL https://tailscale.com/install.sh | sh
              sysctl -w net.ipv4.ip_forward=1
              tailscale up --authkey=${var.tailscale_auth_key_brain} --hostname=brain --ssh

              # Create a service to logout on shutdown
              cat <<EOT > /etc/systemd/system/tailscale-cleanup.service
              [Unit]
              Description=Tailscale Logout
              DefaultDependencies=no
              Before=shutdown.target poweroff.target halt.target
              [Service]
              Type=oneshot
              ExecStart=/usr/bin/tailscale logout
              [Install]
              WantedBy=shutdown.target poweroff.target halt.target
              EOT
              systemctl enable tailscale-cleanup.service

              # 2. Install Ollama
              curl -fsSL https://ollama.com/install.sh | sh
              
              mkdir -p /etc/systemd/system/ollama.service.d
              echo '[Service]
              Environment="OLLAMA_HOST=0.0.0.0"
              Environment="OLLAMA_ORIGINS=*"' > /etc/systemd/system/ollama.service.d/override.conf
              
              systemctl daemon-reload
              systemctl restart ollama
              
              # 3. Create Custom Model (RAM Fix)
              # Wait for Ollama to be ready
              sleep 10
              ollama pull qwen2.5-coder:3b

              cat <<EOT > /home/ubuntu/Modelfile
              FROM qwen2.5-coder:3b
              PARAMETER num_ctx 4096
              TEMPLATE """{{ if .System }}<|im_start|>system
              {{ .System }}<|im_end|>
              {{ end }}{{ if .Prompt }}<|im_start|>user
              {{ .Prompt }}<|im_end|>
              {{ end }}<|im_start|>assistant
              {{ .Response }}<|im_end|>"""
              PARAMETER stop "<|im_start|>"
              PARAMETER stop "<|im_end|>"
              SYSTEM """You are a smart coding assistant. Write clean, efficient code."""
              EOT

              # Create the model non-interactively
              ollama create coder-lite -f /home/ubuntu/Modelfile
              EOF
}

# --- 2. Web Server (Body) ---
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  
  vpc_security_group_ids = [aws_security_group.common_sg.id]

  tags = {
    Name = "${var.project_name}-Body"
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -e

              echo "STARTING USER DATA..."

              # Fix Environment for Build
              export HOME=/root
              export GOCACHE=/root/.cache/go-build
              export GOPATH=/root/go
              export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

              # 1. Install Tools
              apt-get update
              apt-get install -y build-essential git curl

              # 2. Install Tailscale & Setup Cleanup
              curl -fsSL https://tailscale.com/install.sh | sh
              tailscale up --authkey=${var.tailscale_auth_key_body} --hostname=body --ssh

              cat <<EOT > /etc/systemd/system/tailscale-cleanup.service
              [Unit]
              Description=Tailscale Logout
              DefaultDependencies=no
              Before=shutdown.target poweroff.target halt.target
              [Service]
              Type=oneshot
              ExecStart=/usr/bin/tailscale logout
              [Install]
              WantedBy=shutdown.target poweroff.target halt.target
              EOT
              systemctl enable tailscale-cleanup.service

              # 3. Install Go
              wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
              rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
              
              # 4. Clone & Build
              echo "Cloning repository..."
              # THIS CLONES FROM GITHUB. IF YOU DIDN'T PUSH, IT GETS OLD CODE!
              git clone ${var.github_repo_url} /opt/myapp
              cd /opt/myapp/backend
              
              echo "Building Go Binary..."
              /usr/local/go/bin/go build -ldflags "-linkmode=external" -o server main.go

              # 5. Run Service
              cat <<EOT > /etc/systemd/system/go-web.service
              [Unit]
              Description=Go Web Server
              After=network.target tailscaled.service

              [Service]
              Type=simple
              User=root
              WorkingDirectory=/opt/myapp/backend
              ExecStart=/opt/myapp/backend/server
              
              # This sets the Environment Variable for the PROCESS
              Environment="OLLAMA_HOST=http://brain:11434"
              
              Restart=always
              RestartSec=5

              [Install]
              WantedBy=multi-user.target
              EOT

              systemctl daemon-reload
              systemctl enable go-web.service
              systemctl start go-web.service
              
              echo "USER DATA COMPLETE."
              EOF
}

output "web_public_ip" {
  value = "http://${aws_instance.web_server.public_ip}:80"
}