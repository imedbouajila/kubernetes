#check out 1-ingress-loadbalancer.sh for the cloud demos 

#demo 1 - deploying an ingress controller 
#for our ingress controller, we're going to go with nginx, widely available and easy 
#follow this link here to find a manifest for nginx ingress controller for various ..
#we have to choose a platform to deploy in ...we can choose cloud, bare-metal ..
https://kubernetes.github.io/ingress-nginx/deploy/

#bare-metal: on our on prem cluster: bare metal (nodePort)
#let's make sure we're in the right context and deploy the manifest for the ingress controller afound in the link 
kubectl config use-context kubernetes-admin@kubernetes 
kubectl apply -f deploy.yaml 

#using this manifest, the ingress controller is in the ingress-nginx namespace but 
#it will monitor for ingress in all namespaces by default.if can be scoped to monitor a specific namespace if need 

#check the status of the pods to see if the ingress controller is online 
kubectl get pods --namespace ingress-nginx 
#now let's check to see if the service is online.this of type nodeport, so do you have an EXTERNAL-IP? 
kubectl get services --namespace ingress-nginx 

#check out the ingressclass nginx ...we have not set the is-default-class so in each of our ingress we will need 
#specify an ingressclassname  

kubectl describe ingressclasss nginx 
#kubectl annotate ingressclasses nginx "ingressclass.kubernetes.io/is-default-class=true"

#demo 2 - Single Service 
#create a deployment, scale it to 2 replicas ans expose it as a service 
#this service will be ClusterIP and we'll expose this service via the ingress 
kubectl create deployment hello-world-service-Single --image=gcr.io/google-samlpes/hello-app:1.0
kubectl scale deployment hello-world-service-single --replicas=2 
kubectl expose deployment hello-world-service-single --port=80 --target-port=8080 --type=ClusterIP 

#create a single Ingress routing to the one backend service on the service port 80 listing on all hostnames 
kubectl apply -f ingress-single.yaml 
##################### ingress-single.yaml #########################
apiVersion : networking.k8s.io/v1
kind: Ingress 
metadata:
    name: ingress-single
spec:
    ingressClassName: nginx
    defaultBackend:
        service:
            name: hello-world-service-single
            port:
                number: 80
###################################################################
#get the status of the ingress.it's routing for all host names on that public IP on port 80
#this is a NodePort service so there's no public IP, its the NodePort service that you'll use for access or integratio ..
#If you don't define an ingressclassname and don't have a default ingress class the address won't be updated 
kubectl get ingress --watch #wait for the address to be populated before proceeding 
kubectl get service --namespace ingress-nginx 

#notice the backends are the Service's endpoints ... so the traffic is going straight from the Ingress controller to the service 
#also notice, the default back end is the same service, that's because we didn't define any rules and 
#we just popilated ingress.spec.backend. we 're going to look at rules next ...
kubectl describe ingress ingress-single 

#Access the application via the exposed ingress that's listing the NodePort and it's static port, let's get some ...
INGRESSNODEPORTIP=$(kubectl get ingress ingress-single -o jsonpath='{.status.loadbalancer.ingress[].ip}')
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
echo $INGRESSNODEPORTIP:$NODEPORT

#demo 3 - Multiple Services with path based routing
#let's create two additional services 
kubectl create deployment hello-world-service-blue --image=gcr.io/google-samlpes/hello-app:1.0
kubectl create deployment hello-world-service-red --image=gcr.io/google-samlpes/hello-app:1.0

kubectl expose deployment hello-world-service-blue --port=4343 --target-port=8080 --type=ClusterIP 
kubectl expose deployment hello-world-service-red --port=4242 --target-port=8080 --type=ClusterIP 

#let's create an ingress with paths ech routing to different backend services 
kubectl apply -f ingress-path.yaml 
################ ingress-path.yaml ######################
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: 
    name: ingress-path
spec:
    ingressClassName: nginx
    rules:
        - host: path.example.com
          http:
            paths:
            - path: /red 
              pathType: Prefix
              backend:
                service:
                    name: hello-world-service-red 
                    port:
                        number: 4242
            - path: /blue 
              pathType: Exact
              backend:
                service:
                    name: hello-world-service-blue
                    port:
                        number: 4343
#########################################################
#we now have tow, one for all hosts and the other for our defined host with two paths 
#the ingress controller is implementing these ingresses and we're sharing the one public IP , don't proceed until you ...
#the address populated for your ingress 
kubectl get ingress --watch 

#we can see the hosts, the path and the backend 
kubectl describe ingress ingress-path 

#our ingress on all hosts is still routing to service single, since we're accessing the url with an ip a domain ...
curl http://$INGRESSNODEPORTIP:$NODEPORT 

#our paths are routing to their correct services, if we specify a host header or use a DNS name to access the ingress 
curl http://$INGRESSNODEPORTIP:$NODEPORT/red --header 'Host: path.exemple.com' 
curl http://$INGRESSNODEPORTIP:$NODEPORT/blue --header 'Host: path.exemple.com'

