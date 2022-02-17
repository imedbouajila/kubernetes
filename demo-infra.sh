1- creation clé ssh : ssh-keygen -t rsa
2- installation openssh server : sudo apt install openssh-server
3- copy la clé ssh dans les serveurs cibles : ssh-copy-id -i ~/.ssh/id_rsa devops@172.16.18.80
master 172.16.18.79
node1 172.16.18.80
node2 172.16.18.81
node3 172.16.18.82
4- configuration de fichier /etc/ssh/ssh_config
PubkeyAuthentication yes

5- rdemarrage de service ssh : sudo systemctl restart sshd.service

6- fixer les ip : https://fr.techtribune.net/linux/comment-configurer-une-adresse-ip-statique-sur-ubuntu-20-04/56906/

7- mettre Les alias de SSH : ~/.ssh/config
# Server node1
Host node1
HostName 192.168.1.63
User devops
IdentityFile ~/.ssh/id_rsa
Port 22
#Dimension de la fenêtre
xrandr -s 1440x900

# configuration de dhcl server et mettre le rang des adresses ips 
https://www.malekal.com/comment-configurer-une-adresse-ip-sur-ubuntu/