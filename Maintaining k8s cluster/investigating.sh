#not: this restore process is for a locally hosted etcd running in a static pod.
#if you need more information on more advanced restor scenarios such as an external cluster check out :
#https://github.com/etcd-io/etcd/blob/master/Documentation/op-guide/recovery.md#restoring-a-cluster

#check out some of the key etcd configuration information 
#container image and tag, command, --data dir, and mounts and volumes for both etcd-certs and etcd-data 
kubectl describe pod etcd-master -n kube-system 

#the configuration for etcd comes from the static pod manifest,check out the listen-client-urls, data-dir ,volumeMount 
sudo more /etc/kubernetes/manifest/etcd.yaml 

#you can get the runtime values from ps -aux
ps -aux | grep etcd 

#let's get etcdctl on our local system here ...by downloading it from github 
#todo: update release to match your release version !!!
#we can find out the version of etcd we're running by using etcd --version inside the etcd pod 
kubectl exec -it etcd-master -n kube-system -- /bin/sh -c 'ETCDCTL_API=3 /usr/local/bin/etcd --version' | head 
export RELEASE="3.4.3"
wget https://github.com/etcd-io/etcd/releases/download/v${RELEASE}/etcd-v${RELEASE}-linux-amd64.tar.gz 
tar -zxvf etcd-v${RELEASE}-linux-amd64.tar.gz 
cd etcd-v${RELEASE}-linux-amd64
sudo cp etcdctl /usr/local/bin 

#quick chek to see if we have etcdctl...
ETCDCTL_API=3 etcdctl --help | head 

#First, let's create a secret that we're going to delete and then get back when we run the restore 
kubectl create secret generic test-secret \
    --from-literal=username='svcaccount' \
    --from-literal=password='S0mthingS0Str0ng!'


#define a variable for the endpoint to etcd 
ENDPOINT=https://127.0.0.1:2379

#Verify we're connecting to the right cluster...define your endpoints and keys 
sudo ETCDCTL_API=3 etcdctl --endpoints=$ENDPOINT \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    member list 

#take the backup saving it to /var/lib/dat-backup.db...
#be sure to copy that to remote storage when doing this for real 
sudo ETCDCTL_API=3 etcdctl --endpoints=$ENDPOINT \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    snapshot save /var/lib/data-backup.db 

#read the metadata from backup/snapshot to print out the snapshot's status 
sudo ETCDCTL_API=3 etcdctl --write-out=table snapshot status /var/lib/dat-backup.db 

#now let's delete an object and then run a restore to get it back 
kubectl delete secret test-secret  

#run the restor to a second folder...this will restore to the current directory 
sudo ETCDCTL_API=3 etcdctl snapshot restore /var/lib/data-backup.db 

#confirm our data is in the restore directory 
sudo ls -l 
#move the old etcd data to a safe location 
sudo mv /var/lib/etcd /var/lib/etcd.OLD 
#restart the static pod for etcd ...
#if you kubectl delete it will not restart the static pod as it's managed by the kubelet not a controller or the con..
sudo docker ps | grep k8s_etcd_etcd
CONTAINER_ID=$(sudo docker ps | grep k8s_etcd_etcd | awk '{print $1}')
echo $CONTAINER_ID

#STOP THE ETCD CONTAINER FROM OUR ETCD POD AND MOVE OUR RESTORED DATA INTO PLACE 
sudo docker stop $CONTAINER_ID 
sudo mv ./default.etcd /var/lib/etcd 
#wait for etcd to get restarted 
sudo docker ps | grep etcd 

#if our secret back ?
kubectl get secret test-secret 


##Another common restore methode is to update data-path to the restored data path in the static pod manifest
#the kubelet will restart the pod due to the configuration change 

#let's delete an object again then run a restore to get back 
kubectl delete secret test-secret 

#using the same backup from earlier
#run the restore to a define data-dir, rather than the current working directory 
sudo ETCDCTL_API=3 ectdctl snapshot restore /var/lib/data-backup.db --data-dir=/var/lib/etcd-restore 

#Update the static pod manifest to point to that /var/lib/etcd-restore...in three places 
#Update 
#      - --data-dir=/var/lib/etcd-restore
# ....
#   volumeMounts:
#   - mountPath= /var/lib/etcd-restore
# ....
#   volumes:
#   - hostPath:
#       name: etcd-data
#       path: /var/lib/etcd-restore
sudo cp /etc/kubernetes/manifests/etcd.yaml 
sudo vi /etc/kubernetes/manifests/etcd.yaml

#this will cause the control plane pods to restart ...let's check it at the container runtume level 
sudo docker ps 
#is our secret back ?
kubectl get secret test-secret 

#remove etcdctl from the master ,node if you want 

