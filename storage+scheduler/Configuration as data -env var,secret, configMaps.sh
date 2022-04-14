#demo 1 - Passing Configuration into Containers using Environment Variables
#Create two deployments, one for a database system and the other our application
#i'm putting a little wait in there so the pods are created one after the other.
kubectl apply -f deployment-alpha.yaml
################ deployment-alpha.yaml #############
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-alpha
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-alpha 
    template:
        metadata:
            labels:
                app: hello-world-alpha
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              env:
              - name: DATABASE_SERVERNAME
                value: "sql.example.local"
              - name: BACKEND_SERVERNAME
                value: "be.example.local"
              ports:
                - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata: 
    name: hello-world-alpha
spec:
    selector:
        app: hello-world-alpha
    ports:
        - protocaol: TCP
          port: 80
          targetPort: 8080
    type: ClusterIP                     
############################################################################
sleep 5
kubectl apply -f deployment-beta.yaml 
############ deployment-beta.yaml ############################################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-beta
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-beta 
    template:
        metadata:
            labels:
                app: hello-world-beta
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              env:
              - name: DATABASE_SERVERNAME
                value: "sql.example.local"
              - name: BACKEND_SERVERNAME
                value: "be.example.local"
              ports:
                - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata: 
    name: hello-world-beta
spec:
    selector:
        app: hello-world-beta
    ports:
        - protocaol: TCP
          port: 80
          targetPort: 8080
    type: ClusterIP
#############################################################################
#let's look at the services 
kubectl get service
# now let's get the name of one of our pods 
PODNAME=$(kubectl get pods | grep hello-world-alpha | awk '{ print $1 }' | head -n 1)
echo $PODNAME
#inside the pod, let's read the env variables from our container
#notice the alpha information is there but not the beta information. since beta wasn't defined when the pod started 
kubectl exec -it $PODNAME -- /bin/sh
printenv | sort
exit
#if you delete the pod and it gets recreated, you will get the variables for the alpha and beta service information
kubectl delete pod $PODNAME
#get the new pod name and check the env var ...the variables are define at pod/container startup
PODNAME=$(kubectl get pods | grep hello-world-alpha | awk '{ print $1 }' | head -n 1)
kubectl exec -it $PODNAME -- /bin/sh -c "printenv | sort"

#if we delete our service and deployment
kubectl delete deployment hello-world-beta
kubectl delete service hello-world-beta 

#the env vars stick arnound ...to get a new set , the pod need to be recreated 
kubectl exec -it $PODNAME -- /bin/sh -c "printenv | sort" 

#Let's clean up after our demo
kubectl delete -f deployment-alpha.yaml 

#########################################################################
    ############################################################
        ###############################################
#demo 1 - Creating and accessing Secrets
#generic - Create a secret from a local file , directory or literal value
# they keys and values are case sensitive
kubectl create secret generic app1 \
    --from-literal=USERNAME=app1login \
    --form-literal=PASSWORD='s0methings@String!'
#Opaque means it's an arbitrary user defined key/value pair.Data 2 means two key/value paire in the secret
#Other types include service accounts and container registry authentication info
kubectl get secrets 
#app1 said it had 2 data elements, let's look
kubectl describe secret app1
#if we need to access those at the command line ...
#these are wrapped in bash expansion to add a newline to output for readability
echo $(kubectl get secret app1 --template={{.data.USERNAME}} )    
echo $(kubectl get secret app1 --template={{.data.USERNAME}}  | base64 --decode )

echo $(kubectl get secret app1 --template={{.data.PASSWORD}} )    
echo $(kubectl get secret app1 --template={{.data.PASSWORD}}  | base64 --decode )

#demo 2 - accessing secrets inside a pod 
#as environment variables
kubectl apply -f deployment-secrets-env.yaml
#################### deployment-secrets-env.yaml ########################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-secrets-env 
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-secrets-env 
    template:
        metadata:
            labels:
                app: hello-world-secrets-env 
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              env:
              - name : app1username # env var name 
                valueFrom:
                    secretKeyRef:
                        name: app1
                        key: USERNAME
              - name : app1password
                valueFrom:
                    secretKeyRef:
                        name: app1
                        key: USERNAME
              ports:
                - containerPort: 8080
