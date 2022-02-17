###########unistall&&install docker
sudo apt-get remove containerd

sudo apt-get update

sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

 echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io  
#################### config docker runtime
sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl enable docker \
sudo systemctl daemon-reload \
sudo systemctl restart docker


############### listing port
sudo netstat -lnp | grep 10250
######################## init cluster
 kubeadm reset --force
 rm -rf /etc/cni/version/
 kubeadm init --apiserver-advertise-address=192.168.x.x  --pod-network-cidr=192.168.x.x/24
 or 
 sudo kubeadm init \
    --config=ClusterConfiguration.yaml \
    --cri-socket /var/run/dockershim.sock

#################### checker the configuration of kubeadm
kubectl -n kube-system get cm kubeadm-config -o yaml 

to remove docker old verison : https://forums.docker.com/t/how-to-downgrade-docker-to-a-specific-version/29523/3
sudo apt-get autoremove -y docker-engine \
&& sudo apt-get purge docker-engine -y \
&& sudo rm -rf /etc/docker/ \
&& sudo rm -f /etc/systemd/system/multi-user.target.wants/docker.service \
&& sudo rm -rf /var/lib/docker \
&&  sudo systemctl daemon-reload
to install specific verion of docker : https://docs.docker.com/engine/install/ubuntu/

#	Here is one example how you may list all Kubernetes containers running in docker:
docker ps -a | grep kube | grep -v pause
