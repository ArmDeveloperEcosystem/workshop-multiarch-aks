#!/bin/bash
set -euxo pipefail

# Function to print error messages
error_exit() {
    echo "❌ ERROR: $1" >&2
    exit 1
}

cd terraform || error_exit "Failed to change directory to terraform."

terraform init -input=false || error_exit "Terraform init failed."

terraform plan -var="subscription_id=$(az account show --query id --output tsv)" -var="random_id=$(agent variable get randomid)" -out tfplan

echo "🚀 Applying Terraform changes..."
if terraform apply tfplan -auto-approve; then
    echo "✅ Terraform apply completed successfully."
else
    error_exit "Terraform apply failed."
fi
