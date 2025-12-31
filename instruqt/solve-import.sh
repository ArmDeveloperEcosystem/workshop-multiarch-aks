#!/bin/bash
set -euxo pipefail

echo "🚀 Importing image into Azure Container Registry..."
az acr import --name armacr$(agent variable get randomid) --source docker.io/avinzarlez979/multi-arch:latest --image multi-arch:latest
echo "✅ ACR image import completed successfully."
