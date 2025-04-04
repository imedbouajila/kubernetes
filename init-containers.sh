########### init-containers.yaml#######
apiVersion: v1
kind: Pod
metadata: 
    name: init-containers
spec: 
    initContainers:
    - name: init-service
      image: ubuntu
      command: ['sh', '-c', "echo waiting for service; sleep 2"]
    - name: init-database
      image: ubuntu
      command: ['sh', '-c', "echo waiting for database; sleep 2"]
    containers:
    - name: app-container
      image: nginx

#################################
#create the pod with 2 init containers...
#each init container will be processed serially until completion before the main application container is started 
kubectl apply -f init-containers.yaml

#review the init-containers section and you will see each init container state is 'terminated ans completed' and the
#looking at events...you should see each init container starting,serially...
#and then the application container starting last once the others have completed
kubectl describe pods init-containers | more 

#delete the pod
kubectl delete -f init-containers.yaml