#############################################################################
PODNAME=$(kubectl get pods | grep hello-world-secrets-env | awk '{ print $1 }' | head -n 1)
echo $PODNAME
#now let's get our environment variables from our container
#our environment variables from our pod spec are defined 
#notice the alpha information is there but not the beta information.since beta wasn't defined when the pod started
kubectl exec -it $PODNAME -- /bin/sh
printenv | grep ^app1 
exit

#accessing Secret as files
kubectl apply -f deployment-secrets-files.yaml
###################### deployment-secrets-files.yaml ###################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-secrets-files 
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-secrets-files 
    template:
        metadata:
            labels:
                app: hello-world-secrets-files 
        spec:
            volumes:
                - name: appconfig
                  secret:
                    secretName: app1 
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              ports:
                - containerPort: 8080
              volumeMounts:
                - name: appconfig
                 mountPath: "/etc/appconfig"
###########################################################################
#grab our pod name into a variable 
PODNAME=$(kubectl get pods | grep hello-world-secrets-files | awk '{ print $1 }' | head -n 1)
echo $PODNAME
#looking more closely at the pod we see volumes, appconfig and in Mounts..;
kubectl describe pod $PODNAME
#let's access a shell on the pod 
kubectl exec -it $PODNAME -- /bin/sh 
#now we see path we defined in the volumes part of the pod spec 
ls /etc/appconfig
cat /etc/appconfig/USERNAME
cat /etc/appconfig/PASSWORD
exit
#if you need to put a subset of the keys in a secret check out this line here and look at times
#https://kubernetes.io/docs/concepts/storage/volumes#secret

#let's clean up after our demos ....
kubectl delete secret app1 
kubectl delete deployment hello-world-secrets-env
kubectl delete deployment hello-world-secrets-files

#create a secret with encoded values, preferred over clear text
echo -n 'app2login' | base64
echo -n 's0methings@String!' | base64

#############################################################################
    ##############################################################
        #############################################
# demo 1 - pulling a container from a Private container Registrey 
#to create a private repository in a container registry, follow the directions here 
#https://doc.docker.com/docker-hub/repos/#private-repositories

#let's pull down a hello-world image from gcr
sudo ctr images pull gcr.io/google-samples/hello-app:1.0

#let's get a listing of images from ctr to confirm our image is downloaded
sudo ctr images list 

#Tagging our image in the format your registry, image and tag
#you'll be using your own repository , so update that information here 
# source_ref: gcr.io/google-samples/hello-app:1.0   #this is the image pulled from gcr
# target_ref: docker.io/noncentino/hello-app:ps # this is the image you want to push into your private repo
sudo ctr images tag gcr.io/google-samples/hello-app:1.0 docker.io/noncentino/hello-app:ps

#now push that locally tagged image into our private registry at docker hub
#you'll be using your own repository, so update that information here and specify your $USERNAME
#you will be prompted for the password to your repository 
sudo ctr images push docker.io/noncentino/hello-app:ps --user $USERNAME

#create our secret that we'll use for our image pull ...
#update the parametres to match the information for your repository including the servername,username,password and email
kubectl create secret docker-registry private-reg-cred \
    --docker-server=https://index.docker.io/v2/ \
    --docker-username=$USERNAME \
    --docker-password=$PASSWORD \
    --docker-email=$EMAIL 

#Ensure the image doesn't exist on any of our nodes...or else we can get a false positive since our image would be created
#caution. this will delete *ANY* image that begins with hello-app
ssh devops@node1 'sudo ctr --namespace k8s.io image ls "name~=hello-app" -q | sudo xargs ctr --namespace k8s.io image rm'
ssh devops@node2 'sudo ctr --namespace k8s.io image ls "name~=hello-app" -q | sudo xargs ctr --namespace k8s.io image rm'
ssh devops@node3 'sudo ctr --namespace k8s.io image ls "name~=hello-app" -q | sudo xargs ctr --namespace k8s.io image rm'

