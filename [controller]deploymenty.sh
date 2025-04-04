# log into the master to drive these demos 
# inside the kube-system namespace there's a collection of controllers supporting parts of the cluster's control plan
# how'd they get started since ther's no cluster when they need to come online ? static pod manifests
kubectl get --namespace kube-system all 
# let's look more closely at one of those deployments, requiring 2 pods up and running at all times
kubectl get --namespace kube-system deployments coredns
# daemonset pods run every node in the cluster by default, as new nodes are added these will be deployed to the 
# there's a pod for our pod network , calico ansd one for the kubeproxy
kubectl get --namespace kube-ystem daemonset
###############################################################
#demo 2 creating a deployment imperatively with kubectl create,
#you have lot's of options available to you such as image, container ports, ans replicas
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0
kubectl scale deployment hello-world --replicas=5
#these two commands can be combined into one command if needed 
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0 --replicas=5
#checkout the status of our deployment 
kubectl get deployment 
#now let's delete that and move towords declarative configuration
kubectl delete deployment hello-world 
#### let's start off declaratively creating a deployment with a service 
kubectl apply -f deployment.yaml
######## deployment.yaml #########
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: hello-world
spec:
    replicas: 5
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
---
apiVersion: v1
kind: Service 
metadata:
    name: hello-world
spec:
    selector:
        app: hello-world
    ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
################################################################
#check out the status of our deployment,wich creates the replicaSet which creates our Pods 
kubectl get deployments hello-world
#the first replica set created in our deployment which has the responsability of keeping
#of maintaining the desired state of our application but starting and keeping 5 pods online 
#in the name of the replicaset is the pod-template-hash
kubectl get replicasets
#the actual pods as part of this replicaset, we know these pods belong to the replicaset because of the 
#pod-template-hash in the name 
kubectl get pods
#but also by looking at the 'controlled by' property
kubectl describe pods | head -n 15
#it's the job of the deployment-controller to maintain state.let's look at it a litte closer 
#the selector defines which pods are a membre of this deoployment
#replicaset define the current state of the deployment we'll dive into what each one of these means later in the course
#in events you can see the creation and scaling of the replicaset to 5
kubectl describe deployment
#remove our resources
kubectl delete deployment hello-world
kubectl delete service hello-world 

################################## deploy a replicaset with matchExpressions
kubectl apply -f deployment-me.yaml
################ deployment-me.yaml ########################################
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: hello-world
spec:
    replicas: 5
    selector:
        matchLabels:
            - key: app
              operator: In 
              values: 
               - hello-world-pod-me
    template:
        metadata:
            labels:
                app: hello-world-pod-me
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              ports:
              - containerPort: 8080
---
apiVersion: v1
kind: Service 
metadata:
    name: hello-world
spec:
    selector:
        app: hello-world
    ports:
    - port: 80
      protocol: TCP
      targetPort: 8080

#########################################################################
#check on the status of our replicaset
kubectl get replicaset
# lest's look at the selector for this one...and the labels in the pod template
kubectl describe replicaset hello-world

#demo2 - deleting  a pod in areplicaset, application will self-heal itself
kubectl get pods
kubectl delete pods hello-world-[tab][tab]
kubectl get pods 

#demo 3 - Isolating a Pod from a ReplicaSet 
#For more coverage on this see, managing the kubernetes API Server and Pod - Module 2 -Managing objects with labeles 
kubectl get pods --show-labels 
#Edit the labels on one of the Pod in the ReplicaSet, the replicaset controller will create a new pod 
kubectl label pod hello-world-[tab][tab] app=DEBUG --overwrite
kubectl get pods --show-labels 

# demo 4 - Taking over an existing pod in a replicaset, relabel that pod to bring 
# it back into pod the scope of the replicaset...what's kubernetes going to do ?
kubectl label pod hello-world-[tab][tab] app=hello-world-pod-me --overwrite
# one pod will be termineted, since it will maintain the desired number of replicas at 5
kubectl get pods --show-labels 
kubectl describe ReplicaSets 

