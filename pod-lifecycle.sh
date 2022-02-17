#start up kubectl get events --watch and background it
kubectl get events --watch &
clear
#create a pod ...we can see the scheduling,container pulling and containr starting
kubectl apply -f pod.yaml
#we 've used exec to lunch a shell before,but we can use it to launch any program inside a container
#let's use killall to kill the hello-aps process inside our container
kubectl exec -it hello-world-pod -- /bin/sh
ps 
exit
#we still our kubectl get events running in the background,so we see if re-create the contaiiiner automaticlly
kubectl exec -it hello-world-pod -- /usr/bin/killall hello-app
#our restart count increased by 1 after the container needed to be restarted
kubectl get pods
#look at containers->state, last state, reason, exit code,restart count and events
#this is because the container restart policy is always by default 
kubectl describe pod hello-world-pod
#cleanup time
kubectl delete pod hello-world-pod
#kill our watch
fg
ctrl+c 
#remember ...we can ask api server what it knows about an object. in this case our restartpolicy
kubectl explain pod.spec.restartpolicy
#create our pods with the restart policy
more pod-restart-policy.yaml
kubectl apply -f pod-restart-policy.yaml
#check to ensure both pods are up and running we can see the restarts is 0
kubectl get pods
#let's kill our apps in our pods and see how thhe container restart policy reacts
kubectl exec -it hello-world-never-pod -- /usr/bin/killall hello-app 
######## pod-restart-policy.yaml ###########
apiVersion: v1
kind: Pod
metadata:
    name: hello-world-onfailure-pod
spec:
    containers:
    - name: hello-world
      image: gcr.io/google-samples/hello-app:1.0
    restartPolicy: OnFailure 
---
apiVersion: v1
kind: Pod
metadata:
    name: hello-world-never-pod
spec:
    containers:
    - name: hello-world-never-pod
      image: gcr.io/google-samples/hello-app:1.0
    restartPolicy: Never

###############################################################""
kubectl get pods
#review container state, reason,exit code ready and contitions ready containerready
kubectl describe pod hello-world-never-pod
#let's use killall to terminate the process inside our container
kubectl exec -it hello-world-onfailure-pod -- /usr/bin/killall hello-app
#we'll see 1 restart on the pod with the OnFailure restart policy
kubectl get pods
#let's kill our app again, with the same signal
kubectl exec -it hello-world-onfailure-pod -- /usr/bin/killall hello-app
#check its status which is now error too... why? the backoff
kubectl get pods 
#let's check the events, we hit the backoff loop 10 second wait then it will restart
#also check out state and last state
kubectl describe pod hello-world-onfailure-pod
#check its status should be running...after the backoff timer expires
kubectl get pods
#now let's look at our pod statuses
kubectl delete pod hello-world-never-pod
kubectl delete pod hello-world-onfailure-pod




