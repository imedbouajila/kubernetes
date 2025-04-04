#this demo will be run frmo master since kubectl is already installed there.
#this can be run from any system that has the azure cli client installed.

#ensure azure cli command line utilites are installed 
#https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://âckages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

#Install the gpg key for miscrosoft's repository
curl -sL https://packages.microsoft.com/key/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

sudo apt-get update
sudo apt-get install azure-cli

#log into our subscription
#free account - https://azure.microsoft.com/en-us/free/
az login
az account set --subscription "demonstration account"

#creat a resource group for this services we're going to create
az group create --name "kubernetes-cloud" --location centralus

#let's get a list of the versions available to us
az aks get-versions --location centralus -o table

#let's create our aks managed cluster. use --kubernetes-version to specify a version
az aks create \
   --resource-group "kubernetes-cloud" \
   --generate-ssh-keys \
   --name CSCluster \
   --node-count 3 #default node count is 3

#if needed, we can download and install kubectl on our local system
az aks install-cli

#get our cluster credentiels and merge the configuration into our existing config file.
#this will allow us to connect to this system remotely using certificate based user authentication.
az aks get-credentials --resource-group "kubernestes-cloud" --name CSCluster

#list our currently available contexts
kubeclt config get-contexts

#set our current context to the azure context
kubectl config use-context CSCluster

#run a command to communicate with our cluster
kubectl get nodes

#get a list of running pods we'll look at the system pods since we don't have anything running
#since the api server is http based ...we can operate our cluster over the internet...esentially the same as if ..
kubectl get pods --all-namespaces

#let's set to the kubectl context back to our local cluster
kubectl config use-context kubernetes-admin@kubernetes

#use kubectl get nodes
kubectl get nodes

#az aks delete --resource-group "kubernetes-cloud" --name CSCluster #--yes --no-wait

































































