#create a collection of pods with labels assinged to each
more CreatePodsWithLabels.yaml
kubectl apply -f CreatePodsWithLabels.yaml

#####CreatePodsWithLabels.yaml####
apiVersion: v1
kind: Pod
metadata:
    name: nginx-pod-1
    labels:
        apps: MyWebApp
        deployment: v1
        tier: prod
spec:
    containers:
    - name: nginx
      image: nginx
      ports:
      - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
    name: nginx-pod-2
    labels:
        apps: MyWebApp
        deployment: v1.1
        tier: prod
spec:
    containers:
    - name: nginx
      image: nginx
      ports:
      - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
    name: nginx-pod-3
    labels:
        apps: MyWebApp
        deployment: v1.1
        tier: qa
spec:
    containers:
    - name: nginx
      image: nginx
      ports:
      - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
    name: nginx-pod-4
    labels:
        apps: MyAdminApp
        deployment: v1
        tier: prod
spec:
    containers:
    - name: nginx
      image: nginx
      ports:
      - containerPort: 80
###############################
#look at all the pod labels in our cluster
kubectl get pods --show-labels 
#look at one pod's labels in our cluster
kubectl describe pod nginx-pod-1 | head
#query labels and selectors
kubectl get pods --selector tier=prod
kubectl get pods --selector tier=qa
kubectl get pods -l tier=prod
kubectl get pods -l tier=prod --show-labels
#selector for multiple labels and adding on sho-labels to see those albels in the output
kubectl get pods -l 'tier=prod,apps=MyWebApp' --show-labels
kubectl get pods -l 'tier=prod,apps!=MyWebApp' --show-labels
kubectl get pods -l 'tier in (prod,qa)'
kubectl get pods -l 'tier notin (prod,qa)'
#output a particular label in column format (additional column in the output)
kubectl get pods -L tier
kubectl get pods -L tier,apps
#edit an existing label
kubectl label pod nginx-pod-1 tier=non-prod --overwrite
kubectl get pod nginx-pod-1 --show-labels
#adding a new label
kubectl label pod nginx-pod-1 another=label
kubectl get pod nginx-pod-1 --show-labels
#removing an existing label
kubectl label pod nginx-pod-1 another-
kubectl get pod nginx-pod-1 --show-labels
#performin an operation on a collection of pods based on a label query
kubectl label pod --all tier=non-prod --overwrite
#delete all pods matching our non-prod label
kubectl delete pod -l tier=non-prod


#kubernetes resource managment
#start a deployment with 3 replicas, open deployment-label.yaml
kubectl apply -f deployment-label.yaml
###########deployment-label.yaml####
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world
    labels:
        app: hello-world
spec:
    replicas: 4
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
####################################################################
#expose our deployement as service ,open service.yaml
kubectl apply -f service.yaml
####service.yaml######
apiVersion: v1
kind: Service
metadata:
  name: hello-world
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: hello-world
#################################################

#look at the labels and selectors on each resourc, the deployment,replicaset and pod
#the deployment has a selector for app=hello-world
kubectl describe deployment hello-world 
#the replicaset has labels and selectors for app and the current pod-template-hash
#look at the pod template and the labels on the pods created 
kubectl describe replicaset hello-world
kubectl get pods --show-labels
#edit the label on one of the pods in the replicaset, change tthe pod-template-hash
kubectl label pod pod-name pod-template-hash=debug --overwrite
kubectl get pods --show-labels
#let's look at how services use labels and selectors,check out services.yaml
kubectl get service
#the selector for this service is app=hello-world, that pos is still being load balanced to!
kubectl describe service hello-world
#get a list of all ips in the service, ther's 5...why?
kubectl describe endpoints hello-world
#get a list of pods and their ips
kubectl get pod -o wide
#to remove a pod from load balancing, change the label used by the service's selector
#the replicaset will respond by placing another pod in the replicaset
kubectl get pods --show-labels 
kubectl label pod pod-name app=debug --overwrite
#look at the registred endpoint add new ther's 4
kubectl describe endpoints hello-world
#delete
kubectl delete deployment hello-world
kubectl delete service hello-world
kubectl delete pod pod-name
#scheduling a pod to a node 
#scheduling is a much deeper topic, we're focusing on how can be used to influence it here
kubectl get nodes --show-labels
#label our nodes with somthing descriptive
kubectl label node node-name disk=local_ssd
kubectl label node node_name hardware=local_gpu
#query our labels to confirm
kubectl get node -L disk,hardware
#CREATE three pods two using nodeselector ,one without
more PodsToNodes.yaml
kubectl apply -f PodsToNodes.yaml 
#######PodsToNodes.yaml######
apiVersion: v1
kind: Pod
metadata:
    name: nginx-pod-ssd
spec:
    containers:
    - name: nginx
      image: nginx
      ports:
      - containerPort: 80
    nodeSelector:
      disk: local_ssd  
---
apiVersion: v1
kind: Pod
metadata:
    name: nginx-pod-gpu
spec:
    containers:
    - name: nginx
      image: nginx
      ports:
      - containerPort: 80
    nodeSelector:
      hardware: local_gpu
---
apiVersion: v1
kind: Pod
metadata:
    name: nginx-pod
spec:
    containers:
    - name: nginx
      image: nginx
      ports:
      - containerPort: 80
#view the sheduling of the pods in the cluster
kubectl get node -L disk,hardware
kubectl get pods -o wide
#clean up when we're finshed,delete our labels and pods 
kubectl label node node-name disk-
kubectl label node node-name hardware-
kubectl delete pod nginx-pod
kubectl delete pod nginx-pod-gpu
kubectl delete pod nginx-pod-ssd



