###########container-probes.yaml###########
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world
spec:
    replicas: 1
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
              livenessProbe: 
                tcpSocket:
                  port: 8081
                initialDelaySeconds: 10
                periodSeconds: 5
              readinessProbe:
                httpGet:
                  path: /
                  port: 8081
                initialDelaySeconds: 10
                periodSeconds: 5

#####################################################################
# we have a single container pod app in a deployment that has both a liveness probe and a readness probe
more container-probes.yaml
#send in our deployment after 10 seconds our liveness and readiness probes will fail
#the liveness probe will kill the current pod and create one 
kubectl apply -f container-probes.yaml

#kill our watch
fg 
ctr+c
#we can see that our container isn't ready 0/1 and it's restarts are increasing
kubectl get pods
#let's figure out what's wrong
#1. we can see in the events. the liveness probe failures
#2. under containers, livenrss and readiness, we can see the current configuration and the current probe configuration
#3. under containers; ready and container conditions we can see that the container isn't ready
#4. our container port is 8080 that's what we want our probe probings.
kubectl describe pods
#so let's go ahead and change the probes to 8080
vi container-probes.yaml
#and send that change into the api server for this deployment 
kubectl apply -f container-probes.yaml
# confirm our probe are pointing to the correct coantainer port now which is 8080
kubectl describe pods

#let's check our status a couple of things happened there
#1. our deployment replicaSet created a new pod 
#2. it's not immediately ready because of our initialDelaySeconds which is 10 seconds
#3. if we wait long enough the livenessprobe will kill the original pod and it will go away
#4. leaving us with one pod in our deployment'replicaset
kubectl get pods

kubectl delete deployment hello-world

####################################################
#let's start up a watch on kubectl get events 
kubectl get events --watch &
clear

#create our deployment with a faulty startup probe ....
#you'll see failures since the startup probe is looking for 8081
#but you won't see the liveness or readiness probe executed
#the container will be restarted after 1 failures failurethreshold defaults to 3 ...this can take up to 30 seconds
#the container restrat policydefault is always ...so it will restart
kubectl apply -f container-probes-startup.yaml
#do you see any container restarts? you should see 1
kubectl get pods
#change the startup probe from 8081 to 8080
kubectl apply -f container-probes-startup.yaml
#########container-probes-startup.yaml##########
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world
spec:
    replicas: 1
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
              startupProbe:
                tcpSocket:
                  port: 8081
                initialDelaySeconds: 10
                periodSeconds: 5
                failureThreshold: 1              
              livenessProbe: 
                tcpSocket:
                  port: 8080
                initialDelaySeconds: 10
                periodSeconds: 5
              readinessProbe:
                httpGet:
                  path: /
                  port: 8080
                initialDelaySeconds: 10
                periodSeconds: 5

##################################################################
kubectl delete -f container-probes-startup.yaml





