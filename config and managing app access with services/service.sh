#1. exposing and accessing applications with Services on our local cluster
#ClusterIP 

#Imperative, create a deployment with one replica
kubectl create deployment hello-word-clusterip \
    --image=gcr.io/google-samples/hello-app:1.0

#when creating a service, you can define a type, if you don't define a type, eht default is ClusterIP
kubectl expose deployment hello-world-clusterip \
    --port=80 --target-port=8080 --type ClusterIP 

#get a list of services, examine the type, CLUSTER-IP and Port
kubectl get service 

#get the service's ClusterIP and store that for reuse
SERVICEIP=$(kubectl get service hello-world-clusterip -o jsonpath='{.spec.clusterIP}')
echo $SERVICEIP

#access the service inside the cluster 
curl http://$SERVICEIP

#GET a listing of the endpoints for a service, we see the one pod endpoint registered
kubectl get endpoints hello-world-clusterip
kubectl get pods -o wide    

#access the pod's application directly on the target port on the pod, not the service's port, useful for troubelshooting 
#right now there's only one pod and its one endpoint
kubectl get endpoints hello-world-clusterip 
PODIP=$(kubectl get endpoints hello-world-clusterip -o jsonpath='{.subsets[].addresses[].ip}')
echo $PODIP 
curl http://$PODIP:8080 

#scale the deployment, new endpoints are registred automatically 
kubectl scale deployment hello-world-clusterip --replicas=6
kubectl get endpoints hello-world-clusterip     

#access the service inside the cluster, this time our requests will be load balanced ...whoo!
curl http://$SERVICEIP 

#the service's endpoints match the labels, let's look at the service and it's selector and the pods labels 
kubectl describe service hello-world-clusterip
kuibectl get pods --show-labels 

#clean up these resources for next demo 
kubectl delete deployments hello-world-clusterip 

#2- creating a NodePort Service 
#Imperative, create a deployment with one replica
kubectl create deployment hello-world-nodeport \
    --image=gcr.io/google-samples/hello-app:1.0 

#when creating a service, you can define a type, if you don't define a type, eht default is ClusterIP
kubectl expose deployment hello-world-nodeport \
    --port=80 --target-port=8080 --type NodePort 

#let's check out the services details, ther's the node port after the : on the ports column.it's also got a cluster..
#this nodeport service is available on the nodePort on each node in the cluster 
kubectl get service 

CLUSTERIP=$(kubectl get service hello-world-nodeport -o jsonpath='{.spec.clusterIP}')
PORT=$(kubectl get service hello-world-nodeport -o jsonpath='{.spec.sports[].port}')
NODEPORT=$(kubectl get service hello-world-nodeport -o jsonpath='{.spec.ports[].nodePort}')

#let's access the services on the node port...we can do that on each node in the cluster and 
#from outside the cluster ...regardless of wherer the pod actually is 

#we have only one pod online supporting our service 
kubectl get pods -o wide 

#and we can access the service by hitting the node port on any node in the cluster on the node's  real ip or name 
#this will forward to the cluster ip and get load balanced to a pod .even if there is only one Pod 
curl http://master:$NODEPORT
curl http://node1:$NODEPORT 
curl http://node2:$NODEPORT
curl http://node3:$NODEPORT 

#and a node port service is also listing on a Cluster IP , in fact the Node port traffic is routed to the clusterip 
echo $CLUSTERIP:$PORT 
curl http://$CLUSTERIP:PORT     

#let's delete that service 
kubectl delete service hello-world-nodeport
kubeclt delete deployment hello-world-nodeport 

#3 - creating lb services in azure or any cloud 
#switch contexts into AKS, we created this cluster together in kubernetes installation and config funfdamental
#I'Ve added a script to create a GKE and AKS cluster this course's downloads
kubectl config use-context 'k8s-cloud'

#let's create a deployment 
kubectl create deployment hello-world-loadbalancer \
    --image=gcr.io/google-samples/hello-app:1.0 

#when creating a service, you can define a type, if you don't define a type , the default is ClusterIP 
kubectl expose deployment hello-world-loadbalancer \
    --port=80 --target-port=8080 --type LoadBalancer 

#can take a minute for the load balancer to provision and get an public IP , you'll see EXTERNAL-IP as <pending>
kubectl get service 

