#!/usr/bin/env bash
set -euxo pipefail

###############################################################################
# Azure ARM-based VM Launch Script (using standard service principal credentials)
#
# This script logs in non-interactively using service principal credentials.
# It assumes that the following environment variables are set:
#   ARM_CLIENT_ID
#   ARM_CLIENT_SECRET
#   ARM_TENANT_ID
#
# Deployment variables are defined at the top for ease of editing.
###############################################################################

# Deployment variables
location="${AZURE_LOCATION:-eastus}"

# Project variable
agent variable set randomid $(head /dev/urandom | tr -dc 'a-z' | head -c 5)

###############################################################################
# Install terraform
###############################################################################
wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update && apt install terraform

###############################################################################
# Install docker
###############################################################################
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh

###############################################################################
# Login using service principal credentials.
###############################################################################
until az login --service-principal --username "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" --output none; do
  echo "Service principal login failed. Retrying in 3 seconds..."
  sleep 3
done
echo "Logged in using service principal. Using Azure location: $location"

###############################################################################
# Create Azure Policy to restrict VMSS SKUs
###############################################################################
echo "Creating Azure policy to restrict VMSS SKUs..."

# Create policy definition
policy_rule='{
  "if": {
    "allOf": [
    {
      "field": "type",
      "equals": "Microsoft.Compute/virtualMachineScaleSets"
    },
    {
      "not": {
      "field": "Microsoft.Compute/virtualMachineScaleSets/sku.name",
      "in": "[parameters('\''multiarchAllowedSKUs'\'')]"
      }
    }
    ]
  },
  "then": {
    "effect": "Deny"
  }
}'
az policy definition create \
  --name "restrict-vmss-skus" \
  --display-name "Restrict Virtual Machine Scale Sets SKUs" \
  --description "Restricts VMSS to only use allowed SKUs for multiarch workshop" \
  --mode "Indexed" \
  --rules "$policy_rule" \
  --params '{
  "multiarchAllowedSKUs": {
    "type": "Array",
    "metadata": {
    "displayName": "Allowed Size SKUs",
    "description": "The list of size SKUs that can be specified for VMSS.",
    "strongType": "VMSKUs"
    }
  }
}'

# Assign policy to subscription
az policy assignment create \
  --name "restrict-vmss-skus-assignment" \
  --display-name "Restrict VMSS SKUs Assignment" \
  --policy "restrict-vmss-skus" \
  --params '{
    "multiarchAllowedSKUs": {
      "value": [
        "standard_b2pls_v2",
        "standard_a2_v2"
      ]
    }
  }'

echo "Azure policy created and assigned successfully."

###############################################################################
# Create Azure Policy to restrict standalone VM deployments (only allow AKS nodes)
###############################################################################
echo "Creating Azure policy to restrict standalone VM deployments..."

# Create policy definition for standalone VM restriction
vm_policy_rule='{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "not": {
          "value": "[resourceGroup().name]",
          "like": "MC_*"
        }
      }
    ]
  },
  "then": {
    "effect": "Deny"
  }
}'

az policy definition create \
  --name "restrict-standalone-vms" \
  --display-name "Restrict Standalone Virtual Machines" \
  --description "Prevents deployment of VMs unless they are part of an AKS node pool" \
  --mode "Indexed" \
  --rules "$vm_policy_rule"

# Assign policy to subscription
az policy assignment create \
  --name "restrict-standalone-vms-assignment" \
  --display-name "Restrict Standalone VMs Assignment" \
  --policy "restrict-standalone-vms"

echo "Standalone VM restriction policy created and assigned successfully."

###############################################################################
# Clone Git repo
###############################################################################
git clone https://github.com/ArmDeveloperEcosystem/workshop-multiarch-aks.git multiarch
