#!/bin/bash

# startup_route_rules.sh
# ver 0.0.1

# This is run on BIG-IP on boot from /config/startup to fix issues hit when customer
# added routes cause AWS service failures
# It will add IP routing policies to table 245 for the mgmt interface to reach
# metadata, AWS degault GW, and AWS DNS servers
# Here is the default table 245
# $ ip route list table 245
#   default via 10.0.1.1 dev mgmt
#   10.0.1.0/24 dev mgmt  scope link  src 10.0.1.107



# set ip rule to reach meta-data endpoint
ip rule add to 169.254.169.254 lookup 245


# Get AWS DNS server for mgmt interface
MGMT_DNS_SERVER=$(/config/cloud/aws/getNameServer.sh mgmt)

# set ip rule for DNS server IP
ip rule add to $MGMT_DNS_SERVER lookup 245


## get URL for region API endpoint, resolve IP and add ip rule ##
HOSTNAME=$(curl -s  http://169.254.169.254/latest/meta-data/hostname)
# example result:
# ip-172-31-0-84.eu-central-1.compute.internal

# get region
REGION=$(echo $HOSTNAME | cut -d '.' -f2)

# I need to make ec2.<region>.amazonaws.com
ENDPOINT=$(echo -n "ec2.${REGION}.amazonaws.com")

# get ip for ENDPOINT
ENDPOINT_IP=$(dig $ENDPOINT | grep -A1 "ANSWER SECTION" | grep -v "ANSWER SECTION" | awk '{print $5}')

# set ip rule for endpoint
ip rule add to $ENDPOINT_IP lookup 245



# debug
ip rule list

