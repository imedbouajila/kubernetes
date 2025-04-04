#log into the control plane node 
ssh master

#listing and inspecting your...helpful for knowing which cluster is your courrent context
kubectl cluster-info

#one of the most common operations tou will use is get ...
#review status, roles and versions
kubectl get nodes 

#you can add output modifier to get to *get* more information about a resource
#additional information about each node in the cluster
kubectl get nodes -o wide

#let's get a list of pods..but there isn't any running
kubectl get pods 
#true but let's get a list of system pods a namespace is a way to group resources together.
kubectl get pods --namespace kubesystem

#let's get additional information about each pod 
kubectl get pods --namespace kube-system -o wide

#Now let's get a list of everything that's running in all namespaces
#in additional to pods, we see services , deamonsets, deployments and replicasets
kubectl get all --all-namespaces | more

#asking kubernetes for the resources it know about
#let's look at the headers in each column name,alias/shortnames,api version
#is the resources in a namespace, for exemple storageclass isn't and is available to all namespaces and finally kind
kubectl api-resources | more

#you'll soon find your favorite alias
kubectl get no

#we can easily filter using group
kubectl api-resources |grep pod

#explain an individual resource in detail
kubectl explain pod | more
kubectl explain pod.spec | more
kubectl explain pod.spec.containers | more
kubectl explain pod --recursive | more 

#let's take a closer look at our nodes using describe
#check out name ,taints, conditions,addresses,system info,non-terminated pod, and events
kubectl describe nodes master| more

#use -h or --help to find help 
kubectl -h | more
kubectl get -h | more
kubectl create -h | more

#ok so now that we're tired of typing commands out, let's enable bash auto-complet of our kubectl commands
sudo apt-get install -y bash-completion
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
kubectl g[tab][tab] po[tab][tab] --all[tab][tab]

# diff 
kubectl diff -f deployment.yaml










































































































