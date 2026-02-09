variable "aws_access_key" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "Region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "Ollama-IaC"
}

variable "tailscale_auth_key_brain" {
  description = "Tailscale Auth Key for the LLM Server (tag:brain)"
  type        = string
  sensitive   = true
}

variable "tailscale_auth_key_body" {
  description = "Tailscale Auth Key for the Web Server (tag:body)"
  type        = string
  sensitive   = true
}

variable "github_repo_url" {
  description = "URL of the repo to clone"
  type        = string
  default     = "https://github.com/PradyotC/ephemeral-split-web-llm.git" 
  # Note: Ensure this URL is correct and public, or use an SSH key in user_data
}