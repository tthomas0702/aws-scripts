#!/bin/bash

# get IPs for interfaces

# get list of macs for interfaces
mac_list=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)

#echo $mac_list
ip_list=''
for m in $mac_list ; do 
    #echo $m
    ip=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${m}local-ipv4s)
    echo $ip
    #ip_list+="${ip}\n"
    #ip_list+="${ip} "
done

echo -e $ip_list | sort
