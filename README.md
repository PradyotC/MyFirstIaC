### 1. Create terraform.tfvars

```bash
aws_access_key = "AKIAIOSFODNN7EXAMPLE"
aws_secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
tailscale_tag_brain_access_id = "khawsderft11CNTRL"
tailscale_tag_brain_access_token = "tskey-auth-khawsderft11CNTRL-we87tqegqwuveycwreyqrec6edfryqfere"
tailscale_tag_body_access_id = "khploikjuq11CNTRL"
tailscale_tag_body_access_token = "tskey-auth-khploikjuq11CNTRL-MAvBJxguittuiguyguuybtrcy6cuyuetrx"
```

### 2. Deployment
To initialize Terraform and apply the configuration, use the provided `create.sh` script. This script automates the `terraform init` and `terraform apply` process.

```bash
chmod +x create.sh
./create.sh
```

### 3. Cleanup
To remove the infrastructure and clean up the resources created by Terraform, use the `destroy.sh` script.

```bash
chmod +x destroy.sh
./destroy.sh
```