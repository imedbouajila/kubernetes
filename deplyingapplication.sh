#log into the control plane node
ssh master

#deploying resources imperatively in your cluster
#kubectl create deployment, creates a deployment with one replica in it
#this is pulling a simple helloword --image=gcr.io/google-samples/hello-app:1.0

kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0

#but lest's deploy a single "bare" pod that's not managed by a controller...
kubectl run hello-world-pod --image=gcr.io/google-samples/hello-app:1.0
#let's see of the deployment creats a single replicas and also see if that bare pod is created 
#you should have tow pods here...
#- the one managed by our controller has a the pod template hash in it's name and a unique identifier
#- the bare pod
kubectl get pods
kubectl get pods -o wide

#remember k8s is a container orchestrator and it's starting up containers on nodes
#open a second terminal ansd ssh in to the node that hello-word pod is running on
ssh node1

#when containerd is your container runtime,use crictl to get a listing of the containers runnig
#check out this for more details https://kubernetes.io/docs/tasks/debug-appllication-cluster/crivtl
sudo crictl --runtime-endpoint unix://run/containerd/containerd.sock ps

#when docker is your contaianer runtime use
sudo docker ps
exit

#back on master node ,we can pull the logs from the container.which is going to be anything written to stdout
#maybe somthing went wrong inside our app and our pod win't start this is useful for troubelshooting
kubectl logs hello-world-pod

#starting a process inside a container inside a pod
#we can use this to launch any process as long as the executable/binary is in the container
#launch a shell into the container callout that this is on the *pod* network
kubectl exec -it hello-world-pod -- /bin/sh
hostname
ip addr

#remember that first kubectl create deployment we executed, it created a deployment for us
#let's look more closely at that deployment
#deployments are made of replicaSets create pods!
kubectl get deployment hello-world
kubectl get replicaset
kubectl get pods

#let's take a closer look at our deployment and it's pods
#name, replicas and events, in events notice how the replicaset is created by the deployment
#deployments are made of replicasets!
kubectl describe deployment hello-world | more

#the replicaset creates the pods ...check out ...name ,controlled by, replicas,pod templatte,and events
#in events, notice how the replicaset create the pods 
kubectl descirbe replicaset hello-world | more

#check out the name,node,status,controlled by,ips, containers, and events 
#in events, notice how the pod is scheduled, the container image is pulled 
#and then the container is created and then started 
kubectl describe pod hello-world-[tab][tab] | more
 
#for a deep dive into deployments check out managing kubernetes conrollers and deployments
#https://www.pluralsight.com/courses/managing-kubernetes-controllers-deployments


#expose the deployment as a service .this will create a service for the deployment
#we are exposing our service on port 80, connecting to an application running on 8080 in our pod
#port: internal cluster port,the service's port.you will point cluster resources here
#targetport: hte pod's service port, your application.that one we defined when started the pods

kubectl expose deployment hello-world \
	--port=80 \
	--target-port=8080
#check out the cluster-ip and port, that's where we'll access this service,from inside the cluster
kubectl get service hello-world

#we can aslo get that information from using describe
#endpoints are ip:port pairs for each of pods that that are a member of the service
#right now there is only one ...later we'll increase the number of replicas and more endpoints will be added
kubectl describe service hello-world

#access the service inside the cluster
curl http://$SERVICEIP:$PORT

#access a single pod's application directly,useful for troubleshooting
kubectl get endpoints hello-world
curl http://$ENDOINT:$TARGETPORT

#using kubectl to generate yaml or json for your deployments
#this includes runtime information...which can be useful for monitoring and config managment
#but not as source mainifests for declarative deployments 
kubectl get deployment hello-world -o yaml | more
kubectl get deployment hello-world -o json | more

#let's remove everything we created imperatively and start over using a declarative model
#deleting the deployment will delete the replicaset and then the pods 
#we have to deletea the bare pod manually since it's not managed by a controller
kubectl get all
kubectl delete service hello-world
kubectl delete deployment hello-world
kubectl delete pod hello-world
kubectl get all



















































































































