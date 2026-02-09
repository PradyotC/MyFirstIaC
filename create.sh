#!/bin/bash
echo "🚀 Starting Fresh Deployment..."

# Remove old state to force fresh resource creation
if [ -f "terraform.tfstate" ]; then
    echo "🗑️  Deleting old Terraform state..."
    rm terraform.tfstate terraform.tfstate.backup
fi

echo "🐳 Building Docker Image..."
docker build -t my-tf-infra .

echo "🔥 Applying Terraform..."
docker run --rm -it \
  --name tf-apply \
  --entrypoint "" \
  -v "$(pwd)/terraform.tfvars:/workspace/terraform.tfvars" \
  -v "$(pwd):/workspace/data" \
  -w /workspace/data \
  my-tf-infra sh -c "terraform init && terraform apply -auto-approve"