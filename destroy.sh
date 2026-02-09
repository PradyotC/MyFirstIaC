#!/bin/bash
echo "💀 Destroying Infrastructure..."

if [ ! -f "terraform.tfstate" ]; then
    echo "❌ No state file found."
    exit 1
fi

docker run --rm -it \
  --name tf-destroy \
  --entrypoint "" \
  -v "$(pwd)/terraform.tfvars:/workspace/terraform.tfvars" \
  -v "$(pwd):/workspace/data" \
  -w /workspace/data \
  my-tf-infra sh -c "terraform destroy -auto-approve"

if [ $? -eq 0 ]; then
  echo "🧹 Cleaning up Docker artifacts..."
  docker rmi my-tf-infra
  echo "✅ Done! Infrastructure destroyed and Docker image removed."
  echo "ℹ️  Note: If you used Ephemeral Keys, the machines will disappear from Tailscale shortly."
else
  echo "❌ Terraform destroy failed. Keeping Docker image for debugging."
fi