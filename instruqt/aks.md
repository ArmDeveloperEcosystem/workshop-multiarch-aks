# Deploy workload into AKS

Now that we have all the pieces in place, it's time to deploy and run our application itself using kuberneters.

## Update yaml deployment file
===

In the [Editor](tab-1) tab, let's look through the various yaml files we will be using today:

[button label="Editor"](tab-1)

### hello-service.yaml

This is creates a service in kubernetes with an external facing IP address, that will direct traffic to our "hello" application we will deploy across various nodes.

### deployment yaml

There are three deployment files:

- `arm64-deployment.yaml`
- `amd64-deployment.yaml`
- `multi-arch-deployment.yaml`

All three of these files are very similar. They deploy our application from the image we imported into ACR. However, they are different in one key way.

`multi-arch-deployment.yaml` deploys the application to run on whatever node is available. However `arm64-deployment.yaml` and `amd64-deployment.yaml` implement an additional two lines of yaml called a `nodeSelector`, that only allows our application to run on either `arm64` or `amd64` based nodes respectively.

In each file, we will need to update line 21 of all three files to point to our ACR we were using in the previous steps:

```yaml
        image: <your deployed ACR name>.azurecr.io/multi-arch:latest
```

to

```yaml
        image: armacr[[ Instruqt-Var key="randomid" hostname="cloud-client" ]].azurecr.io/multi-arch:latest
```

> [!NOTE]
> Note the name of your deployed Azure Container Registry, if it is not the default `armacr[[ Instruqt-Var key="randomid" hostname="cloud-client" ]]` then edit the above line.

In order make things easier, we are provided a simple script `update-image.sh` to do this for you. Simply run the following command:

```yaml
./update-image.sh armacr[[ Instruqt-Var key="randomid" hostname="cloud-client" ]]
```

You can confirm the lines were changed correctly by looking at the files in the editor tab.

Once the files are updated, we are ready to deploy our application on our AKS cluster.

## Deploy initial AKS workload
===

In your [Terminal tab](tab-0), write the following command to load your AKS credentials into your local kubernetes:

[button label="Terminal"](tab-0)

```bash,run
az aks get-credentials --resource-group arm-aks-demo-rg-[[ Instruqt-Var key="randomid" hostname="cloud-client" ]] --name arm-aks-demo-cluster --overwrite-existing 
```

> [!NOTE]
> Once again if your resource group is not the default name of `arm-aks-demo-rg-[[ Instruqt-Var key="randomid" hostname="cloud-client" ]]`, then you will have to edit the above line to use the actual name of your deployed resource group and AKS cluster.

Deploy the service using `kubectl`

```bash,run
kubectl apply -f hello-service.yaml
```

Now that our service is running, let's deploy our application. At first, let's deploy only the version that runs on arm64 based devices:

```bash,run
kubectl apply -f arm64-deployment.yaml
```

You can check your deploy service with:

```bash,run
kubectl get svc
```

You should see the hello-service we deployed, along with an external facing IP address.

> [!IMPORTANT]
> If you still see a `pending` value for the external IP address, wait a moment and try again.

Once an external IP addressed is assigned, let's save that value to a variable:

```bash,run
export IPADDRESS=$(kubectl get services hello-service --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Then send a ping using curl:

```bash,run
curl -w '\n' $IPADDRESS
```

You should get a reply from that service that confirms the Go application is running, and which architecture the application is running on.

## Deploy multi-architectural workloads
===

Now it's time to deploy the amd64 version of the application:

```bash,run
kubectl apply -f amd64-deployment.yaml
```

You can now see you have pods for both the arm64 and amd64 deployments.

```bash,run
kubectl get pods
```

Note that these are running the same application, and your load balancer will automatically assign a response from one upon request.

You can test this by sending more pings to the service:

```bash,run
curl -w '\n' $IPADDRESS
```

> [!NOTE]
> Remember you can run `kubectl get svc` to get the external IP address of your service.

Do this a couple of times, and you should see two different kinds of responses. Showing the Go application is running sometimes on amd64 and other times on arm64 based nodes.

Let's add a third deployment without the architecture restrictions:

```bash,run
kubectl apply -f multi-arch-deployment.yaml
```

Since our docker image has both an amd64 and arm64 version, it is compatible with all our nodes.

You can now see you have three pods for both the arm64, amd64 and multi architectural deployments.

```bash,run
kubectl get pods
```

Let's run a little script to ping the service repeatedly. Insert the external IP address of your service into this line of code and run it:

```bash,run
for i in $(seq 1 20); do curl -w '\n' $IPADDRESS; done
```

You will now get a variety of messages back. Some will be from the application deployments that we assigned to run on amd or arm. Others will be on the multi architectural deployment that could be running on both amd and arm based compute.

The load balance will automatically direct traffic to your various pods that is completely invisible to your end user.

This is a great example of how you can implement new architecture into your existing workloads without having to take existing services down. Then gradually change the available of your nodes as you optimize for cost and scale.

To complete this workshop and clean up these resources, click the **Next** button below.
