#!/bin/bash
if [[ $# -ne 4 ]]
then
echo "Usage: <container name> <external ip> <netmask> <mitm port>"
exit 1
fi
name=$1
sudo lxc init ubuntu:20.04 "$name"
sudo lxc start "$name"
sleep 10
sudo lxc exec "$name" -- bash -c "sudo apt update && sudo apt-get install openssh-server && sudo systemctl restart ssh"

#ADD CODE FOR GENERATION OF FILES AND DIRECTORIES


ip=$2
port=$4
containerIP=$(sudo lxc-info -i -n "$name" | awk '{print $2}')
sudo ip addr add $ip/$3 brd + dev eth1s
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ip --jump DNAT --to-destination $containerIP
sudo iptables --table nat --insert POSTROUTING --source $containerIP --destination 0.0.0.0/0 --jump SNAT --to-source $ip
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ip --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:$port
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo forever start -l "/home/student/MITM/$name.log" -a /home/student/MITM/mitm.js -n "$name" -i "$containerIP" -p $port --auto-access --auto-access-fixed 3 --debug