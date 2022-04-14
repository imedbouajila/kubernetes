# localCluster - Calico CNI Plugin 
#get all nodes and their IP information, INTERNAL-IP is the real IP of the Node 
kubectl get nodes -o wide 
#let's deploy a basic workload.hello-world with 3 replicas to create some pods on the pod network
kubectl apply -f deployment.yaml
###################### deployment.yaml ###################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world 
spec:
    replicas: 3
    selector:
        matchLabels:
            app: hello-world 
    template:
        metadata:
            labels:
                app: hello-world  
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              ports:
                - containerPort: 8080
##########################################################
#get all pods, we can see each pod has a unique IP on the Pod network
#our pod network was defined in the first course and we chose 192.168.0.0/16
kubectl get pods -o wide 

#let's hop inside a pod and check out it's networking, a single interface an IP on the POD NETWORK
#the line below will get a list of pods from the label query and return the name of the first pod in the list 
PODNAME=$(kubectl get pods -selector=app=hello-world -o jsonpath='{ .items[0].metadata.name}')
echo $PODNAME
kubectl exec -it $PODNAME -- /bin/sh 
ip addr
exit

#for the pod on node1 ,let's find out how traffic gets from master to node1 to get to that pod
#look at PodCIDR and also the annotations, specifically the annotation projectcalico.org/IPv4IPIPTunnelAddr:192.168.222.211
#check out the addresses: InternalIP ,that's the real IP of the Node 
#chech out: PodCIDR (single IPv4 or IPv6 Rang)
#   PodCIDRs (multiple IP Ranges,but only 1 IPv4 and IPv6 Range)
# but the pods aren't on the node's PodCIDR Network...why not ?
# we're using the calico pod network which is configurable, it's controlling the IP allocation 
#calico is using a tunnel interfaces to implement the pod network model
#traffic going to other pods will be sent into the tunnel interface and directly to the node running the pod 
#for more info on calico's operations http://docs.projectcalico.org/reference/cni-plugin/configuration
kubectl describe node node1 | more

#let's see how the traffic gets to node1 form master
#via routes on the node , to get to node1 traffic goes into tunl0/192.168.19.64
#calico handles the tunneling and sends the packet ti the correct node to be send on into the pod running on the node
#follow each route, showing how to get to the pod IP , it need to go to the tuni0 interface 
#there cali* interfaces are for each pod on the pod network, traffic destined for the pod IP will have a 255.255.255.255
kubectl get pods -o wide 
route 

#the local tunl0 is 192.168.19.64 packets destined for pods running on master1 will be routed to this interface 
#then send to the destination node for de-encapsulation
ip addr

#log into node1 and look at the interfaces, there's tunl0 192.168.222.192 ... this is this node's tunnel interface 
ssh devops@node1
# this tunl0 is the destination interface, on this node its 192.168.222.192 which we saw on the routez listing on node1
ip addr
#all nodes will have routes bacj to the other nodes via the tunl0 interface 
route 
# exit back to master
exit


#Azure kubernetes Servise - kubenet 
#get all nodes and their Ip information , internal-IP is the real ip of the node 
kubectl config  use-context 'k8s-cloud'

#let's deploy a basic workload, hello word with 3 replicas 
kubectl apply -f deployment.yaml 
###################### deployment.yaml ###################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world 
spec:
    replicas: 3
    selector:
        matchLabels:
            app: hello-world 
    template:
        metadata:
            labels:
                app: hello-world  
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              ports:
                - containerPort: 8080
##########################################################
#note the internal-ip, these are on the virtual network in azure , the real ips of the underlying vms 
kubectl get nodes - wide 
#this time we're using a different network plugin, kubenet. it's based on routes/bridges rather than tunnels.let's ..
#check out adderesses and PodCIDR
kubectl describe nodes | more 
#the pods are getting ips from their node's PodCIDR Rang 
kubectl get pods -o wide 

##############################################################################################################################
#Access an AKS node via ssh so we can examine it's network config which uses kubenet
#https://docs.microsoft.com/en-us/azure/aks/ssh#configure-virtual-machine-scale-set-based-aks-clusters-for-ssh-access  ...
NODENAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl debug node/$NODENAME -it --image=mcr.microsoft.com/aks/fundamental/base-ubuntu:v0.0.11

#check out the routes, notice the route to the local pod network matching PodCIDR for this node sending traffic to ..
#the routes for the other PodCIDR ranges on the other nodes are implemented in the cloud's virtual network
route 
# in azure, these route are implemented as route tables assigned to the virtual machine's for your nodes
#you'll find the routes implemented in the resource group as a route table assigned to the subnet the nodes are on 
#this is a link to my azure account, you's will vary 
#https://portal.azure.com/#@nocentinohotmail.microsoft.com/resource/subscriptions/fd0c5e48-eea6-4b37-a076-0e23e0df

#check out the eth0, actual node interface ip , then cbr0 which is the bridge the pods are attached to and 
#has an ip on the pod network
#each pod has an veth interface on the bridge,which you see here, and and interface inside the container 
#wich will haave the pod ip 
ip addr 

#let's check out the bridge's 'connections'
sudo apt-get install bridge-utils
sudo brctl show 

#exit the ssh session to the node 
exit 

#here is the pod's interface and it's ip 
#this interface is attached to the cbr0 bridge on the node to get access to the pod network 
PODNAME=$(kubectl get pods -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $PODNAME -- ip addr 
#and inside the pod, ther's a default route in the pod to the interface 10.244.0.1 wich is the bridge interface cbr0
#then the node will route it on the node network for reachability to other nodes 
kubectl exec -it $PODNAME -- route 

#delete the deployment in aks,switch to the local cluster and delete the deployment too
kubectl delete -f deployment.yaml
kubectl config use-context kubernetes-admin@kubernetes
kubectl delete -f deployment.yaml 





























