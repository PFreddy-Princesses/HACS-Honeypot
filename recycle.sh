#!/bin/bash
if [ "$#" -ne 4 ]; then
echo "Usage: $0 <container_name> <external_ip> <netmask> <mitm_port>"
exit 1
fi
name=$1
ip=$2
netmask=$3
port=$4
containerIP=$(sudo lxc-info -n "$name" -iH)
sudo lxc-stop "$name"
sudo lxc-destroy "$name"
sudo ip addr add $ip/16 brd + dev eth1
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $ip
--jump DNAT --to-destination $containerIP
sudo iptables --table nat --delete POSTROUTING --source $containerIP --destination
0.0.0.0/0 --jump SNAT --to-source $ip
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $ip
--protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:$port
sudo forever stop 0
sudo rm -f "/home/student/MITM/$name.log"
