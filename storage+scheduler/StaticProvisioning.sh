#demo 0 - NFS Server Overview
ssh devops@c1-storage 

#More details available here : https://help.ubuntu.com/lts/serverguide/network-file-system.html
#install NFS Server and create the directory for our exports
sudo apt install nfs-kernel-server 
sudo mkdir /export/volumes
sudo mkdir /export/volumes/pod
#configure our NFS Export in /etc/export for /export/volumes. using no_root_squash and no_subtree_check to
#allow application to mount subdirectories of the export directly
sudo bash -c 'echo "/export/volumes *(rw,no_root_squash,no_subtree_check)" > /etc/exports'
cat /etc/exports 
sudo systemctl restart nfs-kernel-server.server 
exit
#on each Node in your cluster...install the NFS client.
sudo apt install nfs-common
#on one of the Nodes, test out basic NFS access before moving on
ssh devops@node1
sudo mount -t nfs4 c1-storage:/export/volumes /mnt/
mount | grep nfs 
sudo umount /mnt 
exit 

#demo 1 - Static Provisioning  PV
#Create a PV with the read/write many and retain as the reclaim policy
kubectl apply -f nfs.pv.yaml
################# nfs.pv.yaml ###############################
apiVersion: v1
kind: PersistentVolume
metadata:
    name: pv-nfs-data
spec:
    accessModes:
        - ReadWriteMany
    capacity:
        storage: 10Gi
    persistentVolumeReclaimPolicy: Retain 
    nfs:
        server: 172.16.94.5 # ip of storage server
        path: "/export/volumes/pod"
###########################################################
#review the created resources, status, access mode and reclaim policy is set to reclaim rather than delete
kubectl get PersistentVolume pv-nfs-data    
#look more closely at the PV and it's configuration 
kubectl describe PersistentVolume pv-nfs-data 


## Create a PVC on that PV 
kubectl apply -f nfs.pvc.yaml
############ nfs.pvc.yaml ################
apiVersion: v1
kind: PersistentVolumeClaim 
metadata:
    name: pvc-nfs-data
spec:
    accessModes:
        - ReadWriteMany
    resources: 
        requests: 
            storage: 10Gi
####################################################################
#check the status , now it's bound due to the PVC on the PV .see the claim ...
kubectl get PersistentVolume 
#check the status , bound.
#we defined the PVC it statically provisioned the PV ...but it's not mounted yet.
kubectl get PersistentVolumeClaim pvc-nfs-data 
kubectl describe PersistentVolumeClaim pvc-nfs-data 

#let's create some content on our storage server
ssh devops@c1-storage   
sudo bash -c 'echo "Hello from our NFS mount!!!" > /export/volumes/pod/demo.html'
more /export/volumes/pod/demo.html
exit
#let's create a pod (in a deployment and add a service) with a PVC on pvc-nfs-data
kubectl apply -f nfs.nginx.yaml 
############### nfs.nginx.yaml #################
apiVersion: apps/v1 
kind: deployment    
metadata: 
    name: nginx-nfs-deployment
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
            volumes:
            - name: webcontent
              persistentVolumeClaim:
                claimName: pvc-nfs-data 
            containers:
            - name: nginx
              image: nginx
              ports: 
              - containerPort: 80
              volumeMounts:
              - name: webcontent
                mountPath: "/user/share/nginx/html/web-app" 
---
apiVersion: v1
kind: service
metadata:
    name: nginx-nfs-service 
spec:   
    selector:
        app: nginx
    ports:
    - port: 80
      protocol: TCP
      targetPort: 80 
#######################################################
kubectl get service nginx-nfs-service
SERVERIP=$(kubectl get service | grep nginx-nfs-service | awk '{ print $3 }')

#check to see if our pods are Running before proceeding 
kubectl get pods 
#let's access that application to see our application data ...
curl http://$SERVERIP/web-app/demo.html 
#check the Mounted by output for which Pod(s) are accessing this storage
kubectl describe PersistentVolumeClaim pvc-nfs-data
#if we go 'inside' the pod/container, let's look at where the PV is mounted 
kubectl exec -it nginx-nfs-deployment-[tab][tab] --/bin/bash
ls /usr/share/nginx/html/web-app
exit 

#what node is this pod on ?
kubectl get pods -o wide 

#let's log into that node and look at the mounted volumes...it's the kubelets job to make the device/mount available 
ssh devops@node1
mount | grep nfs
exit 

#let's delete the pod and see if we still have access to our data in our PV 
kubectl get pods 
kubectl delete pods nginw-nfs-deployment-[tab][tab]
#we get a new pod ...but is our app data still there???
kubectl get pods 
#let's access that application to see our application data ...yes
curl http://$SERVERIP/web-app/demo.html


#demo 2 - controlling PV access with access modes and persistentVolumeReclaimPolicy
#scale up the deployment to 4 replicas 
kubectl scale deployment nginx-nfs-deployment --replicas=4

#now let's look at who's attached to the pvc, all 4 pods 
#Oour AccessMode for this PV and PVC is RWX ReadWriteMany
kubectl describe PersistentVolumeClaim 
#NOW WHEN ACCESS our application we're getting load balanced across all the pods hitting the same PV data 
curl http://$SERVERIP/web-app/demo.html 
#let's delete our deployment 
kubectl delete deployment nginx-nfs-deployment 
#check status , still bound on the PV ...why is that ...
kubectl get PersistentVolume 
# because the PVC still exists ...
kubectl get PersistentVolumeClaim 

