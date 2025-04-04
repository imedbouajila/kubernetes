################ troubleshootin - NODES



#run the code in 1-TroubleshootingNodesBreaktuff.sh ... there's a readme inside this file 
#this script will implement a breaking change on each worker node in the cluster 
#you'll need to update the login username for this to work 
sh  ./1-TroubleshootingNodesBreaktuff.sh 'devops'
############## TroubleshootingNodesBreaktuff.sh ##############

##############################################################
#worker Node Troubleshooting scenario 1
#it can take a minute for the node's status to change to NotReady...wait until they are.
#except for the master, all of the Nodes' statuses are NotReady, let's check out why ...
kubectl get nodes 

#remember the master/control plane node still has a kubelet and runs pods...
#so this troubleshooting methodology can apply there 

#let's start troubleshooting nod1 issues
#ssh into node1
ssh devops@node1

#the kubelet runs as a systemd service/unit...so we can use those tools to troubleshoot why it's not working
#let's start by checking the status. add no-pager so it will wrap the text 
#it's loaded, but it's inactive (dead)... so that means it's not running 
#we want the service to be active (running)
#so the first thing to check is the service enabled?
sudo systemctl status kubelet.service 

#if the service wasn't configured to start up by default(disabled) we can use enable to set it to 
sudo systemctl enable kubelet.service 

#that just enables the service to start up on boot, we could reboot now or we can start it manually 
#so let's start it up and see what happens...ah, it's now active (running) which means the kubelet is online 
#we also see in the journald snippet, that it's watching the apiserver.so good stuff there...
sudo systemctl start kubelet.service
sudo systemctl status kubelet.service 

#log out of the node and onto master 
exit 

#back on master, is node1 reporting ready?
kubectl get nodes 

#worker node Troubelshooting scenario 2
ssh devops@node2

#Crashlooping kubelet ...indicated by the code = exited  and the status = 255
#but that didn't tell us why kubelet is crashlooping, just that it is ...let's dig deeper 
sudo systemctl status kubelet.service --no-pager 

#systemd based systems write logs to journald, let's ask it for the logs for the kubelet 
#this tells us exactly what's wrong, the failed to load the kubelet config file 
#which it thinks is at /var/lib/kubelet/config.yaml 
sudo journalctl -u kubelet.service --no-pager 

#let's see what's in /var/lib/kubelet/...ah, look the kubelet wants config.yaml, but we have config.yml 
sudo ls -la  /var/lib/kubelet/ 

#and now fixup that config by renaming the file and restarting the kubelet 
#another option here would have been to edit the systemd unit configuration for the kubelet in /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
#we're going to look at that in the next demo below
sudo mv /var/lib/kubelet/config.yml /var/lib/kubelet/config.yaml 
sudo systemctl restart kubelet.service 

#...let's log out and check the node status 
exit 
#on master, node2 should be ready 
kubectl get nodes 

#worker node troubelshooting secnario 3 

ssh devops@node3

#crashlooping again...let's dig deeper and grab the logs 
sudo systemctl status kubelet.service --no-pager 

#using journalctl we can pull the logs...this it's looking for config.yml ...
sudo journalctl -u kubelet.service --no-pager

#is config.yml in /var/lib/kubelet/? No, it's config.yaml... but i don't want to rename this beacause 
#i want the filename so it matches all the configs on all my other nodes 
sudo ls -la  /var/lib/kubelet/  

#let's reconfigure where the kubelet looks for this config file 
#where is the kubelet file specified? check the systemd unit config for the kubelet 
#where does systemd think the kubelet's config.yaml is ?
sudo systemctl status kubelet.service --no-pager 
sudo more /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

#let's update the config args, inside here is the startup configuration for the kubelet 
sudo vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

#let's restart the kubelet...
sudo systemctl restart kubelet.service 

#but since edited the unit file, we neede to reload the unit files (configs)...then restart the service 
sudo systemctl daemon-reload 
sudo systemctl restart kubelet.service 
#check the status ...active and running ?
sudo systemctl status kubelet.service 
#...let's log out and check the node status 
exit 
#on master, node3 should be ready 
kubectl get nodes 

#############################################################################################################""
################ troubleshootin - Control Plane 

#1 - control plane pods stopped 
#remember the master still has a kubelet and runs pods...if the kubelet's not running then troubleshoot that first
#this section focuses on the control plane when it's running the control plane as pods 
#run this script on your master nodes to break the control plane 

sh ./2-TroubelshootingControlPlaneBreakStuff-1.sh 

#let's check the status of our control plane pods ...refused?
#it can take a bit to break the control plane wait until it connection to server was refused 
kubectl get pods --namespace  kube-system 

#let's ask our container runtime, what's up...well there's pods running on this node, but no control plane pods
#that's your clue... no control plane plane pods running ...what starts up the control plane pods ....static pod manifests 
sudo docker ps 

#let's check config.yaml for the location of the static pod manifets 
#look for staticPodPath 
sudo mmore /Var/lib/kubelet/config.yaml 

#the directory doesn't exist ...oh no!
sudo ls -laR /etc/kubernetes/

#we could update config.yaml to point to this path or rename it to put the manifests in the configured location 
#the kubelet will find these manifests and launch the pods again
sudo mv /etc/kubernetes/manifests.wrong /etc/kubernetes/manifests
sudo ls /etc/kubernetes/manifests

#check the container runtime to ensure the pods are started ...We can see they were created and running just a few 
sudo docker ps 

#let's ask kubernetes whats it thinks...
kubectl get pods -n kube-system 

#2 - troubleshooting control plane failure, user Pods are all pending 

#breack the control plane 
sh 2-TroubelshootingControlPlaneBreakStuff-2.sh

#let's start a workload 
kubectl create deployment nginx --image=nginx 
kubectl scale deployment nginx --replicas=4 

#Interesting, all of the pods are pending...why ?
kubectl get pods

#nodes look good ? yes, they're all reporting ready 
kubectl get nodes 

#let's look at the pod's events...<none> nothing, no sheduling, no image pulling, no container starting...let's zoom 
kubectl describe pods 
#what's the next step after the pods are created by the replication controler?sheduling...
kubeclt get events --sort-by='.metadata.creationTimestmp'

#so we know ther's no sheduling events, let's check the control plane status...the sheduler isn't listening 
kubectl get componentstatuses 

#ah, the sheduler pod is reporting ImagePullBackoff
kubectl get pods --namespace kube-system 

#let's check the events on the pod...We can see if failed for pull the image for the sheduler, says image not found 
#looks like the manifest is trying to pull an image that doesn't exist 
kubectl describe pods --namespace kube-system kube-scheduler-master 

#that's defined in the static pod manifest 
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml # correction the name of image 

#is the scheduler back online , yes ,it's running
kubectl get pods --namespace kube-system 

#it's healthy 
kubectl get componentstatuses 

#and our deployment is now up and running ...might take a minute or two for the pods to start up 
kubectl get deployment 

#Clean up our resources...
kubectl delete deployments.app nginx 


