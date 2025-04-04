1- creation clé ssh : ssh-keygen -t rsa
2- installation openssh server : sudo apt install openssh-server
3- copy la clé ssh dans les serveurs cibles : ssh-copy-id -i ~/.ssh/id_rsa devops@172.16.18.80
master 172.16.18.79
node1 172.16.18.80
node2 172.16.18.81
node3 172.16.18.82

sudo apt-get install vim
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
ssh devops@node1
# configuration de dhcl server et mettre le rang des adresses ips 
https://www.malekal.com/comment-configurer-une-adresse-ip-sur-ubuntu/
- dimentions
redhat 64
nodes 4 - 15 
master 6 - 30
mdp 1992 

## disk
 du -a | sort -n -r | head -n 10



- copie coller 
Activate shared clipboard in menu
https://askubuntu.com/a/438204/245048
Install Virtual Box guest extensions in ubuntu guest
sudo apt-get install virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11
- reseau nat network
https://www.it-connect.fr/comprendre-les-differents-types-de-reseaux-virtualbox/
=================
devops@master:~$ ifconfig
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.5  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::a986:194b:3621:7e21  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:b1:41:1f  txqueuelen 1000  (Ethernet)
        RX packets 8725  bytes 12806576 (12.8 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1608  bytes 122321 (122.3 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

devops@node1:~$ ifconfig
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.6  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::922e:6826:8ceb:f6c2  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:db:fc:df  txqueuelen 1000  (Ethernet)
        RX packets 159895  bytes 241858315 (241.8 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 6192  bytes 391537 (391.5 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
devops@node2:~$ ifconfig
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::ce1c:5433:2e58:2cbb  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:08:f8:43  txqueuelen 1000  (Ethernet)
        RX packets 74498  bytes 112574623 (112.5 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 4669  bytes 425356 (425.3 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
devops@node3:~$ ifconfig
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.4  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::4020:8243:ed2b:231  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:c3:bb:a3  txqueuelen 1000  (Ethernet)
        RX packets 172  bytes 208583 (208.5 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 138  bytes 12392 (12.3 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0


#Dimension de la fenêtre
xrandr -s 1440x900

# configuration de dhcl server et mettre le rang des adresses ips 
https://www.malekal.com/comment-configurer-une-adresse-ip-sur-ubuntu/



#==== new cluster

chmod 777 
vi /etc/sudoers
chmod 555 
