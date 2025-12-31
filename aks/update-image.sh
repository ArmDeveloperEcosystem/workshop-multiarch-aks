#!/bin/bash

# Check if ACR name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <acr_name>"
    exit 1
fi

acr_name="$1"

# Update the image line in each deployment file
for file in amd64-deployment.yaml arm64-deployment.yaml multi-arch-deployment.yaml; do
    if [ -f "$file" ]; then
        sed -i.bak "s|<your deployed ACR name>|${acr_name}|g" "$file"
        rm "${file}.bak"  # Clean up backup file
        echo "Updated $file"
    else
        echo "Warning: $file not found. Skipping."
    fi
done

echo "ACR updates completed."