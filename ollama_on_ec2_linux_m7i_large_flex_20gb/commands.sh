#!/bin/bash

# # 1. System Updates
# apt update && apt upgrade -y

# # 2. Install Ollama
# curl -fsSL https://ollama.com/install.sh | sh

# # 3. Download Model
# wget -O /home/ubuntu/qwen2.5-coder-3b.gguf "https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf?download=true"

# # 4. Create Modelfile (Non-interactive)
# cat <<EOF > /home/ubuntu/Modelfile
# FROM /home/ubuntu/qwen2.5-coder-3b.gguf
# PARAMETER num_ctx 4096
# TEMPLATE """{{ if .System }}<|im_start|>system
# {{ .System }}<|im_end|>
# {{ end }}{{ if .Prompt }}<|im_start|>user
# {{ .Prompt }}<|im_end|>
# {{ end }}<|im_start|>assistant
# {{ .Response }}<|im_end|>"""
# PARAMETER stop "<|im_start|>"
# PARAMETER stop "<|im_end|>"
# SYSTEM """You are a smart coding assistant. Write clean, efficient code."""
# EOF

# # 5. Build Model & Cleanup
# # We run this as the 'ubuntu' user so permissions are correct
# sudo -u ubuntu ollama create coder-lite -f /home/ubuntu/Modelfile
# rm /home/ubuntu/qwen2.5-coder-3b.gguf

# # 6. Expose to Network (Tailscale Prep)
# mkdir -p /etc/systemd/system/ollama.service.d
# echo '[Service]
# Environment="OLLAMA_HOST=0.0.0.0"
# Environment="OLLAMA_ORIGINS=*"' > /etc/systemd/system/ollama.service.d/override.conf

# systemctl daemon-reload
# systemctl restart ollama

sudo apt update
sudo apt upgrade
curl -fsSL https://ollama.com/install.sh | sh
ollama -v
wget -O qwen2.5-coder-3b.gguf "https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf?download=true"
nano Modelfile
ollama create coder-lite -f Modelfile
rm qwen2.5-coder-3b.gguf
df -h
systemctl daemon-reload
systemctl restart ollama
ollama run coder-lite