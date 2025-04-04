sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl restart kubelet
sudo systemctl restart kube-proxy

ssh -OPTIONS -p SSH_PORT user@remote_server "remote_command1; remote_command2; remote_script.sh"
ssh -p 22 devops@node1 "sudo systemctl restart kubelet"

##check connectivity via
worker# nc -vz 192.168.1.230 6443