###Important#####
#If you are using containerd, make sure docker isn't installed
#Kubeadm init will try to auto detect the container runtime and at the moment
#it if both are installed it will pick docker fisrt

ssh master

#Creating a cluster
#create our kubernetes cluster, specify a pod nework rang matching that in calicoyaml!
#Only on the control plane node, download the yaml files for the pod network

curl https://docs.projectcalico.org/manifests/calico.yaml -O

#Look inside calico.yaml andi find the setting for pod network ip adress rang CALICIO_IPV4POOL_CIDR,
#adjust if needed for your infrastructure to ensure that the pod network IP
#range dosen't overlap with other networks in our infrastructure

vi calico.yaml
kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml
#witch cidr
CALICO_KUBECONFIG=~/.kube/config DATASTORE_TYPE=kubernetes calicoctl get ippool -o wide --allow-version-mismatch
or kubectl get ippools -o yaml
#AME                  CIDR             NAT    IPIPMODE   VXLANMODE   DISABLED   DISABLEBGPEXPORT   SELECTOR   
#default-ipv4-ippool   192.168.0.0/16   true   Always     Never       false      false              all() 
#pb:Calico requires net.ipv4.conf.all.rp_filter to be set to 0 or 1
kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true 
sudo ./calicoctl node status


#How to remove extra host only network interfaces 
#Generate a default kubeadm init configuration file ...this defines the settings of the cluster being built.
#if you get a warning about how docker is not installed ...this is ok to ignre ans is a bug in kubeadm
#for more info on kubeconfig configuration files see:
# hhtps://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file

kubeadm config print init-defaults | tee ClusterConfiguration.yaml

#inside default configuration file, we need to change four things.
#1. the ip endpoint for api server localAPIEndpoint.advertiseAddress:
#2. nodeRegistration.criSpcket from docker to containerd
#3. set the cgroup driver for the kublet to systemd, it's not set in this file yet, the default is cgroupfs
#4. edit kubernetesVersion to match the version you installed in 0-PackageInstallation-containerd.sh

#change the adress of the loclaAPIEndpoint.advertiseAddres to the control plane node's IP adress 
sed -i 's/ advertiseAddress: 1.2.3.4/ advertiseAddress: 172.16.18.79/' ClusterConfiguration.yaml

#set the CRI Socket to point to containerd
sed -i 's/ criSocket: \/var\/run\/dockershim\.sock/ criSocket: \/var\/run\/containerd\/containerd\.sock/' ClusterConfiguration.yaml

#set the cgroupDriver to systemd...matching that of your container runtime, containerd
cat <<EOF | cat >> ClusterConfiguration.yaml
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd

EOF

#review the cluster configuration file,update the version to match what you've installed.
#we'r using 1.20.1 if you're using a newer version update that here.
vi ClusterConfiguration.yaml

#need to add CRI socket since there's a check for docker in the kubeadm init process,
#if you don't you'll get this error...
#error execution phase perflight: docker is requied for container runtime: exec: "docker":executable file not found

sudo kubeadm init \
    --config=ClusterConfiguration.yaml \
    --cri-socket /run/containerd/containerd.sock
sudo kubeadm init \
    --config=ClusterConfiguration.yaml \
    --cri-socket /var/run/dockershim.sock

### restultat ##"kubeadm join 172.16.18.79:6443 --token abcdef.0123456789abcdef \
##    --discovery-token-ca-cert-hash sha256:e870533550220ca2cc784655fb956fdde8ad4644b04795e487f9d0c54025dad8 

#Before moving on review the output of the cluster création process including the kubeadm init phases,
#the admin.conf setup and the node join command

#Configure our account on the control plane node to have admin access to the api server from a non-privileged account

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

#1. creating a pod network
#deploy yaml file for your pod network

kubectl apply -f calico.yaml

#look for the all the system pods and calico pods to change to running.
#the DNS pod won't start (pending) until the pod network is deployed and running.

kubectl get pods --all-namespaces

#gives you output over time, rather than repainting the screen on each iteration.

kubectl get pods --all-namespaces --watch

#all system pods should be running 
kubectl get pods --all-namespaces

#get a list of our current nodes,just the control plane node/master node ...should be ready.
kubectl get nodes

#2. systemd units...again!
#check out the systemd unit...it's no longer carshlooping because it has static pods to start
#remember the kubelet starts the static pods, and thus the control plane pods 

sudo systemctl status kubelet.service 
#3. static pod manifests
#let's check out the static pod manifests on the control plane node 

ls /etc/kubernetes/manifests

#and look more closely at api server ans etcd's manifest.
sudo more /etc/kubernetes/manifests/etcd.yaml
sudo more /etc/kubernetes/manifests/kube-apiserver.yaml

#check out the directory where the kubeconfig files live for each of the control plane nodes.
ls /etc/kubernetes


##########################""
#kubectl logs etcd-master
#kubectl delete pods etcd-master
#kubectl delete pods --all
#kubectl get namespaces
#kubectl config get-contexts # current namespace 
#kubectl describe pod
#kubectl describe pod calico-kube-controllers-59f54d6bbc-gbj95 --namespace=kube-system
#kubectl logs calico-node-f8hb5 --namespace=kube-system
#sudo du -ahxd 1 /  
#kubectl config set-context --current --namespace





















