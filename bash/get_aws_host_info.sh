#!/bin/bash

# get_aws_host_info.sh  
# Tim Thomas 2018
# ver. 0.0.1

# This s designed to be run locally on a BIG-IP running in AWS to get info
# These example are for reference to create other scripts


HOSTNAME=$(curl -s  http://169.254.169.254/latest/meta-data/hostname)
# example result:
# ip-172-31-0-84.eu-central-1.compute.internal


DOMAIN=$(echo $HOSTNAME | cut -d '.' -f2-)

REGION=$(echo $HOSTNAME | cut -d '.' -f2)

# I need to make ec2.<region>.amazonaws.com
ENDPOINT=$(echo -n "ec2.${REGION}.amazonaws.com")

# get ip for ENDPOINT
ENDPOINT_IP=$(dig $ENDPOINT | grep -A1 "ANSWER SECTION" | grep -v "ANSWER SECTION" | awk '{print $5}')


# get mgmt default gw
MGMT_DEFAULT_GW=$(ip route list table 245 | grep default | awk '{print $3}')

# get AWS DNS server
MGMT_DNS_SERVER=$(/config/cloud/aws/getNameServer.sh mgmt)



echo "**** RESULT VALUES ****"
echo -e "HOSTNAME \t\t $HOSTNAME"
echo -e "DOMAIN \t\t\t $DOMAIN"
echo -e "REGION \t\t\t $REGION"
echo -e "MGMT_DNS_SERVER\t\t $MGMT_DNS_SERVER"
echo -e "ENDPOINT \t\t $ENDPOINT"
echo -e "ENDPOINT_IP \t\t $ENDPOINT_IP"
echo -e "MGMT_DEFAULT_GW \t $MGMT_DEFAULT_GW"