#example Prefix mismatches...these will all match and get routed to red 
curl http://$INGRESSNODEPORTIP:$NODEPORT/red/1 --header 'Host: path.exemple.com' 
curl http://$INGRESSNODEPORTIP:$NODEPORT/red/2 --header 'Host: path.exemple.com'
#example Exact mismatches...these will all 404
curl http://$INGRESSNODEPORTIP:$NODEPORT/Blue --header 'Host: path.exemple.com'
curl http://$INGRESSNODEPORTIP:$NODEPORT/blue/1 --header 'Host: path.exemple.com'
curl http://$INGRESSNODEPORTIP:$NODEPORT/blue/2 --header 'Host: path.exemple.com'

#if we don't specify a path we'll get a 404 while specifying a host header
#we'll need to configure a path and backend for / or define a default backend for the service 
curl http://$INGRESSNODEPORTIP:$NODEPORT/  --header 'Host: path.exemple.com' 

#Add a backend to the ingress listenting on path.exemple.com pointing to the single service 
kubectl apply -f ingress-path-backend.yaml 
################# ingress-path-backend.yaml #################
 apiVersion: networking.k8s.io/v1
 kind: Ingress
 metadata: 
    name: ingress-path
spec:
    ingressClassName: nginx
    rules:
        - host: path.example.com
          http:
            paths:
            - path: /red 
              pathType: Prefix
              backend:
                service:
                    name: hello-world-service-red 
                    port:
                        number: 4242
            - path: /blue 
              pathType: Exact
              backend:
                service:
                    name: hello-world-service-blue
                    port:
                        number: 4343
    defaultBackend:
        service:
            name: hello-world-service-single 
            port:
                number: 80
#############################################################
#we can see the default backend, and in the rules, the host, the path, and the backends
kubectl describe ingress ingress-path 

#now we'll hit the default backend service, singlefor the undefined path 
curl http://$INGRESSNODEPORTIP:$NODEPORT/  --header 'Host: path.exemple.com' 

#demo 4 - name based virtual hosts 
#now, let's route traffic ti the services using named based virtual hosts rather than paths 
kubectl apply -f ingress-namebased.yaml 
######### ingress-namebased.yaml ################
 apiVersion: networking.k8s.io/v1
 kind: Ingress
 metadata: 
    name: ingress-namebased
spec:
    ingressClassName: nginx
    rules:
        - host: red.example.com
          http:
            paths: 
              - pathType: Prefix
                path: "/"
                backend:
                  service:
                    name: hello-world-service-red 
                    port:
                        number: 4242
        - host: blue.example.com
          http:
            paths: 
              - pathType: Prefix
                path: "/"
                backend:                        
                    service:
                        name: hello-world-service-blue
                        port:
                            number: 4343
#################################################
kubectl get ingress --watch #wait for the address to be populated before proceeding 
curl http://$INGRESSNODEPORTIP:$NODEPORT/  --header 'Host: red.exemple.com'
curl http://$INGRESSNODEPORTIP:$NODEPORT/  --header 'Host: blue.exemple.com'

#demo 5 -TLS example
#1 - GENERATE a certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout tls.key -out tls.crt -subj "/C=US/ST=ILLINOIS/L=CHICAGO/O=IT/OU=IT/CN=tls.example.com"

#2 - create a secret with the key and the certificate 
kubectl create secret tls tls-secret --key tls.key --cert tls.crt 

#3 - create an ingress using the certificate and key .this uses https for both / and /red 
kubectl apply -f ingress-tls.yaml 
#################### ingress-tls.yaml ##################################
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: 
    name: ingress-tls 
spec:
    ingressClassName: nginx
    tls: 
    - hosts:
        - tls.example.com 
      secretName: tls-secret
    rules:
        - host: tls.example.com
          http:
            paths:
            - path: / 
              pathType: Prefix
              backend:
                service:
                    name: hello-world-service-single 
                    port:
                        number: 80
#######################################################################
#check the status ... do we have an IP ?
kubectl get ingress --watch #wait for the address to be populated before proceeding 
#test access to the hostname ... we need --resolve because we haven't registred the DNS name 
#tls is a layer lower than host headers, so we have to spicify the correct DNS NAME 
kubectl get service -n ingress-nginx ingress-nginx-controller 
NODEPORTHTTPS=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
echo $NODEPORT

curl https://tls.example.com:$NODEPORTHTTPS/ \
    --resolve tls.example.com:NODEPORTHTTPS:$INGRESSNODEPORTIP \
    --insure --verbose

#clean up from our demo 
kubectl delete ingress ingress-path
kubectl delete ingress ingress-tls 
kubectl delete ingress ingress-namebased 
kubectl delete deployment hello-world-service-single 
kubectl delete deployment hello-world-service-red 
kubectl delete deployment hello-world-service-blue 
kubectl delete service hello-world-service-single
kubectl delete service hello-world-service-red 
kubectl delete service hello-world-service-blue 
kubectl delete secret tls-secret 
rm tls.crt 
rm tls.key 
#delete the ingress, ingress controller and other configuration elements 
kubectl delete -f deploy.yaml 
