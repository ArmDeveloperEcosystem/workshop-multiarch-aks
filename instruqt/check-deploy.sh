#!/bin/bash
set -euxo pipefail

# Check if terraform apply is running
if pgrep -f "terraform apply" > /dev/null; then
    echo "Terraform apply is currently running."
    fail-message "Please wait for terraform apply to finish running."
else
    echo "No terraform apply process found."
fi

UNIQUE_ID=$(agent variable get randomid)

# Define the expected resources from Terraform
EXPECTED_RESOURCES=(
    "resourceGroup:arm-aks-demo-rg-$UNIQUE_ID"
    "aksCluster:arm-aks-demo-cluster"
    "acr:armacr$UNIQUE_ID"
    "nodePool:armpool"
    "nodePool:amdpool"
)

# Azure subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Function to check if a resource exists
check_resource() {
    local resource_type=$1
    local resource_name=$2

    case $resource_type in
        resourceGroup)
            az group show --name "$resource_name" --subscription "$SUBSCRIPTION_ID" &>/dev/null
            ;;
        aksCluster)
            az aks show --name "$resource_name" --resource-group "${EXPECTED_RESOURCES[0]#*:}" --subscription "$SUBSCRIPTION_ID" &>/dev/null
            ;;
        acr)
            az acr show --name "$resource_name" --subscription "$SUBSCRIPTION_ID" &>/dev/null
            ;;
        nodePool)
            az aks nodepool show --cluster-name "${EXPECTED_RESOURCES[1]#*:}" --resource-group "${EXPECTED_RESOURCES[0]#*:}" --name "$resource_name" --subscription "$SUBSCRIPTION_ID" &>/dev/null
            ;;
        *)
            echo "Unknown resource type: $resource_type"
            return 1
            ;;
    esac
}

# Check each expected resource
for resource in "${EXPECTED_RESOURCES[@]}"; do
    IFS=":" read -r resource_type resource_name <<<"$resource"
    echo "Checking $resource_type: $resource_name..."
    if check_resource "$resource_type" "$resource_name"; then
        echo "✅ $resource_type '$resource_name' exists."
    else
        echo "❌ $resource_type '$resource_name' is missing."
        fail-message "Not all required resources were found in the Azure subscription: $resource_type '$resource_name' is missing."
    fi
done

# Check AKS cluster status
echo "Checking AKS cluster provisioning state..."
AKS_STATE=$(az aks show --name "${EXPECTED_RESOURCES[1]#*:}" --resource-group "${EXPECTED_RESOURCES[0]#*:}" --subscription "$SUBSCRIPTION_ID" --query "provisioningState" -o tsv)
if [ "$AKS_STATE" != "Succeeded" ]; then
    echo "❌ AKS cluster deployment failed. Current state: $AKS_STATE"
    fail-message "AKS cluster deployment was not successful. Current state: $AKS_STATE"
else
    echo "✅ AKS cluster deployment successful."
fi

# Check ACR status
echo "Checking ACR provisioning state..."
ACR_STATE=$(az acr show --name "${EXPECTED_RESOURCES[2]#*:}" --subscription "$SUBSCRIPTION_ID" --query "provisioningState" -o tsv)
if [ "$ACR_STATE" != "Succeeded" ]; then
    echo "❌ ACR deployment failed. Current state: $ACR_STATE"
    fail-message "ACR deployment was not successful. Current state: $ACR_STATE"
else
    echo "✅ ACR deployment successful."
fi

# Check node pools status
for i in {3..4}; do
    nodepool_name="${EXPECTED_RESOURCES[$i]#*:}"
    echo "Checking node pool '$nodepool_name' provisioning state..."
    NODEPOOL_STATE=$(az aks nodepool show --cluster-name "${EXPECTED_RESOURCES[1]#*:}" --resource-group "${EXPECTED_RESOURCES[0]#*:}" --name "$nodepool_name" --subscription "$SUBSCRIPTION_ID" --query "provisioningState" -o tsv)
    if [ "$NODEPOOL_STATE" != "Succeeded" ]; then
        echo "❌ Node pool '$nodepool_name' deployment failed. Current state: $NODEPOOL_STATE"
        fail-message "Node pool '$nodepool_name' deployment was not successful. Current state: $NODEPOOL_STATE"
    else
        echo "✅ Node pool '$nodepool_name' deployment successful."
    fi
done

echo "✅ All deployments completed successfully!"