LOADBALANCERIP=$(kubectl get service hello-world-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[].ip}') 
curl http://$LOADBALANCERIP:$PORT 

#the loadbalancer, which is 'outside' your cluster, sends traffics traffic to the NodePort Service which sends it to the ClusterIP 
#your cloud load balancer will have health probes checking the health of the node port service on the real node IPs
#this isn't the health of our application, that still needs to be configured via readness/liveness probes and maint..
kubectl get service hello-world-loadbalancer 

#clean up the resources from this demo 
kubectl delete deployment hello-world-loadbalancer 
kubectl delete service hello-world-loadbalancer 

#let's switch back to our local cluster 
kubectl config use-context kubernetes-admin@kubernetes 

#declarative examples 
kubectl config use-context kubernetes-admin@kubernetes 
kubectl apply -f service-hello-world-clusterip.yaml 
kubectl get service 




#creating a NodPort with a predefined port, first with a port outside of the NodePort rang then a corrected one  
kubectl apply -f service-hello-world-nodeport-incorrect.yaml 
kubectl apply -f service-hello-world-nodeport.yaml
kubectl get service 

#switch contexts to azure to create a cloud load balancer 
kubectl config use-context 'k8s-cloud'
kubectl apply -f service-hello-world-loadbalancer.yaml 
kubectl get service 

####################################################################################################
#serviceDiscovery

#cluster DNS 
#let's create a deployment in the default namespace 
kubectl create deployment hello-world-clusterip \
    --image=gcr.io/google-samples/hello-app:1.0

#let's create a deployment in the default namspace 
kubectl expose deployment hello-world-clusterip \
    --port=80 --target-port=8080 --type ClusterIP 

#we can use nslookup or dig to investigate the dns record, it's cname @10.96.0.10 is the cluster ip of our dns server 
kubectl get service kube-dns --namespace kube-system 

#each service gets a dns record, we can use this in our applications to find services by name 
#the a record is in the form <servicename>.<namespace>.svc.<clusterdomain>
nslookup hello-world-clusterip.default.svc.cluster.local 10.96.0.10 
kubectl get service hello-world-clusterip   

#create a namespace , deployment with one replica and a service 
kubectl create namespace ns1

#let's create a deployment with the same name as the first one, but in our new namespace 
kubectl create deployment hello-world-clusterip --namespace ns1 \
    --image=gcr.io/google-samples/hello-app:1.0 

kubectl expose deployment hello-world-clusterip --namespace ns1 \
    --port=80 --target-port=8080 --type ClusterIP 

#let's chech the dns record for the service in the namespace, ns1 . see how ns1 is in the DNS record ?
# <servicename>.<namespace>.svc.<clusterdomain>
nslookup hello-world-clusterip.ns1.svc.cluster.local 10.96.0.10 

#our service in the default namespace is still there, these are completely unique services 
nslookup hello-world-clusterip.default.svc.cluster.local 10.96.0.10 

#get the envirobnement variables for the pod in our default namespace 
#more details about the lifecycle of variables in 'configyration and managing kubernetes storage ans shecduling'
#only the kubernetes service is available? why ? i created the deployment then i created the service 

PODNAME=$(kubectl get pods -o jsonpath='{.items[].metadata.name}')
echo $PODNAME 
kubectl exec -it $PODNAME -- env | sort 

#environment variables are only create at pod start up, so let's delete the pod 
kubectl delete pod $PODNAME 

# and check the environment variables again ...
PODNAME=$(kubectl get pods -o jsonpath='{.items[].metadata.name}')
echo $PODNAME 
kubectl exec -it $PODNAME -- env | sort 

#externalName
kubectl apply -f service-externalname.yaml 

########## service-externalname.yaml  ############
apiVersion: v1 
kind: Service 
metadata:
    name: hello-world-api 
spec:
    type: ExternalName 
    externalName: hello-world.api.exaple.com    
###################################################

# the record is in the form <servicename>.<namespace>.<clusterdomain>
nslookup hello-world-api.default.svc.cluster.local 10.96.0.10 

#let's clean up our resources in this demo 
kubectl delete service hello-world-api 
kubectl delete service hello-world-clusterip
kubectl delete service hello-world-clusterip --namespace ns1 
kubectl delete deployment hello-world-clusterip
kubectl delete deployment hello-world-clusterip --namespace ns1
kubectl delete namespace ns1