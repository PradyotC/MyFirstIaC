# ☁️ Ephemeral Split Web-LLM (AWS + Tailscale)

An automated Infrastructure-as-Code (IaC) project to deploy a private, secure, and disposable AI Chat interface on AWS.

This project uses **Terraform** to provision the infrastructure, **Tailscale** for secure mesh networking, and **Ollama** to serve the LLM. It connects a public-facing Go/React web server to a private, backend AI inference server.

## 🏗️ Architecture

The infrastructure consists of two distinct AWS EC2 instances connected via a private Tailscale Tailnet:

1.  **The Body (Web Server):**
    - **Instance:** `t3.micro` (Low cost)
    - **Stack:** Go (Golang) Backend + React Frontend.
    - **Role:** Serves the UI and proxies API requests to the Brain.
    - **Networking:** Accessible via Public HTTP (Port 80).

2.  **The Brain (LLM Server):**
    - **Instance:** `m7i-flex.large` (Compute optimized, 20GB Storage).
    - **Stack:** Ollama running `qwen2.5-coder:3b`.
    - **Role:** Handles inference and heavy computation.
    - **Networking:** **Private only.** Accessible only via Tailscale.

**Connection Flow:**
`User` -> `Internet` -> `Web Server (Body)` --[Tailscale VPN]--> `LLM Server (Brain)`

## ✨ Key Features

- **Scale-to-Zero:** Designed to be ephemeral. Spin it up for a session, then destroy it immediately to stop costs.
- **Zero-Config Provisioning:** `user_data` scripts automatically install Docker, Tailscale, Go, and Ollama.
- **Cost Optimized:** Designed to be destroyed when not in use. Includes scripts to gracefully log out of Tailscale and terminate resources.
- **Smart Resource Management:**
    * **20GB Storage** auto-provisioned for large model files.
    * **Custom Modelfile** (`coder-lite`) created on-the-fly to optimize RAM usage (4096 context window).

## 🛠️ Prerequisites

1.  **AWS Account** (Access Key & Secret Key).
2.  **Tailscale Account:**
    - Generate two **Ephemeral** Auth Keys (one for `tag:body`, one for `tag:brain`).
    - _Note: Ephemeral keys automatically clean themselves up after the instances are destroyed._
3.  **Docker:** Used to run Terraform in a consistent environment (no local TF installation needed).

## 🚀 Getting Started

### 1. Configuration

Create a `terraform.tfvars` file in the root directory:

```hcl
aws_access_key           = "YOUR_AWS_ACCESS_KEY"
aws_secret_key           = "YOUR_AWS_SECRET_KEY"
tailscale_auth_key_brain = "tskey-auth-..."
tailscale_auth_key_body  = "tskey-auth-..."
aws_region               = "us-east-1"
project_name             = "Ollama-IaC"
```

### 2. Deployment

To initialize Terraform and apply the configuration, use the provided `create.sh` script. This script automates the `terraform init` and `terraform apply` process.

```bash
chmod +x create.sh
./create.sh
```

### 3. Access

Once deployed, Terraform will output the public IP of the Web Server. Open your browser and navigate to: `http://<web_public_ip>`

### 4. Cleanup

To remove the infrastructure and clean up the resources created by Terraform, use the `destroy.sh` script.

```bash
chmod +x destroy.sh
./destroy.sh
```

## 🧩 Tailscale ACLs

For the servers to communicate, ensure your Tailscale Access Controls (ACLs) allow traffic on port 11434:

```json
{
  "tagOwners": {
    "tag:brain": ["autogroup:admin"],
    "tag:body": ["autogroup:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:body"],
      "dst": ["tag:brain:11434"]
    }
  ]
}
```

## 🔍 Troubleshooting

Logs: If the servers start but the app isn't working, SSH into the instances and check the setup logs:

```Bash
# On either server
tail -f /var/log/user-data.log
```