#Create a deployment using imagePullSecret in the pod spec
kubectl -f deployment-private-registry.yaml 
########################### deployment-private-registry.yaml #####################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-private-registry 
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-private-registry 
    template:
        metadata:
            labels:
                app: hello-world-private-registry  
        spec:
            containers:
            - name: hello-world
              image: noncentino/hello-app:ps
              ports:
                - containerPort: 8080
            imagePullSecrets:
            - name: private-reg-cred 
####################################################################
#check out containers and events section to ensure the container was actually pulled 
#this is why i made sure they were deleted from each node above 
kubectl describe pods hello-world 

#clean up after our demo, remove the images from node1 
kubectl delete -f deployment-private-registry.yaml
kubectl delete secret private-reg-cred
sudo ctr images remove docker.io/noncentino/hello-app:ps
sudo ctr images remove gcr.io/google-samples/hello-app:1.0

#################################################################
    ##################################################
        ######################################

#demo 1 - creating ConfigMaps
#Create a PROD ConfigMap
kubectl create configmap appconfigprod \
    --from-literal=DATABASE_SERVERNAME=sql.example.local \
    --from-literal=BACKEND_SERVERNAME=be.example.local


#create a QA ConfigMap
#we can source our ConfigMap from files or from directories
#if no key, then the base name of the file 
#otherwise we can specify a key name to allow for more complex app configs and access to specific configuration elements
more appconfigqa
################# appconfigqa ###############
DATABASE_SERVERNAME="sqlqa.example.local"
BACKEND_SERVERNAME="beqa.example.local"
#############################################
kubectl create configmap appconfigqa \
    --from-file=appconfigqa 
#each creation methode yeilded a different structure in the ConfigMap
kubectl get configmap appconfigprod -o yaml
kubectl get configmap appconfigqa -o yaml

#demo 2 - using ConfigMaps in pod Configuration 
#first as environment variables 
kubectl apply -f deployment-configmaps-env-prod.yaml 
###################### deployment-configmaps-env-prod.yaml ###################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-configmaps-env-prod 
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-configmaps-env-prod 
    template:
        metadata:
            labels:
                app: hello-world-configmaps-env-prod  
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              envFrom:
                - ConfigMapRef:
                    name: appconfigprod
              ports:
                - containerPort: 8080
##############################################################################
#let's see or configured environment variables 
PODNAME=$(kubectl get pods | grep hello-world-configmaps-env-prod | awk '{print $1}' | head -n 1)
echo $PODNAME

kubectl exec -it $PODNAME -- /bin/sh 
printenv | sort 
exit 

#second as files 
kubectl apply -f deployment-configmaps-files-qa.yaml 
######################## deployment-configmaps-files-qa.yaml ################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-configmaps-files-qa 
spec:
    replicas: 1
    selector:
        matchLabels:
            app: hello-world-configmaps-files-qa  
    template:
        metadata:
            labels:
                app: hello-world-configmaps-files-qa   
        spec:
            volumes
                - name: appconfig
                  ConfigMap:
                    name: appconfigqa
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              ports:
                - containerPort: 8080
              volumeMounts:
                - name: appconfig
                  mountPath: "etc/appconfig"  
#########################################################################
#let's see or configmap exposed as a file using the key as the file name  
PODNAME=$(kubectl get pods | grep hello-world-configmaps-files-qa | awk '{print $1}' | head -n 1)
echo $PODNAME

kubectl exec -it $PODNAME -- /bin/sh 
ls /etc/appconfig
cat /etc/appconfig/appconfigqa  
exit 

#Our configMap key , was the filename we read in , and the values are inside the file 
#this is how we can read in whole files at a time and present them to the file system with the same name in one confiMap 
#so think about using this for daemon configs like nginx,redis...etc
kubectl get configmap appconfigqa -o yaml 

#Updating a configMap 
kubectl edit configmap appconfigqa

kubectl exec -it $PODNAME -- /bin/sh 
watch cat /etc/appconfig/appconfigqa  
exit

#cleaning up our demo
kubectl delete deployment hello-world-configmaps-env-pod
kubectl delete deployment hello-world-configmaps-files-qa
kubectl delete configmap appconfigprod
kubectl delete configmap appconfigqa 
