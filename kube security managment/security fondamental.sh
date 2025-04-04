# Investigating certificate based authenticatiion 
#we're using certificates to authenticate to our cluster 
#our certificate information is stored in the .kube/config 
#kubectl reads the credentials and sends the api request on to the api server 
kubectl config view 
kubectl config view --raw 

#let's read the certificate information out of our kubernetes file 
#look for subject: CN= is the username which is kubernetes-admin, it's also in the group (o=) system:masters 
kubectl config view --raw -o jsonpath='{ .users[*].user.client-certificate-data}' | base64 --decode > admin.crt 
openssl x509 -in admin.crt -text -noout | head 

#we can use -v 6 to see the api request, and return code which is 200
kubectl get pods -v 6 

#clean up files no longer needed 
rm admin.crt 

##########################################################################################################
#2 - working with service accounts 
#getting service accounts information 
kubectl get serviceaccounts

#a service account can contain image pull secrets and also mountable secrets, notice the mountable secrets name 
kubectl describe serviceaccounts default 

#here is the secret associated with the default service account and a token which can be  used for authentication to 
#if you don't define a service account in you pod spec, this service account is used in the pod 
#there is one default service account per namespace 
#pods can only access service accounts in the same namespace 
kubectl describe secret default-token-8fb46 # <-- change this to your default service account name 

#create a service accounts 
kubectl create serviceaccount mysvcaccount1

#this new service account will get it's own secret 
kubectl describe serviceaccounts mysvcaccount1 

#Create a workload, this uses the defined service account mysericeaccount
kubectl apply -f nginx-deployment.yaml
kubectl get pods 
#################### nginx-deployment.yaml #################
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: nginx
    labels:
        app: nginx
spec:
    replicas: 1
    selector:
        matchLabels:
            app: nginx
    template:
        metadata:
            labels:
                app: nginx
        spec:
            serviceAccount: mysvcaccount1
            containers:
            - image: nginx
              name: nginx
############################################################
#you can see the pod spec gets populated with the serviceaccount.if we didn't specify one ,it would get the default 
#use serviceAccountName as serviceAccount is deprecated
PODNAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[*].metadata.name}')
kubectl get pod $PODNAME -o yaml 

#the secret is mounted in the pod. see volumes and mounts 
kubectl describe pod $PODNAME

######################################################################
#3- Accessing the API server inside a pod 
#let'see haw the secret is available inside the pod 
PODNAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[*].metadata.name}')
kubectl exec $PODNAME -it -- /bin/bash 
ls /var/run/secrets/kubernetes.io/serviceaccount/
cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
cat /var/run/secrets/kubernetes.io/serviceaccount/token 

#load the token and secret into variables for reuse 
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

#you're abel to authenticate to the API server with the user ... and retrieve some basic and safe information from the 
#see this link for more details on API discovery roles: https://kubernetes.io/reference/access-authn-authz/rbac
curl --cacert $CACERT -x GET https://kubernetes.default.svc/api/
curl --cacert $CACERT --header "Authorization: Bearer $TOKEN" -X GET https://kubernetes.default.svc/api 

#But it doesn't have any permissions to access objects...this user is not authorized to access pods 
curl --cacert $CACERT --header "Authorization: Bearer $TOKEN" -X GET https://kubernetes.default/svc/api/v1/namespaces



























