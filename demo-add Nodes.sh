# connect to node1
ssh node1
#Disable swap,swapoff then edit your fstab removing any entry for swap partitions
#you can recover the space with fdisk.you may want to reboot to ensure your config is ok.

sudo swapoff -a
vi /etc/fstab

####Important####
#I expect this node to change a bit to make the installation process more streamlined.
#overall, the end result will stay the same ...you'll have containerd installed

#0. joining nodes to a cluster
#install a container runtime - containerd
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
sudo apt-get update
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
sudo apt install curl
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
sudo apt-mark hold kubelet kubeadm kubectl containerd

#To install the last, omit the version parametres
#sudo apt-get insatll kybelet kubeadm kubectl
#sudo apt-mark hold kubelet kubectl kubeadm containerd


#Check the status of our kubelet and our container runtime, containerd 
#The kubelet will enter a carshloop until a cluster is creadted or the node is joined to an existing cluster
sudo systemctl status kubelet.service
sudo systemctl status containerd.service

#Ensur both are set to start when the system starts up
sudo systemctl enable kubelet.service
sudo systemctl enable containerd.service

#log out node1 and back on to master 
exit

#on master if you didn't keep the output, on the control plan node,  you can get the token.
kubeadm token list

#if you need to generate a new token, perhaps the old one timed out/expired
kubeadm token create

#on the control plane node, you can find the ca cert hash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outfrom der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
# => resultat : e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
#you can also use print-join-command to generate token and print the join command in the proper format
#copy this into your CLIPBOARD
kubeadm token create --print-join-command 
# => resultat :kubeadm join 172.16.18.79:6443 --token 77jmbp.k18gpaa6jfgtvmlx \
#    --discovery-token-ca-cert-hash sha256:e870533550220ca2cc784655fb956fdde8ad4644b04795e487f9d0c54025dad8 

#back on the worker nod1, using the control plane node (api server) ip address or name, the token and the 
ssh node1

#Paste_join_command_here be sure to add sudo 
sudo kubeadm join 172.16.18.79:6443 \
   --token gbdfob.h9sa6thcfra3vym9  \
   --discovery-token-ca-cert-hash sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

#log out of node1 and back to master 
exit 

#back on control plane node, this will say notready until the networking pod is created on the new node
#has to schedule the pod, then pull the container 
kubectl get nodes

#on the control plane node, watch for the calico pod and the kube-proxy to change to running on the newley added node
kubectl get pods --all-namespaces --watch 

#still on the control plane node look for this added node's status ready.
kubectl get nodes 

#go back to the top and do the same for node2 and node3
ssh node2 

#you can skip the token re-creation if you have one that's still valid 

#to remove a node follow the below steps

#Run on Master
# kubectl cordon <node-name>
# kubectl drain <node-name> --force --ignore-daemonsets  --delete-emptydir-data
# kubectl delete node <node-name>










