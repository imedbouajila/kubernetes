#demo 1 - finding sheduling information
#let's create a deployment with three replicas 
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
#pods spread out evenly across the Nodes due to our scoring functions for selector spread during scoring 
kubectl get pods -o wide 
#we can look at the pods events to see the scheduler making its choice 
kubectl describe pods 
#if we scale our deployment to 6 ...
kubectl scale deployment hello-world --replicas=6 
#we can see that the scheduler works to keep load even across the nodes 
kubectl get pods -o wide 
#we can see the nodeName populated for this node 
kubectl get pods hello-world-[tab][tab] -o yaml 

#clean up this demo ...and delete its resources 
kubectl delete deployment hello-world  

#######################################################
#demo 2 - Scheduling Pods with resource requests 
kubectl apply -f requests.yaml
######################## requests.yaml ################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-requests
spec:
    replicas: 3
    selector:
        matchLabels:
            app: hello-world-requests 
    template:
        metadata:
            labels:
                app: hello-world-requests  
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              resources:
                requests:
                    cpu: "1"
              ports:
                - containerPort: 8080
##########################################################
#we created three pods, one on each node 
kubectl get pods -o wide 
#let's scale our deployment to 6 replica
kubectl scale deployment hello-world-requests --replicas=6

#we see that the pods are pending...why?
kubectl get pods -o wide 
kubectl get pods -o wide | grep Pending 
#let's look at why the Pod is Pending...check out the pod's events ...
kubectl describe pods 

#now let's look at the node's allocations ...we've allocated 62% of our CPU...
#1 user pod using 1 whole CPU, one system Pod ising 250 millicores of a CPU and
#looking at allocatable resources, we have only 2 whole cores available for use 
#the next pod coming along wants 1 whole core, and tha'ts not available 
#the scheduler can't find a place in this cluster to place our workload...is this good or bad ?
kubectl describe node node1 
#clean up after this demo 
kubectl delete deployment hello-world-requests 

##########################################################################
    ########################################################
        ##############################################
#Demo - using labels to schedule pods to nodes 
#the code is below to experiment with on your own
#course: managing the kubernetes API server and pods 
#Module: managing objects with labels, annotations , and Namespaces 
#Clip : Demo: Services, labels , selectors, and scheduling pods to nodes 

#Demo 1a - using Affinity and Anti-Affinity to shcedule Pods to Nodes 
#let's start off with a deployment of web and cache pods 
#Affinity: we want to have always have a cache pod co-located on a node where we a web Pod 
kubectl apply -f deployment-affinity.yaml 

################### deployment-affinity.yaml ###########
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-web  
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-web 
    template:
        metadata:
            labels:
                app: hello-world-web  
        spec:
            containers:
            - name: hello-world-web
              image: gcr.io/google-samples/hello-app:1.0
              ports:
                - containerPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-cache  
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-cache
    template:
        metadata:
            labels:
                app: hello-world-cache  
        spec:
            containers:
            - name: hello-world-cache
              image: gcr.io/google-samples/hello-app:1.0
              ports:
                - containerPort: 8080
            affinity:
                podAffinity:
                    requiredDuringSchedulingIgnoredDuringExecution:
                    - labelSelector:
                        matchExpressions:
                        - key: app
                          operator: In 
                          values:
                          - hello-world-web 
                       topologyKey: "kubernetes.io/hostname"       
###########################################################################
#let's check out the labels on the nodes, look for kubernetes.io/hostname which
#we're using for our topologykey
kubectl describe nodes node1 | head 
kubectl get nodes --show-labels 

#we can see that web and cache are both on thee name node 
kubectl get pods -o wide 

#if we scale the web deployment 
#we'll still get spread across nodes in the ReplicaSet, so we don't need to enforce that with affinity
kubectl scale deployment hello-world-web --replicas=2
kubectl get pods -o wide 

#then when we scale the cache deployment, it will get scheduled to the same node as the other web server 
kubectl scale deployment hello-world-cache --replicas=2 
kubectl get pods -o wide 

# clean up the resources from these deployments 
kubectl delete -f deployment-affinity.yaml 

########################################################################
#########################################################################
#demo 1b - using anti-affinity
#Now, let's test out anti-affinity, deploy web and cach again 
#but this time we're going to make sure that no more than 1 web pod is on each node with anti-affinity 
kubectl apply -f deployment-antiaffinity.yaml 
kubectl get pods -o wide 
########################### deployment-antiaffinity.yaml #####################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-web  
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-web 
    template:
        metadata:
            labels:
                app: hello-world-web  
        spec:
            containers:
            - name: hello-world-web
              image: gcr.io/google-samples/hello-app:1.0
              ports:
              - containerPort: 8080
            affinity:
                podAntiAffinity:
                    requiredDuringSchedulingIgnoredDuringExecution:
                    - labelSelector:
                        matchExpressions:
                        - key: app
                          operator: In 
                          values:
                          - hello-world-web 
                       topologyKey: "kubernetes.io/hostname"                
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-cache  
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-cache
    template:
        metadata:
            labels:
                app: hello-world-cache  
        spec:
            containers:
            - name: hello-world-cache
              image: gcr.io/google-samples/hello-app:1.0
              ports:
                - containerPort: 8080
            affinity:
                podAffinity:
                    requiredDuringSchedulingIgnoredDuringExecution:
                    - labelSelector:
                        matchExpressions:
                        - key: app
                          operator: In 
                          values:
                          - hello-world-web 
                       topologyKey: "kubernetes.io/hostname" 
