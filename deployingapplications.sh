#deploying resources declaratively in your cluster
#we can use apply to create our resources from yaml
#we could write the yaml by hand ...but we can use dry-run=client to build for us
#this can be used a template for move complex deployments 
kubectl create deployment hello-world \
        --image=gcr.io/google-samples/hello-app:1.0 \
        --dry-run=client -o yaml | more

#let's write this deployment yaml out to file 
kubectl create deployment hello-world \
        --image=gcr.io/google-samples/hello-app:1.0 \
        --dry-run=client -o yaml > deployment.yaml

#the contents of the yaml file show the definition of the deployment 
more deployment.yaml

#create the deployment ...declaratively ...in code
kubectl apply -f deployment.yaml

#generate the yaml for the service 
kubectl expose deployment hello-world \
	--port=80 --target-port=8080\
	--dry-run=client -o yaml | more


#write the service yaml manifest to file  
kubectl expose deployment hello-world \
	--port=80 --target-port=8080\
	--dry-run=client -o yaml > service.yaml

#the contents of the yaml file show the definition of the service
more service.yaml

#create the service declaratively
kubectl apply -f service.yaml

#check out our current state,deployment,replicaset,pod and service
kubectl get all

#scale up our deployment ...in code 
vi deployment.yaml

change spec.replicas from 1 to 20 
		replicas: 20
#update our configuration with apply to make the code to the desired state 
kubectl apply -f deployment.yaml

#and check the current configuration of our deployment...you should see 20/20
kubectl get deployment hello-world
kubectl get pods | more

#repeat the curl acess to see the load balancing of the http request
kubectl get service hello-world 
curl http://$SERVICEIP:PORT

#we can edit the resources "on the fly" with kubectl edit.but this isn't reflected in our yaml
#but this change is persisted in the etcd....cluster store.change 20 to 30
kubectl edit deployment hello-world

#the deeployment is scaled to 30 and we have 30 pods 
kubectl get deployment hello-world 

#you can also scale a deployment using scale
kubectl scale deployment hello-world --replicas=40

#lest's clean up our deployment and move everything
kubectl delete deployment hello-world
kubectl delete service hello-world
kubectl get all
























#






























