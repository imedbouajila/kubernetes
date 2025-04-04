#get the metrics Server deployment manifest from github, the release versin may change 
#https://github.com/kubernetes-sigs/metrics-server
wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml 

#add these two lines to metrics server's container args, around line 90
# - --kubelet-insecure-tls
# - --kubelet-preferred-address-types=InternalIP,Hostname 

#deploy the manifest for the metrics server 
kubectl apply -f components.yaml 
######################  components.yaml ############################

###################################################################
#is the Metrics server running ?
kubectl get pods --namespace kube-system 

#let's test it to see if it's collecting data, we can get core information about memory and cpu
#this can take a second...
kubectl top nodes 

#if you have any issues check out the logs for metric server...
kubectl logs --namespace kube-system -l k8s-app=metrics-server 

#let's check the perf data for pods, bu there's no pods in the default namespace 
kubectl top pods 
#we can look at our system pods, CPU and memeory 
kubectl top pods --all-namespaces 

#let's deploy a pod that will burn a lot of CPU, but single threaded we have two vCPUs IN OUR NODES 
kubectl apply -f cpuburner.yaml 

#and create a deployment and scale it 
kubectl create deployment nginx --image=nginx
kubectl scale deployment nginx --repliacas=3

#are our pods up running?
kubectl get pods -o wide 

#how about that CPU now, one of the nodes should about 50% CPU, one should be 1000m+ recall 1000m = 1vCPU 
#we can see the resource allocations across the nodes in terms of CPU and memory 
kubectl top nodes 

#let's get the perf across all pods...it can take a second after the deployments are create to get data 
kubectl top pods 

#we can use labels and selectors to query subsets of pods
kubectl top pods -l app=cpuburner 

#and we have primitive sorting, top CPU and top memory consumers across all Pods 
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory 

#now, that cpuburner, let's look a little more closely at it we can ask for perf for the containers inside a pod 
kubectl top pods --containers 

#clean up our resources 
kubectl delete deployment cpuburner 
kubectl delete deployment nginx

#delete the Metrics servevr and it's configuration elements 
kubectl delete -f components.yaml 


