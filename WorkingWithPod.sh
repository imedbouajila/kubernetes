kubectl exec -it pod1 --container container1 -- /bin/bash
kubectl logs pod1 --container container1
#check acess
kubectl port-forward pod pod1 localport:containerPort
=======================================================
#start up kubectl get envents --watch and background it
kubectl get envents --watch &
#create a pod..we can see the sceduling,container pulling and container starting
kubectl apply -f pod.yaml
#start a deployment with 1 replica.we see the deployment created,scaling the replicaset and the replicaset start
kubectl apply - deployment.yaml
#scale deployment to 2 replicas.we see the scaling the replicaset and the replicaset starting the second pod
kubectl scale deployment hello-word --replicas=2
#we start with the replica set scaling to 1,then pod deletion,then the pod killing the container
kubectl scale deployment hello-world --replicas=1

kubectl get pods

#let's use exec a command inide our container, we can see the get and post api requests through the api server to 
kubectl -v 6 exec -it pod-name -- /bin/sh
ps 
exit 
#let's look at the running container/pod from the process level on a node
kubectl get pods -o wide
ssh node1
ps -aux | grep hello-world
exit
#now ,let's access our pod's application directly without a service and also off the pod network
kubectl port-forward pode-name 80:8080
#let's do it again, but this time with a non-privileged port
kubectl port-forward pod-node_name 8080:80 &
#we can point curl to localhost ans kubectl port-forward will send the traffic through the api server to the pod
curl http://localhost:8080
#kill our port forward session
fg 
ctrl+c 
kubectl delete deployment hello-world 