# Deploy workload into AKS

Now that we have all the pieces in place, it's time to deploy and run our application itself using kuberneters.

## Deploy initial AKS workload
===

In your [Terminal tab](tab-0), write the following command to load your AKS credentials into your local kubernetes:

```bash,run
az aks get-credentials --resource-group arm-aks-demo-rg-`[[ Instruqt-Var key="randomid" hostname="cloud-client" ]] --name arm-aks-demo-cluster --overwrite-existing 
```

> [!NOTE]
> Once again if you did not set your `random_id` to `[[ Instruqt-Var key="randomid" hostname="cloud-client" ]]` during deployment, then you will have to edit the above line to use the actual name of your deployed resource group and AKS cluster.
