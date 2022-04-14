# demo 1 - creating a daemonSet on all nodes
#we get one pod per node to run network services on that node 
kubectl get nodes
kubectl get daemonsets --namespace kube-system kube-proxy

#let's create a daemonset with pods on each node in our cluster ...that's not the master
kubectl apply -f DaemonSet.yaml
################### DaemonSet.yaml ######################
apiVersion: apps/v1
kind: DaemonSet 
metadata:
    name: hello-world-ds
spec:
    selector:
        matchLabels:
            app: hello-world-app
    template:
        metadata:
            labels:
                app: hello-world-app
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
####################################################################""
#so we'll get three since we have 3 workers and 1 mater in our cluster and the master is set to run only system pods
kubectl get daemonsets
kubectl get daemonsets -o wide
kubeclt get pods -o wide 
#callout, labels, desired/current nodes scheduled .pod status and template and events 
kubectl describe daemonsets hello-world | more 
#each pods is created with our label, app=hello-world, controller-revision-hash and a pod-template-generation
kubectl get pods --show-labels 

#if we change the label to one of our Pods ...
MYPOD=$(kubectl get pods -l app=hello-world-app | grep hello-world | head -n 1 | awk {'print $1'})
echo $MYPOD
kubectl label pods $MYPOD app=not-hello-world --overwrite

#we'll get a new pod from the daemonset controller
kubectl get pods --show-labels 
#let's clean up this daemonSet
kubectl delete daemonsets hello-world-ds
kubectl delete pods $MYPOD 

#demo 2 - creating a daemonSet on a subset of nodes 
#let's create a daemonSet with a defined nodeSelector 
kubectl apply -f DaemonSetWithNodeSelector.yaml
################## DaemonSetWithNodeSelector.yaml ##############""
apiVersion: apps/v1
kind: DaemonSet 
metadata:
    name: hello-world-ds
spec:
    selector:
        matchLabels:
            app: hello-world-app
    template:
        metadata:
            labels:
                app: hello-world-app
        spec:
            nodeSelector:
              node: hello-world-ns
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
#no pods created because we don't have any nodes with the appropriate label
kubectl get daemonsets 

##we need a node that satisfies the node selector
kubectl label node node1 node=hello-world-ns

#let's see if a pod gets created...
kubectl get daemonsets 
kubectl get daemonsets -o wide
kubectl get pods -o wide 
#what's going to happen if we remove the label 
kubectl label node node1 node-

#it's going to terminate the pod ,ewamine events, desired number of nodes scheduled ...
kubectl describe daemonsets hello-world-ds 
# clean up our demo 
kubectl delete daemonsets hello-world-ds 


#######################################################################################################
# demo3 -  updating a daemonset
# deploy our v1 daemonset again
kubectl apply -f daemonSet.yaml

#check out our image version 1.0
kubectl describe daemonsets hello-world 


# examine what our update strategy is ... defaults to rollingUpdate and maxUnavailable 1
kubectl get DaemonSet hello-world-ds -o yaml | more 
#Update our container image from 1.0 to 2.0 and apply the config 
diff DaemonSet.yaml DaemonSet-v2.yaml
kubectl apply -f DaemonSet-v2.yaml
############ DaemonSet-v2.yaml ################
apiVersion: apps/v1
kind: DaemonSet 
metadata:
    name: hello-world-ds
spec:
    selector:
        matchLabels:
            app: hello-world-app
    template:
        metadata:
            labels:
                app: hello-world-app
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:2.0

########################################################################
# check on the status of our rollout , a touch slower than a deployment due to maxUnavailable 
kubectl rollout status daemonsets hello-world-ds

#we can see our daemonset container image is now 2.0 and in the events it rolled out 
kubectl describe daemonsets

#we can see the new controller-revision-hash and also an updated popd-template-generation
kubectl get pods --show-labels 
# time to clean up our deamos 
kubectl delete daemonsets hello-world-ds
