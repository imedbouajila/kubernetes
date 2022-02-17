#Setup
# 1. 4 VMs ubuntu 20.4, 1 control plane, 3 nodes.
# 2. Static IPs on individual VMs
# 3. /etc/hosts hosts file includes name to IP mappings for VMs
# 4. Swap is disabled
# 5. Take snapshots prior to insatallation, this way you can insatall and revert to snapshot if needed

#Disable swap; swapoff then edit your fstab removing any entry for swap partitions
#you can recover the space with fdisk. you may want to reboot to ensure your config is ok

swapoff -a 
vi /etc/fstab

#Install packages 
#containerd prerequisites, first load two modules and configure them to load on boot
#https://kubernetes.io/doc/setup/production-environment/container-runtimes/
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

#Setup required sysctl params, these persist across reboots

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward                = 1
net.bridge.bridge-nf-call-ip6tables =1
EOF

#Applay sysctl params without reboot

sudo sysctl --system

#Install containerd

sudo apt-get upgrade
sudo apt-get install -y containerd

#Create a containerd configuration file 

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

#Set the cgroup driver for containerd to systemd which is required for the kubelet.
#For more information on this config file see:
#https://github.com/containerd/cri/blob/master/docs/config.md and also 
#https://github.com/containerd/containerd/blob/master/docs/ops.md

#At the end of this section 
	[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
	....
#Add this two lines, identation matters.
	[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]	
	  SystemdCgroup = true
#these two lines are now in the config.toml file...all you have to do is set systemdCgroup=fals => change it to true   
sudo vi /etc/containerd/config.toml

#Restart containerd with new configuration
sudo systemctl restart containerd

###########
#Install kubernestes packages - kubeadm, kublet and kubectl
#Add google's apt repository gpg key

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - 

#Add the kubernestes apt repository

sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF'

#Update the package list and use apt-cache policy to inspect versions available in the repository
sudo apt-get update
apt-cache policy kubelet | head -n 20

#Install the required packages, if needed we can request a seoecific version
#Use this version because in a later course we will upgrade the cluster to a newer version 
VERSION=1.20.1-00
sudo apt-get install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION
sudo apt-mark hold kubelet kubeadm kubectl docker

#To install the last, omit the version parametres
#sudo apt-get insatll kybelet kubeadm kubectl
#sudo apt-mark hold kubelet kubectl kubeadm containerd

#1 - systemd Units
#Check the status of our kubelet and our container runtime, containerd 
#The kubelet will enter a carshloop until a cluster is creadted or the node is joined to an existing cluster
sudo systemctl status kubelet.service
sudo systemctl status containerd.service

#Ensur both are set to start when the system starts up
sudo systemctl enable kubelet.service
sudo systemctl enable containerd.service




















	








