# demo 5 - Node failures in ReplicaSets
#shutdown a node 
ssh node3
sudo shutdown -h now 
#node3 status will go notready ...takes about 1 minute
kubectl get nodes --watch 
#but there's a pod still on node3 ..wut?

#kubernetes is protecting against issues .assumes the pod is still running...
kubectl get pods -o wide 
#start up node3 break out of watch when node reports ready , takes about 15 seconds
kubectl get nodes --watch
#that pod that was on node3 goes to status error then it will be restarted on that node 
kubectl get pods -o wide 
#it will start the container back up on the node3 ...see restarts is now1 ,takes about 10 seconds 
#the pod didn't get rescheduled, it's still therer, the container restart policy restarts the container which 
#starts at 10 seconds and defaults to always .we covered this in deatail in my course "managing the kubernetes api and .."
kubectl get pods -o wide --watch
#shutdown a node again...
ssh node3
sudo shutdown -h now

#let's set a watch and wait ...about 5 minutes and see what kubernetes will do 
#because of the -pod-eviction-timeout duration setting on the kube-controller-manager, this pod will get killed after ...
kubectl get pods --watch 

#orphaned pod goes terminating and a new pod will be deployed in the cluster
#if the node returns the pod will be deleted, if the node does not we'll have to delete it 
kubectl get pods -o wide 

#let's clean up 
kubectl delete deployment hello-world 
kubectl delete service hello-waorld 
#and go start node3  back up again :)


################################################################################3
#######################################################################
#########################################################
########################################
###########################

# Updating a deployment object 
kubectl set image deployment hello-world hello-world=hello-app:2.0
kubectl set image deployment hello-world hello-world=hello-app:2.0 --record
kubectl edit deployment hello-world 
kubectl apply -f hello-world-deployment.yaml --record
######## demo 1- updating a deployment and checking our rellout status 
# let's start off with rolling out v1
kubectl apply -f deployment.yaml
#### deployment.yaml ###########
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: hello-world
spec:
    replicas: 10
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
---
apiVersion: v1
kind: Service 
metadata:
    name: hello-world
spec:
    selector:
        app: hello-world
    ports:
    - port: 80
      protocol: TCP
      targetPort: 8080 

###############################################################
# check the status of the deployment 
kubectl get deployment hello-world 
#now let's apply that deployment, run both this and line 18 at the same time 
kubectl apply -f deployment.v2.yaml
#### deployment.v2.yaml ###########
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: hello-world
spec:
    replicas: 10
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
            # version of image beckome 2 
              image: gcr.io/google-samples/hello-app:2.0
              ports:
              - containerPort: 8080
---
apiVersion: v1
kind: Service 
metadata:
    name: hello-world
spec:
    selector:
        app: hello-world
    ports:
    - port: 80
      protocol: TCP
      targetPort: 8080 
#let's check the status of that rollout, while the command blocking your deployment is in the processing status 
kubectl rollout status deployment hello-world 
#Expect a return code of 0 from kubectl rellout status ...that's how we know we 're in the complete status 
echo $?

#let's walk through the description of the deployment...
#check out replicas, conditions and events oldReplicaSet (will only be populated during a rollout) and newReplicaSet
#conditions (more informations about objects state):
#   available   true    minimumReplicasAvailable
#   progressing true    newReplicaSetAvailable (when true, deployment is still progressing or complete)
kubectl describe deployments hello-world 
#both replicasets remain, and that will become very useful shortly when we use a rollback
kubectl get replicaset
#the newreplicaSet check out labels ,replicas, status and pod-template-hash
kubectl describe replicaSet hello-world-54875c5d5c
# the oldReplicaSet, check out labels , replicas , status and pod-template-hash
kubectl describe replicaset hello-world-5646fcc96b

#### demo 2.1 - updating to a non-existent image 
#delete any current deployments, because we're interested in the deploy state changes 
kubectl delete deployment hello-world
kubectl delete service hello-world 
# create our v1 deployment , then update it to v2
kubectl apply -f deployment.yaml
kubectl apply -f deployment.v2.yaml

