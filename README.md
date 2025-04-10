
# Multi-Architectural Kubernetes Cluster on Azure

This tutorial provides a step-by-step guide to create and deploy a multi-architectural Kubernetes cluster on Azure. Follow the instructions below to set up your environment, build multi-architecture container images, and deploy them to your Azure Kubernetes Service (AKS) cluster.

## Prerequisites

Before you begin, ensure you have the following installed:

- Azure CLI.
- Docker with Buildx enabled.
- Terraform.
- Kubernetes CLI (`kubectl`)

You will of course also need access to an Azure subscription.

## Steps

### 1. Set Up Azure CLI

1. Authenticate with Azure:

    ```bash
    az login
    ```

2. Verify your Azure account:

    ```bash
    az account show
    ```

    If the active Azure subscription is not correct, follow these steps to change it:

    1. List all available subscriptions:

        ```bash
        az account list --output table
        ```

    2. Set the desired subscription as active:

        ```bash
        az account set --subscription "<subscription-id>"
        ```

    3. Verify the active subscription:

        ```bash
        az account show
        ```

### 2. Configure Terraform

1. Navigate to the `terraform` directory

    ```bash
    cd terraform
    ```

1. Initialize Terraform:

    ```bash
    terraform init
    ```

1. Plan the infrastructure:

    ```bash
    terraform plan -var="subscription_id=$(az account show --query id --output tsv)"
    ```

    Review the plan before applying. Ensure that your actively Azure subscription is the correct one.

1. Apply the Terraform configuration:

    ```bash
    terraform apply -var="subscription_id=$(az account show --query id --output tsv)"
    ```

    Make sure you note the deployment name of the ACR, you'll need that for later.

### 3. Build and Push Multi-Architecture Images

1. Navigate to the `go` directory:

    Back out of the `terraform` directory if you are still into it:

    ```bash
    cd ..
    ```

    Then go into the `go` directory:

    ```bash
    cd go
    ```

1. Log in to Azure Container Registry (ACR):

    ```bash
    az acr login --name <acr-name>
    ```

1. Set up Docker Buildx:

    ```bash
    docker buildx create --name multiarch --use --bootstrap
    ```

1. Build and push the multi-architecture image:

    ```bash
    docker buildx build -t <acr-name>.azurecr.io/multi-arch:latest --platform linux/amd64,linux/arm64 --push .
    ```

### 4. Deploy initial AKS workload

1. Navigate to the `aks` directory:

    Back out of the `go` directory if you are still into it:

    ```bash
    cd ..
    ```

    Then go into the `aks` directory:

    ```bash
    cd aks
    ```

1. Get AKS credentials:

    ```bash
    az aks get-credentials --resource-group <resource-group-name> --name <aks-name> --overwrite-existing
    ```

1. Update the deployment YAML files with the ACR name:

    Open each deployment YAML file ([`arm64-deployment.yaml`](aks/arm64-deployment.yaml), [`amd64-deployment.yaml`](aks/amd64-deployment.yaml), [`multi-arch-deployment.yaml`](aks/multi-arch-deployment.yaml)) and replace `<your deployed ACR name>` with the name of your ACR you deployed via Terraform.

    For example, in line 21 of [`multi-arch-deployment.yaml`](aks/multi-arch-deployment.yaml):

    ```yaml
    image: <your deployed ACR name>.azurecr.io/multi-arch:latest
    ```

    Save the changes to the YAML files.

1. Deploy the service:

    ```bash
    kubectl apply -f hello-service.yaml
    ```

1. Deploy the ARM64 workload:

    ```bash
    kubectl apply -f arm64-deployment.yaml
    ```

### 5. Verify the Deployment

1. Check the services:

    ```bash
    kubectl get svc
    ```

    You should see the service we deployed, along with an external facing IP address.

2. Test the service:

    Using that external IP address, send a ping to the service:

    ```bash
    curl -w '\n' http://<IP-of-your-AKS>
    ```

    You should get a reply from that service that confirms the go application is running, and which architecture the application is running on.

### 6. Deploy a second AKS workload

1. Deploy the AMD64 workload:

    ```bash
    kubectl apply -f amd64-deployment.yaml
    ```

1. Verify the pods:

    ```bash
    kubectl get pods
    ```

    You should see both workloads on your cluster now.

1. Using the same external IP address, send more pings to the service:

    ```bash
    curl -w '\n' http://<IP-of-your-AKS>
    ```

    Do this a couple of times, and you should see two different kinds of responses. Showing the go application is running on both amd and arm based nodes.

### 7. Deploy a third multi-architectural AKS workload

1. Deploy the multi-architecture workload:

    ```bash
    kubectl apply -f multi-arch-deployment.yaml
    ```

1. Verify the pods:

    ```bash
    kubectl get pods
    ```

    You will now see three different pods for our three deployments

1. Perform multiple requests to test load balancing:

    ```bash
    for i in $(seq 1 20); do curl -w '\n' http://<IP-of-your-AKS>; done
    ```

    You will now get a variety of message types back.

    Some will be from the application deployments that we assigned to run on amd or arm. Others will be on the multi architectural deployment that will run on both amd and arm based compute.

    The load balance will automatically direct traffic to your various pods that in a real world scenario will be completely invisible to your end user.

## Notes

- Ensure your ACR is attached to your AKS cluster:
    If you deployed using the terraform from this repo, this is already configured for you and you should not need to do this step.

    However, if you pushed your docker image to a different ACR, you can link it to your AKS with the following Azure CLI command:

    ```bash
    az aks update --name <aks-name> --resource-group <resource-group-name> --attach-acr <acr-name>
    ```

    Or:

    ```bash
    az aks update --name <aks-name> --resource-group <resource-group-name> --attach-acr <acr-resource-id>
    ```

## Cleanup

To avoid unnecessary costs, delete the resources when you're done:

1. Navigate to the `terraform` directory:

    Back out of the `aks` directory if you are still into it:

    ```bash
    cd ..
    ```

    Go back into your terraform folder:

    ```bash
    cd terraform
    ```

2. Destroy the infrastructure using Terraform:

    ```bash
    terraform destroy -var="subscription_id=$(az account show --query id --output tsv)"
    ```

    Confirm the prompt to proceed with the destruction of resources.

## Conclusion

You have successfully created and deployed a multi-architectural Kubernetes cluster on Azure. This setup allows you to run workloads across different architectures seamlessly.
