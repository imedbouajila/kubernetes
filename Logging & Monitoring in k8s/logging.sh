#1 - Pods 
#check the logs for a single container pod 
kubectl create deployment nginx --image=nginx 
PODNAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
echo $PODNAME 
kubectl logs $PODNAME 

#Clean up that deployment 
kubectl delete deployment nginx 

#let's create a multi-container pod that writes some information to stdout 
kubectl apply -f multiconatainer.yaml   

########################### multiconatainer.yaml ###############################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: loggingdemo
    labels:
        app: loggingdemo
spec:
    replicas: 3
    selector:
        matchLabels:
            app: loggingdemo 
    template:
        metadata:
            labels:
                app: loggingdemo  
        spec:
            containers:
            - name: container1 
              image: busybox
              arge: [/bin/sh, -c, 'while true; do echo "$(date)": $(hostname): container1; sleep 1; done']
            - name: container2 
              image: busybox
              arge: [/bin/sh, -c, 'while true; do echo "$(date)": $(hostname): container2; sleep 1; done']
################################################################################################################
#pods a specific container in a pod and a collection of pods 
PODNAME=$(kubectl get pods -l app=loggingdemo -o jsonpath='{.items[0].metadata.name}')
echo $PODNAME 

#let's get the logs from the multicontainer pod ...this will throw an error and ask us to define which container 
kubectl logs $PODNAME 

#But we need to specify which container inside the pods 
kubectl logs $PODNAME -c container1
kubectl logs $PODNAME -c container2

#we can access all container logs which will dump each containers in sequence 
kubectl logs $PODNAME --all-containers 

#if we need to follow a log, we can do that ...helpful in debugging real time issues
#this works for both single and multi-container pods 
kubectl logs $PODNAME --all-containers --follow
ctrl+c

#for all pods matching the selector, get all the container logs and write it to stdout and then file 
kubectl get pods --selector app=loggingdemo
kubectl logs --selector app=loggingdemo --all-containers 
kubectl logs --selector app=loggingdemo --all-containers > allpods.txt

#also helpful is tailing the bottom of a log ...
#here we're getting the last 5 log entries across all pods matching the selector 
#you can do this for a single container or using a selector
kubectl logs --selector app=loggingdemo --all-containers --tail 5 

#2 - Nodes 
#get key information and status about the kubelet, ensure that it's active/runniing and check oout the log
#also key information about it's configuration is available 
systemctl status kubelet.service 

#If we want to examine it's log further, we journalctl to access it's log from journald
# -u for which systemd unit. if using a pager, use f and b to for forward and back 
journalctl -u kubelet.service 

#journalctl has search capabilities, but grep is likely easier
journalctl -u kubelet.service | grep -i ERROR 

#Time bounding searches can be helpful in finding inssues add --no-pager for line wrapping 
journalctl -u kubelet.service --since today --no-pager 
journalctl -u kubelet.service --since today 

#3 - control plane 
#get a listing of the control plane pods using a selector 
kubectl get pods --namespace kube-system --selector tier=control-plane 
#we can retrieve the logs for the control plane pods by using kubectl logs 
#this info is coming from api server over kubectl 
#it instructs the kubelet will read the log from the node and send it back to your over stdout 
kubectl logs --namespace kube-system kube-apiservevr-master 

#but, what if your control plane is down? go to docker or to the file system 
#kubectl logs will send the request to the local node's kubelet to read the logs from disk 
#since we're on the master/control plane node already we can use docker for that 
sudo docker ps 

#grab the log for the api server pod, paste in the CONTAINER ID
sudo docker ps | grep k8s_kube-apiserver 
CONTAINER_ID=$(sudo docker ps | grep k8s_kube-apiserver | awk '{print $1}')
echo $CONTAINER_ID 

sudo docker logs $CONTAINER_ID

#BUT. what if docker is not available ?
#they're also available on the filesystem, here you'll find the current and the previous logs for the containers
#this is the same across all nodes and pods in the cluster. this also applies to user pods/containers 
#these are json formmatted which is the docker logging driver default 
sudo ls /var/log/containers 
sudo tail /var/log/containers/kube-apiserver-master*

####### 4 - Events 
#show events for all objects in the cluster in the default namespace 
#look for the deployment cration and scaling operations from above ...
#if you don't have any events since they are only around for an hour create a deployment to genereate some 
kubectl get events 

#it can be easier if the data is actually stored...
#sort by isn't for just events, it can be used in most output 
kubectl get events --sort-by='.metadata.creationTimestamp'
#create a flowed deployment 
kubectl create deployment nginx --image ngins  # pour voir l'erreur

#we can filter the list of events using field selector 
kubectl get events --field-selector type=Warning
kubectl get events --field-selector type=Warning, reason=Failed 

#we can also monitor the events as they happen with watch 
kubectl get events --watch &
kubectl scale deployment loggingdemo --replicas=5 

#break out of the watch 
fg 
ctrl+c 

#we can look in another namespace too if needed, deployment,created the replica set, which creadted the pod, then we 
kubectl get events --namespace kube-system 
#these events are also available in the object as part of kubectl describe, in the events section 
kubectl describe deployment nginx 
kubectl describe replicaset nginx-675d6c6f67
kubectl describe pods nginx 

#clean up our resources 
kubectl delete -f multicontainer.yaml 
kubectl delete deployment nginx 

#but the event data is still available from the cluster's events, even though the objects are gone 
kubectl get events --sort-by='.metadata.creationTimestamp' 





 

