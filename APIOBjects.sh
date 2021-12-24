#API discovery
#Get information about our current cluster context, ensure we 're logged into the correct cluster.
kubectl config get-contexts
#change our context if needed by specifying the name # change cluster
kubectl config use-context kubernetes-admin@kubernetes
#get information about the api server for our current context,wich should be kubernetes-admin@kubernetes
kubectl cluster-info
#get a list of api resources available in the cluster 
kubectl api-resources | more
#using kubectl expalin to see the structure of a resource ...specefically it's fields
#in addition to using api reference on the web this a great way to discover what it takes to write yaml manifest
kubectl explain pods | more
#let's look more closely at what we need in pod.spec and pod.spec.containers (image and name are required)
kubectl explain pod.spec | more
kubectl explain pod.spec.containers | more


