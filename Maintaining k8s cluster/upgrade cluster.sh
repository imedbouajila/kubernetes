#1 - find the version you want to upgrade to 
#you can only upgrade one minor version to the next minor version 
sudo apt update 
apt-cache policy kubeadm 

#what version are we on ?
kubectl version --short 
kubectl get nodes

#First, upgrade kubeadm on the master 
#replace the version with the version you want to upgrade to 
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.18.4-00
sudo apt-amrk hold kubeadm

#all good?
kubeadm version 

#next, drain any workload on the master node 
kubectl drain master --ignore-daemonsets 

#Run upgrade plan to test the upgrade process and run pref-flight checks
#highlights additional work needed after the upgrade, such as manually updating the kubelets
#and displays version information for the control plan components 
sudo kubeadm upgrade paln   

#run the upgrade, you can get this from previous output 
#run preflight checks - API available.Node status ready and control plane healthy 
#checks to ensure you're upgrading along the correct upgrade path 
#prepulls container images to reduce downtime of control plane components 
#for each control plane component,
#   updates the certificates used for authentication 
#   create a new static pod manifest in /etc/kubernetes/manifestes and saves the old one to /etc/kubernetes/tmp 
#   which causes the kubelet to restart the pods 
#updates the master's kubelet configuration and also updates CoreDNS and kube-proxy 
sudo kubeadm upgrade apply v1.18.4 #<-- this format is different than the package's version format 

#look for [upgrade/successful] SUCCESS! your clluster was upgraded to "v1.xx.yy". Enjoy!

#Uncordon the node 
kubectl Uncordon master

#now update the kubelet and kubectl on the control plane node(s)
sudo apt-mark unhold kubelet kubectl 
sudo apt-get update 
sudo apt-get install -y kubelet=1.18.4-00 kubectl=1.18.4-00
sudo apt-mark hold kubelet kubectll 

#check the update status 
kubectl version --short
kubectl get nodes 

#upgrade anyy additional control plane nodes with the same process 

#upgrade the workers, drain the node, then log into it 
#update the environment variable so you can reuse those code over and over 

kubectl drain node1 --ignore-daemonsets 
ssh devops@node1

#First, upgrade kubeadm 
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.18.4-00
sudo apt-amrk hold kubeadm

#update kubelet configuration for the node 
sudo kubeadm upgrade node 

#update the kubelet and kubectl on the node
sudo apt-mark unhold kubelet kubectl 
sudo apt-get update 
sudo apt-get install -y kubelet=1.18.4-00 kubectl=1.18.4-00
sudo apt-mark hold kubelet kubectll

#log out of the node 
exit 

#get the nodes to show the version ...can take a second to update 
kubectl get nodes 

#Uncordon the node to allow workload again 
kubectl uncordon node1 

#check the versions of the nodes 
kubectl get nodes 


#### TO DO ##############
#### BE SURE TO UPGRADE THE REMAINING NODES ####