#observe behavior since new image wasn't available, the replicaset doesen't go below maxUnavailable
kubectl apply -f deployment.broken.yaml
################### deployment.broken.yaml #################
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: hello-world
spec:
    progressDeadlineSeconds: 10
    replicas: 10
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
            # name of image beckome ap 
              image: gcr.io/google-samples/hello-ap:2.0
              ports:
              - containerPort: 8080
---
apiVersion: v1
kind: Service 
metadata:
    name: hello-world
spec:
    selector:
        app: hello-world
    ports:
    - port: 80
      protocol: TCP
      targetPort: 8080 
###############################################################################      
#why isn't this finishing...?after progressDeadlineSeconds which we set to 10 seconds(defaults to 10 minutes)
kubectl rollout status deployment hello-world 
#Eexpect a return code of 1 from kubectl rollout status ...that's how we knnow we're in the failed status 
echo $?
#lest's check out Pods, ImagePullBackoff/ErrImagePull..ah an error in our image definition
#also, it stopped the rollout at 5, that's kind of nice isn't it ?
#and 8 are online, let's look at why 
kubectl get pods 
#what is maxUnavailable ?25%..so only two pod in the ORIGINAL ReplicaSet are offline and 8 are online 
#what is maxSurge ? 25% so we have 13 total pods , or 25% in addition to desired number
#look at replicas and OldReplicaSet 8/8 and NewReolicaSet 5/5
#   Available    True   MinimumReplicasAvailable
#   Progressing  False  ProgressDeadLineExceeded
kubectl describe deployments hello-world
#let's sort this out now ...check the rollout history, but which revision should we rollback to ?
kubectl rollout history deployment hello-world 
#it's easy in this exemple, but could be harder for complex systems
#let's look at our revision annotation, should be 3
kubectl describe deployments hello-world | head
#we can also look at the changes appplied in each revision to see the new pod templates 
kubectl rollout history deployment hello-worold --revision=2
kubectl rollout history deployment hello-worold --revision=3
#let's undo pour rollout to revision 2 , which is our v2 container
kubectl rollout undo deployement hello-world --to-revision=2
kubectl rollout status deployment hello-world 
echo $?
#we 're back to desired of 10 and 2 new pod where deployed using the previous deployment Replicas/Container Image
kubectl get pods 
#let's delete this deployment and start over with a new deployment 
kubectl delete deployment hello-world 
kubectl delete service hello-world 


#Exmaine deployment.probes-1.yaml,review strategy settings,revisionhistory,and readinessProbe setting

## QUICKLY run these two commands or as one block ##
# demo 3 controlling the rate and update strategy of a deployment update
#let's deploy a deployment with readiness Probes
kubectl apply -f deployment.probes-1.yaml --record
##################### deployment.probes-1.yaml #########################################################
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: hello-world
spec:
    replicas: 20
    strategy:
        type: RollingUpdate
        rollingUpdate:
            maxUnavailable: 10%
            maxSurge: 2
    revisionHistoryLimit: 20
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
              readinessProbe: 
                httpGet:
                    path: /index.html 
                    port: 8080
                initialDelaySeconds: 10
                periodSeconds: 10
---
apiVersion: v1
kind: Service 
metadata:
    name: hello-world
spec:
    selector:
        app: hello-world
    ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
#########################################################################""
#Available is still 0 because of our Readiness Probe's initialDelaySeconds is 10 seconds
#Also look there's a new annotation for our change -cause
#And check the conditions 
# progressing ture newReplicaSetCreated or replaSetetUpdated - depending on the state 
#Availabele FALSE  minimumReplicaUnavailable
kubectl describe deployment hello-world 

#check again, Replicas and Conditions , all should be online and ready
# available true minimumReplicasAvailable
# progressing true newReplicaSetAvailable 
kubectl describe deployment hello-world 

#let's update from v1 to v2 with readiness probes controlling the rellout, and record our rellout 
diff deployment.probes-1.yaml deployment.probes-2.yaml
kubectl apply -f deployment.probes-2.yaml --record 
##################### deployment.probes-2.yaml #################""
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: hello-world
spec:
    replicas: 20
    strategy:
        type: RollingUpdate
        rollingUpdate:
            maxUnavailable: 10%
            maxSurge: 2
    revisionHistoryLimit: 20
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
            # version of image changed
              image: gcr.io/google-samples/hello-app:2.0
              ports:
              - containerPort: 8080
              readinessProbe: 
                httpGet:
                    path: /index.html 
                    port: 8080
                initialDelaySeconds: 10
                periodSeconds: 10
