#Accessing information with jsonpath 
#create a workload and scale it 
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0
kubectl scale deployement hello-world --replicas=3
kubectl get pods -l app=hello-world 
#we're working with the json output of our objects, in this case pods 
#let's start by accessing that list of pods, inside items 
#look at the items, find the metadata and name sections in the json output
kubeclt get pods -l app=hello-world -o json > pods.json 
#it's a list of objects, so let's display the pod names 
kubectl get pods -l app=hello-world -o jsonpath='{.items[*].metadata.name}' # -l = labels 

#display all pods names, this will put the new line at the end of the set rather then on each object output to screen 
#additional tips on formatting code in the examples below including adding a new line after each object 
kubectl get pods -l app=hello-world -o jsonpath='{.items[*].metadata.name}{"\n"}'

#it's a list of objects , so let's display the first (zero'th) pod from the output 
kubectl get pods -l app=hello-world -o jsonpath='{.items[0].metadata.name}{"\n"}'

#get all container images in use by all pods in all namespaces 
kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image}{"\n"}'

#filtring a specific value in a list 
#let's say there's an list inside items and you need to access an element in that list ...
# ?() - defines a filter
# @ - the current object 
kubectl get nodes master -o json | more 
kubectl get nodes -o jsonpath="{.items[*].status.addresses[?(@.type=='InternalIP')].address}"

#sorting 
#use the --sort-by parameter and define which field you want to sort on.it can be any field in the object
kubectl get pods -A -o jsonpath='{.items[*].metadata.name}{"\n"}' --sort-by=.metadata.name 

#now that we're sorting that output, maybe we want a listing of all pods sorted by a dield that's part of the 
#object but not part of the default kubectl output. like creationTimestamp and we want to see what that value is 
#we can use a custom colume to output object field data, in this case the creation timestamp
kubectl get pods -A -o jsonpath='{.items[*].metadata.name}{"\n"}'  \
    --sort-by=.metadata.creationTimestamp \
    --output=custom-columns='NAME:metadata.name,CREATIONTIMESTAMP:metadata.creationTimestamp'

#clean up our resources 
kubectl delete deployment hello-world 





