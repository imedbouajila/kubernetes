#1. iNVESTIGATION The cluster DNS Service 
#it's deployed as a Service in the cluster with a deployment in the kube-system namespace 
kubectl get service --namespace kube-system 

#two replicas, args injecting the location of the config file which is backed by ConfigMap mounted as a volume 
kubectl describe deployment coredns --namespace kube-system | more 

#the configmap defining the CoreDNS configuration and we can see the default forwarder is /etc/resolv.conf
kubectl get configmaps --namespace kube-system coredns -o yaml | more

#2. Configuring CoreDNS to use custom Forwarders, space not tabs!
#Defaults use the nodes DNS Servers for forwarders
#replaces forward 1.1.1.1
#add a conditional domain forwarder for a specific domain 
#ConfigMap will take a second to update the mapped file and the config to be reloaded
kubectl apply -f CoreDNSConfigCustopm.yaml --namespace kube-system
######################## CoreDNSConfigCustopm.yaml ######################
apiVersion: v1
kind: ConfigMap
metadata:
    name: coredns
    namespace: kube-system
data:
    Corefile: |
        .:53 {
            errors
            health
            ready
            kubernetes cluster.local in-addr.arpa ip6.arpa {
                pods insecure
                fallthrough in-addr.arpa ip6.arpa
                ttl 30
            }
            prometheus :9153
            forward . 1.1.1.1
            cache 30
            loop
            reload
            loadbalance 
        }
        centinosystems.com {
            forward . 9.9.9.9
        }
#########################################################################
#How will we know the core dns configuration file is updated in the pod ?
#you can tail the log looking for the reload the configuration file ...this can take a mminute ot two
#also look for any errors post configuration 
kubectl logs --namespace kube-system --selector 'k8s-app=kube-dns' --follow

#run some DNS  queries against the kube-dns service cluster ip to ensure everything works ...
SERVICEIP=$(kubectl get service --namespace kube-system kube-dns -o jsonpath='{.spec.clusterIP}')
nslookup www.pluralsight.com $SERVICEIP
nslookup www.centinosystems.com $SERVICEIP 

#on master, let's put the default configuration back, using. forward /etc/resolv.conf
kubectl apply -f CoreDNSConfigDefault.yaml --namespace kube-system
###########################CoreDNSConfigDefault.yaml#################################
apiVersion: v1
kind: ConfigMap
metadata:
    name: coredns
    namespace: kube-system
data:
    Corefile: |
        .:53 {
            errors
            health
            ready
            kubernetes cluster.local in-addr.arpa ip6.arpa {
                pods insecure
                fallthrough in-addr.arpa ip6.arpa
                ttl 30
            }
            forward . /etc/resolv.conf            
            prometheus :9153
            cache 30
            loop
            reload
            loadbalance 
        }
        centinosystems.com {
            forward . 9.9.9.9
        }
##################################################################################

#3. Configuring Pod DNS client Configuration 
kubectl apply -f DeploymentCustomDns.yaml 
###########################  DeploymentCustomDns.yaml###############################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world-customdns 
spec:
    replicas: 3
    selector:
        matchLabels:
            app: hello-world-customdns 
    template:
        metadata:
            labels:
                app: hello-world-customdns  
        spec:
            containers:
            - name: hello-world
              image: gcr.io/google-samples/hello-app:1.0
              ports:
              - containerPort: 8080
            dnsPolicy: "None"
            dnsConfig: 
                nameservers:
                    - 9.9.9.9
---  
apiVersion: v1
kind: Service
metadata:
    name: hello-world-customdns 
spec:   
    selector:
        app: hello-world-customdns
    ports:
    - port: 80
      protocol: TCP
      targetPort: 80 
#####################################################################################
#let's check the DNS configuration of a Pod created with that configuration 
#this line will grab the first pod matching the defined selector
PODNAME=$(kubectl get pods --selector=app=hello-world-customdns -o jsonpath='{.item[0].metadata.name}')
echo $PODNAME
kubectl exec -it $PODNAME -- cat /etc/resolv.conf 

#clean up our resources
kubectl delete -f DeploymentCustomDns.yaml 

#demo 3 -let's get a pods DNS a record and a services a record 
#create a deployment and a service 
kubectl apply -f deployment.yaml 
######################################################################
########################### deployment.yaml ###############################
apiVersion: apps/v1
kind: Deployment
metadata:
    name: hello-world
spec:
    replicas: 3
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
#get the pods and their IP addresses 
kubectl get pods -o wide 
#get the address of our DNS service again...just in case
SERVICEIP=$(kubectl get service --namespace kube-system kube-dns -o jsonpath='{.spec.clusterIP}')

#For one of the pods replace the dots in the IP address with dashes for exemple 192.168.206.68 becomes 192-168-206-68
#we'll look at some additional exemples of service discovery in the next module too 
nslookup 192-168-206-124.default.pod.cluster.local $SERVICEIP 

#our services also get DNS  a recods 
#there's more on service a records in the next demo 
kubectl get service 
nslookup hello-world.default.svc.cluster.local $SERVICEIP 

#clean up our resources 
kubectl delete -f deployment.yaml 
  
#todo for the viewer...you can use this technique to verify your dns forwarder configuration from the first demo in ...
#recreate the custom configuration by applying the custom configmap defined in CoreDNSConfigCustom.yaml
#logging in CoreDNS will log the query, but not which forwarder it was sent to 
#we can use tcpdump to listen to the packets on the wire to see where the DNS queries are being sent to 

#find the name of a node running one of the dns pods running...so we're going to observe DNS queries there.
DNSPODNODENAME=$(kubectl get pods --namespace kube-system --selector=k8s-app=kube-dns -o jsonpath='{.items[0].spec.}')
echo $DNSPODNODENAME

#let's log into that node running the dns pod and start a tcpdump to watch our dns queries in action 
#you interface (-i) name may be different 
ssh devops@DNSPODNODENAME 
sudo tcpdump -i ens33 port 53 -n 
#in a second terminal , let's test our DNS configuration from a pod to make sure we're using the configured forwarder
#when this pod starts, it will point to our cluster dns service 
#install dnsutils for nslookup and dig 
ssh devops@node1 
kubectl run -it --rm debian --image =debian
apt-get update && apt-get install dnsutils -y 

#in our debian pod let's look at the dns config and run two test DNS queries 
#the nameserver will be your cluster dns service cluster ip 
#we'll query two domains to generate traffic for our tcpdump 
cat /etc/resolv.conf
nslookup www.pluralsight.com
nslookup www.centinosystems.com

#switch back to our second terminal and review the tcpdump, config each  query is going to the correct forwarder
#here is some exemple output...www.pluralsight.com is going to 1.1.1.1 and www.centinosystem.com is going to 9.9.9.9
#172.16.94.13.63841 > 1.1.1.1.53: 24753+ A? www.pluralsight.com. (37)
#172.16.94.13.42523 > 9.9.9.9.53: 29485+ [1au] A? www.pluralsight.com. (63)

#exit the tcpdump
ctrl+c 