---
apiVersion: v1
kind: Service 
metadata:
    name: hello-world
spec:
    selector:
        app: hello-world
    ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
###############################################################
kubectl get replicaset
#check again , Replicas and Conditions
#Progressing is now ReplicaSetUpdated, will change to NewReplicaSetAvailable when it's Ready
#NewReplicaSet is this current RS, oLDRedpllicaset is populated during a rollout , otherwise it's <none>
#we used the update strategy setting of max unavailable and max surge to slow this rollout down
#this update takes about a minute to rollout
kubectl describe deployment hello-world 
#let's update again , but i 'm not going to tell you what i changed , we 're going to troubelshoot it together
kubectl apply -f deployment.probes-3.yaml --record

#we stall at 4 out of 20 replicas updated ...let's look
kubectl rollout status deployment hello-world 
#let's check the status of the deployment, replicas and conditions 
#22 total (20 original + 2 max surge)
#18 available (20 original -2 (10%) in the old RS)
#4 univailable (only 2 pods in the old RS are offline, 4 in the new RS are not READY)
#available  true    minimumReplicaAvailable
#Progressing    true    ReplicaSetUpdated
kubectl describe deployment hello-world 

#let's look at our replicaSets, no Pods in the new RS 67844877b6 are Ready , but 4 our deployed
#that RS with desired 0 is from our v1 deployment ,18 is from our v2 deployment 
kubectl get replicaset
#ready ...that sounds familiar, let's check the deployment again
#what keeps a pod from reporting ready? a readiness probe...see that readiness probe, wrong port ;)
kubectl describe deployement hello-world 

#we can read the deployment's rollout history, and see our change-cause annotations
kubectl rollout history deployment hello-world
#let's rollback to revision 2 to undo that change ...
kubectl rollout history deplooyment hello-world --revision=3
kubectl rollout history deplooyment hello-world --revision=2
kubectl rollout undo deplooyment hello-world --to-revision=2

#and check out our deployment to see if we get 20 ready replicas
kubectl describe deployment | head
kubectl get deployment 
#####################################################################################

#Restarting a deployment.createa fresh deployment so we have easier to read logs
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0 --replicas=5

#check the status of the deployment 
kubectl get deployment 

#let's restart a deployment 
kubectl rollout restart deployment hello-world 
#you get a new replicaset and the pods in the replicaset are shutdown and the new replicaset are started up
kubectl describe deployment hello-world 
#all new pods in the replicaset 
kubectl get pods 
#clean up from this demo
kubectl delete deployment hello-world 

##################################################
#demo 1 - creating and scaling a deployment 
#lets start off imperatively creating a deployment and scaling it ...
#to create a deployment , we need kubectl create deployment 
kubectl create deployment hello-world --image =gcr.io/google-samples/hello-app:1.0

#check out the status of our deployment, we get 1 replica
kubectl get deployment hello-world 

#let's scale our deployment from 1 to 10 replicas 
kubectl scale deployment hello-world --replicas=10

#check out the status of our deployment, we get 10 replicas
kubectl get deployment hello-world
#but we're going to want use declarative deployment in yaml, so let's delete this 
kubectl delete deployment hello-world 

#deploy our deployment via yaml, look inside deployment.yaml first
kubectl apply -f deployment.yaml
##################### deployment.yaml #################""
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: hello-world
spec:
    replicas: 10
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
---
apiVersion: v1
kind: Service 
metadata:
    name: hello-world
spec:
    selector:
        app: hello-world
    ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
###############################################################

#check the status of our deployment 
kubectl get deployment hello-world 

#apply a modified yaml file scaling from 10 to 20 replicas
diff deployment.yaml deployment.20replicas.yaml
kubectl apply -f deployment.20replicas.yaml
























