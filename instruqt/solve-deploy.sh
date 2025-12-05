#!/bin/bash
set -euxo pipefail

echo "Starting deploy solve script"

cd multiarch/terraform

terraform init -input=false

terraform plan -var="subscription_id=$(az account show --query id --output tsv)" -var="random_id=$(agent variable get randomid)" -out tfplan

echo "🚀 Applying Terraform changes..."
if terraform apply tfplan; then
    echo "✅ Terraform apply completed successfully."
else
    echo "❌ Terraform apply failed."
    exit 1
fi