#############################################################################################
#now let's scale the replicas in the web and cach deployments
kubectl scale deployment hello-world-web --replicas=4
#One Pod will go Pending because we can have only 1 web Pod per node 
#W  hen using requiredDuringSchedulingIgnoredDuringExecution in our antiaffinity rule
kubectl get pods -o wide --selector app=hello-world-web 

#To 'fix' This we can change the schedulingrule to preferredDuringSchedulingIgnoredDuringExecution
#Also going to set the number of replicas to 4 
kubctl apply -f deployment-antiaffinity-corrected.yaml
########################### deployment-antiaffinity-corrected.yaml #####################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-web  
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-web 
    template:
        metadata:
            labels:
                app: hello-world-web  
        spec:
            containers:
            - name: hello-world-web
              image: gcr.io/google-samples/hello-app:1.0
              ports:
              - containerPort: 8080
            affinity:
                podAntiAffinity:
                    preferredDuringSchedulingIgnoredDuringExecution:
                    - weight: 100
                      podAffinityTerm:        
                        labelSelector:
                            matchExpressions:
                            - key: app
                                operator: In 
                                values:
                                - hello-world-web 
                        topologyKey: "kubernetes.io/hostname"                
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-cache  
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-cache
    template:
        metadata:
            labels:
                app: hello-world-cache  
        spec:
            containers:
            - name: hello-world-cache
              image: gcr.io/google-samples/hello-app:1.0
              ports:
                - containerPort: 8080
            affinity:
                podAffinity:
                    requiredDuringSchedulingIgnoredDuringExecution:
                    - labelSelector:
                        matchExpressions:
                        - key: app
                          operator: In 
                          values:
                          - hello-world-web 
                       topologyKey: "kubernetes.io/hostname" 
#############################################################################################
kubectl scale deployment hello-world-web --replicas=4 

#now we'll have 4 pods up an running, but doesn't the scheduler already ensure replicaset spread? yes!
kubectl get pods -o wide --selector app=hello-world-web 

#let's clean up the resources from this demos 
kubectl delete -f deployment-antiaffinity-corrected.yaml 

#################################################################################################################
#################################################################################################################
#demo 2 - controlling pods placement with taints and tolerations 
#let's add a taint to node1
kubectl taint nodes node1 key=MyTaint:NoSchedule

#we can see the taint at the node level, look at the taints section 
kubectl describe node node1

#let's create a deployment with three replicas 
kubectl apply -f deployment.yaml 
####################### deployment.yaml ########################
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
################################################################
#we can see pods get placed on the non tainted nodes 
kubectl get pods -o wide 
#but we we add a deployment with a Toleration ...
kubectl apply -f deployment-tolerations.yaml
####################### deployment-tolerations.yaml ########################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-tolerations
spec:
    replicas: 3
    selector:
        matchLabels:
            app: hello-world-tolerations 
    template:
        metadata:
            labels:
                app: hello-world-tolerations 
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              ports:
              - containerPort: 8080
            tolerations:
            - key: "key"
              operator: "Equal"
              value: "MyTaint"
              effect: "NoSchedule"  
################################################################
#we can see pods get placed on the non tainted nodes 
kubectl get pods -o wide 

#Remove our Taint
kubectl taint noses node1 key:NoSchedule-

#clean up after our demo 
kubectl delete -f deployment-tolerations.yaml
kubectl delete -f deployment.yaml 

####################################################################################
####################################################################################
# demo 1 - node cordoning 
# let's create a deployment with three replicas 
kubectl apply -f deployment.yaml 
####################### deployment-tolerations.yaml ########################
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
################################################################
#pods spread out evenly across the nodes 
kubectl get pods -o wide 
#let's cordon node3
kubectl cordon node3

#that won't evict any pods ...
kubectl get pods -o wide 

#but if i scale the deployment 
kubectl scale deployment hello-world --replicas=6

# node3 won't get any new pods ...one of the other nodes will get an extra pod here 
kubectl get pods -o wide 
#let's drain (remove) the pods from node3
kubectl drain node3

#let's try that again since daemmonsets (calico, kube-proxy) aren't scheduled we need to work around them 
kubectl drain node3 --ignore-daemmonsets

#now all the workload is on node1 and node2 
kubectl get pods -o wide 
# we can uncordon node3 , but nothing will get scheduled until there's an event like a scaling operation or ...
#somthing that will cause pods to get created 
kubectl uncordon node3

#So let's scale that deployment and see where they get sheduled...
kubectl scale deployment hello-world --replicas=9
#all three get scheduled to the cordoned node 
kubectl get pods -o wide

#clean up this demo ...
kubectl delete deployment hello-world

###############################################################
###############################################################
#demo 2 - Manually scheduling a pod by specifing nodeName
kubectl apply -f pod.yaml
####################### pod.yaml ########################
apiVersion: v1
kind: Pod
metadata:
    name: hello-world-pod
spec:
    nodeName: 'node3'
    containers:
    - name: hello-world
      image: gcr.io/google-samples/hello-app:1.0
      ports:
      - containerPort: 8080
####################################################################
#our pod should be on node3
kubectl get pod -o wide 
#let's delete our pod, since there's no controller it won't get recreated 
kubectl delete pod hello-world-pod 

#now let's cordon node3 again
kubectl cordon node3

#and try to recreate our pod 
kubectl apply -f pod.yaml

#you can still place a pod on the node since the pod isn't getting 'scheduled', status is SchedulingDisabled
kubectl get pod -o wide 
#can't remove the unmanaged popd either since it's not managed by a controller (replicaset,...) and won't get restarted 
kubectl drain node3 --ignore-daemmonsets

#let's clean up our demo, delete our pod and uncordon the node 
kubectl delete pod hello-world-pod 
kubectl uncordon node3