#can re-use the same PVC and PV from a pod definition ...yes! because i didn't delete the PVC
kubectl apply -f nfs.nginx.yaml
#our app is up and running
kubectl get pods 

#but if i delete the deployment 
kubectl delete deployment nginx-nfs-deployment
#and i delete the PersistentVolumeClaim
kubectl deelete PersistentVolumeClaim pvc-nfs-data

#my status is now Released ...which means no one can claim this PV 
kubectl get PersistentVolume
#but let's try to use it and see what happend, recreate the PVC for this PV

#then try to use PVC:PV in a pod difinition 
kubectl apply -f nfs.nginx.yaml 
#my pod creation is Pending
kubectl get pods 

#as is my PVC status ...pending ... because that PV is released and our Reclaim Policy is Retain 
kubectl get PersistentVolumeClaim
kubectl get PersistentVolume

#need to delete the PV if we xant to 'reuse' that exact PV ... to 're-create' the PV
kubectl delete deployment nginx-nfs-deployment
kubectl delete pvc pvc-nfs-data
kubectl delete pv pv-nfs-data

#if we recreate the pv, pvc and pods.we'll be able to re-deploy
#the clean up of the data is defined by the reclaim policy.(delete will clean up for you useful in dynamic provisioning)
#but in this case, since it's NFS , we have to clean it up and remove the files
#nothing will prevent a uset from getting this access to this data, so it's imperitive to clean up
kubectl apply -f nfs.pv.yaml
kubectl apply -f nfs.pvc.yaml
kubectl apply -f nfs.nginx.yaml
kubectl get pods 

#time to clean up for the next demo 
kubectl delete pv  nfs.pv.yaml
kubectl delete pvc nfs.pvc.yaml
kubectl delete -f nfs.nginx.yaml
#####################################################################################
    ########################################################################
        ###########################################################
############### Dynamic Provisionning in the Cloud ##################################
# demo 0 - AZURE setup
# if you don't have your azure kubernetes Service Cluster available follow the script in CreateAKSCluster.sh

#switch to our azure cluster context 
kubectl config use-context 'k8s-cloud'
kubectl get nodes 

#demo 1 - StorageClass and dynamic Provisionning in the azure 
#let's create a disk in azure.using a dynamic provisioner and storage class
#check out our list of available storage classes, which one is default?wotice the provisioner,parametres and recla..
kubectl get StorageClass
kubectl describe StorageClass default 
kubectl describe StorageClass managed-premium 
#let's create a deployment of an nginx pod with a RWO (readwriteonce) disk
#we create a pvc and a deployment that creates pods that use that pvc
kubectl apply -f AzureDisk.yaml 
################### AzureDisk.yaml ################"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: pvc-azure-managed 
spec:
    accessModes:
    - ReadWriteOnce 
    storageClassName: managed-premium 
    resources:
        requests:
            storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: nginx-azdisk-deployment
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
            volumes:
            - name: webcontent
              persistentVolumeClaim:
                claimName: pvc-azure-managed
            containers:
            - name: nginx
              image: nginx
              ports:
              - containerPort: 80
              volumeMounts
              - name: webcontent
                mountPath: "/user/share/nginx/html/web-app"
##########################################################################
#check out the Access Mode, Reclaim Policy, Status ,Claim and StorageClass
kubectl get PersistentVolume 
#check out the access mode on the PersistentVolumeClaim, status is bound and it's volume is the pv dynamically provisioning
kubectl get PersistentVolumeClaim
#let's see if our single pod was created (the status can take a second to transition to running )
kubectl get pods 
# clean up when we're finished and our context back to our local cluster
kubectl delete deployment nginx-azdisk-deployment
kubectl delete PersistentVolumeClaim pvc-azure-managed

# demo 2 - Defining a custom StorageClass in Azure
kubectl apply -f CustomStorageClass.yaml 
##############  CustomStorageClass.yaml  #############
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
    name: managed-standard-ssd
parametres:
    cachingmode: ReadOnly
    kind: managed
    storageaccounttype: StandardSSD_LRS
provisioner: kubernetes.io/azure-disk 
###################################################################################
#get a list of the current StorageClassesKubectl get StorageClass
kubectl get StorageClass
#a closer look at the SC, you can see the Reclaim Policy is delete since we didn't set it in our StorageClass yaml
kubectl describe StorageClass managed-standard-ssd 

#let's use our new StorageClass
kubectl apply -f AzureDiskCustomStorageClass.yaml
######### AzureDiskCustomStorageClass.yaml ############
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: pvc-azure-standard-ssd 
spec:
    accessModes:
    - ReadWriteOnce 
    storageClassName: managed-standard-ssd  
    resources:
        requests:
            storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment 
metadata:
    name: nginx-azdisk-deployment-standard-ssd
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
            volumes:
            - name: webcontent
              persistentVolumeClaim:
                claimName: pvc-azure-standard-ssd
            containers:
            - name: nginx
              image: nginx
              ports:
              - containerPort: 80
              volumeMounts
              - name: webcontent
                mountPath: "/user/share/nginx/html/web-app"
####################################################################
#and take a closer look at our new storage class, reclaim policy delete
kubectl get PersistentVolumeClaim   
kubectl get PersistentVolume

#clean up our demo resources
kubectl delete deployment nginx-azdisk-deployment-standard-ssd
kubectl delete PersistentVolumeClaim pvc-azure-standard-ssd 
kubectl delete StorageClass managed-standard-ssd

#switch back to our local cluster from Azure 
kubectl config use-context kubernetes-admin@kubernetes 


