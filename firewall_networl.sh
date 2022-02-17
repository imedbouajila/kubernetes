sudo apt update
sudo apt install firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --state

sudo firewall-cmd --add-port=179/tcp --permanent
sudo firewall-cmd --reload

nc -zvw3 192.168.1.43 6443
telnet 192.168.1.43 6443
nmap 192.168.1.43 -p 6443

#les ports ouverts sont sudo netstat -lp --inet
