# Deploy resources via Terraform

This workshop demonstrates how to deploy a multi-architectural Azure Kubernetes service with both amd and arm based nodes.

Through instruqt you have been given:

- An Azure subscription
- A terminal to work in with the required tools (git, azure cli, terraform) already installed

> [!NOTE]
> Your Azure CLI should already be configured and authorized to the correct Azure subscription.

## Plan and apply Terraform
===

In your [Terminal tab](tab-0), write the following command to prepare the current working directory for use with Terraform:

```bash,run
terraform init
```

### Terraform Plan

Then you can run `terraform plan` to see what we will deploy:

```bash,run
terraform plan -var="subscription_id=$(az account show --query id --output tsv)" -var="random_id=[[ Instruqt-Var key="randomid" hostname="cloud-client" ]]"
```

We pass in two variables to the terraform. First is the current Azure subscription, and the second is a random string of characters (in your case, `[[ Instruqt-Var key="randomid" hostname="cloud-client" ]]`) which will be used to make unique resource names within Azure.

### Terraform Apply

If everything looks correct, let's deploy via terraform:

```bash,run
terraform apply -var="subscription_id=$(az account show --query id --output tsv)" -var="random_id=[[ Instruqt-Var key="randomid" hostname="cloud-client" ]]"
```

This will take a couple of minutes to run. Make sure your screen doesn't time out!

## What are we deploying?
===

Switch to the [Editor](tab-1) tab to take a look at our terraform files while your deployment is running:

[button label="Editor"](tab-1)

### `providers.tf`

This file contains the configuration for the Terraform project and which provider versions to use.

### `variables.tf`

This file defines the input variables for the Terraform project. It allows you to parameterize the configuration and make it more flexible.

### `main.tf`

This file contains the primary configuration for the Terraform project. It defines the Azure resource group that will be used by Terraform.

### `acr.tf`

This file configures the Azure Container Registry (ACR) resource. It defines the repository where Docker images will be stored and managed.

### `aks.tf`

This file sets up the Azure Kubernetes Service (AKS) resources. It defines the AKS cluster and node groups, enabling the deployment and management of containerized applications on Kubernetes.

### `outputs.tf`

This file specifies the outputs of the Terraform project. Outputs values that are created by Terraform and can then be displayed to the user, or copied to other platforms like GitHub Actions.