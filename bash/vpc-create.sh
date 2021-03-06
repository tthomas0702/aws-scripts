#!/bin/bash

# vpc-create.sh version 0.1.0
# 
# This is depricated in favor of vpcform.py
# vpcform.py results is the samve VPC, subnet etc as this script
# but is easier to maintain moving forward. 
# I am leaving this here in case I still need a bash AWSCLI version for some reason and also 
# as a AWSCLI reference if needed. 
# vpcform.py cannot yet replcase ssg-vpc-create.sh that sets up for deploying ssg with BIG-IQ 
# and ELB  
# I plan to add those features into vpcform.py


### SET DEFAULTS HERE ###
name="test1-new"
subnet_count="3"
region="us-west-2"
network_prefix="10.0."

### END DEFAULTS ###

shopt -s -o nounset
declare -rx SCRIPT=${0##*/}


# Proccess paramaters
while [ $# -gt 0 ] ; do
  case "$1" in
    -h | --help)
      printf "%s\n" "usage: $SCRIPT  "
      printf "%s\n" "-n name of VPC to be created default "test1""
      printf "%s\n" "-s number of subnets to create in each AZ [1,2, or 3] default 3"
      printf "%s\n" "-r region to create VPC in default us-west-2 (Oregon)"
      printf "%s\n" "-h --help"
      printf "%s\n\n" "Most switches are optional if set in the defaults section of the script"
      printf "%s\n" "Example:"
      printf "%s\n\n" "$SCRIPT -n devVPC -s 3 -r us-east-1"

      exit 0
      ;;

    -n ) shift
      if [ $# -eq 0 ] ; then
        printf "$SCRIPT:$LINENO: %s\n" "name for -n missing" >&2
        exit 192
      fi
      name="$1"
      ;;

    -s ) shift
      if [ $# -eq 0 ] ; then
        printf "$SCRIPT:$LINENO: %s\n" "number of subnets for -s is missing" >&2
        exit 192
      fi
      subnet_count="$1"
      ;;

    -p ) shift
      if [ $# -eq 0 ] ; then
        printf "$SCRIPT:$LINENO: %s\n" "The first two octets of network with . appened; eg 10.99." >&2
        exit 192
        fi
        network_prefix="$1"
        ;;

    -r ) shift
      if [ $# -eq 0 ] ; then
        printf "$SCRIPT:$LINENO: %s\n"  "-r requires a region be provided" >&2
        exit 192
        fi
        region="$1"
        ;;

    -* ) printf "$SCRIPT:$LINENO: %s\n"  "switch $1 not supported" >&2
      exit 192
      ;;

     * ) printf "$SCRIPT:$LINENO: %s\n"  "extra argument or missing switch" >&2
      exit 192
      ;;


  esac
  shift
done

# proccessing function outside of main

# decided not to refator and instead write a new script in python using boto3

# TODO
# Refactoring to move everything into functions and then call from main at the end of script
# This is left unfinished. The script word but I decided to write over in python
# see vpcform.py

# Functions #

# get subnetId from the output when creating a subnet
# I have had trouble with this changing and had to adjust 12-28-2018 from $9 to $12
# it also may have to do with the version of aws-cli and boto used by it
get_subnet_ID () {
    echo $subnet_result | awk '{print $12}'
}

# function tag_resource 
# aws --region $region ec2 create-tags --resources $vpcid --tags Key=Name,Value=vpc-${name}
# $1 resources, $2 Key, $3 Value
tag_resource () {
    aws --region $region ec2 create-tags --resources "$1" --tags Key="$2",Value="$3"
}

echo "*** Creating VPC in Region $region ***"


# create the basic VPC and save vpc-ip to a var
vpcid_temp=$(aws ec2 --region $region create-vpc --cidr-block ${network_prefix}0.0/16  --query "Vpc.VpcId")
# need to remove " from vpcid var
vpcid="${vpcid_temp%\"}"
vpcid="${vpcid#\"}"

echo "Created VPC $vpcid"


# give VPC Name tag
tag_resource $vpcid Name vpc-${name}
tag_resource $vpcid Purpose "Devloping bash script"
tag_resource $vpcid sr "SR name or number"


# create igw for vpc
igwid=$(aws --region $region ec2  create-internet-gateway --output text | awk '{print $2}')


# attach igw to VPC and tag it
aws --region $region ec2 attach-internet-gateway --vpc-id $vpcid --internet-gateway-id $igwid
aws --region $region ec2 create-tags --resources $igwid --tags Key=Name,Value=igw-$name


# get route-table-id VPC auto creates and use for the public subnets to get out to internet
rtbid=$(aws --region $region ec2  describe-route-tables --filters "Name=vpc-id,Values=$vpcid" --output text --query RouteTables[0].RouteTableId)
echo "route table id: $rtbid"


# create route in route-table to igw and tag it
aws --region $region ec2 create-route --route-table-id $rtbid --destination-cidr-block 0.0.0.0/0 --gateway-id $igwid 1>/dev/null
aws --region $region ec2 create-tags --resources $rtbid --tags Key=Name,Value=gw-dft-$name


## make subnets in each Availability Zone in VPC ##
# make a list of all Availibilty Zones in region
declare azlist=$(aws ec2 --region $region describe-availability-zones --output text --query "AvailabilityZones[].ZoneName")


# create var for third octect of IP network
third=0


# loop through AZ list to create subnets
for az in $azlist ;
do

    # Make mgmt default subnet for each az
    ((third+=1));
    subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block ${network_prefix}${third}.0/24 --availability-zone $az) ;

    #tag mgmt subnet
    subnetId=`get_subnet_ID`
    echo "mgmt AZ: $az subnetId: $subnetId net: ${network_prefix}${third}.0/24" 
    aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=mgmt-${az} 

    # enable auto assing mgmt IP on subnet
    # DISABLED
    #aws ec2 --region $region modify-subnet-attribute --subnet-id $subnetId --map-public-ip-on-launch


    # accociate route table to igw with mgmt subnet 
    aws --region $region ec2 associate-route-table  --subnet-id $subnetId --route-table-id $rtbid 1>/dev/null

    # if -s 2 or 3 given
    if [ "$subnet_count" = "2" ] || [ "$subnet_count" = "3" ]
        then
        # make ext subnet for each az
        ((third+=1));
        subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block ${network_prefix}${third}.0/24 --availability-zone $az) ;
     

        #tag ext subnet
        subnetId=`get_subnet_ID`
        echo "ext  AZ: $az subnetId: $subnetId net: ${network_prefix}${third}.0/24"
        aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=ext-${az}
    
        # accociate route table to igw with ext subnet, but have not enabled public IP, this subnet is for Virtual Servers 
        aws --region $region ec2 associate-route-table  --subnet-id $subnetId --route-table-id $rtbid 1>/dev/null
    fi

    # if -s 3 given
    if [ "$subnet_count" = "3" ]
        then
        # make int subnet for each az (no route-table association
        ((third+=1));
        subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block ${network_prefix}${third}.0/24 --availability-zone $az) ;

        #tag int subnet
        subnetId=`get_subnet_ID`
        echo "int  AZ: $az subnetId: $subnetId net: ${network_prefix}${third}.0/24"
        aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=int-${az}
    fi
done


# find the default security-group that gets auto created with VPC creation 
sgid=$(aws ec2 --region $region  describe-security-groups --filter "Name=vpc-id,Values=$vpcid" --query "SecurityGroups[].GroupId" --output text)
echo "VPC security-group: $sgid"


# describe and tag default security-group
aws --region $region ec2  create-tags --resources $sgid --tags Key=Name,Value=auto-created-default-sg-${name}


# create mgmt security-group
mgmt_sg_id=$(aws --region $region ec2 create-security-group --group-name Bigip-mgmt --description "Group for 22, 443, and 8443" --vpc-id $vpcid --output text)
echo "big-ip-mgmt security-group: $mgmt_sg_id"
# tag bigip mgmt security-group
aws --region $region ec2 create-tags --resources $mgmt_sg_id --tags Key=Name,Value=bigip-mgmt


# put inbound rules in bigip mgmt security-group
aws --region $region ec2 authorize-security-group-ingress --group-id $mgmt_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $mgmt_sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $mgmt_sg_id --protocol tcp --port 8443 --cidr 0.0.0.0/0


# create bigiq security-group
bigiq_sg_id=$(aws --region $region ec2 create-security-group --group-name bigiq --description "Group for BIG-IQs" --vpc-id $vpcid --output text)
echo "bigiq security-group:        $bigiq_sg_id"
# tag bigiq security-group
aws --region $region ec2 create-tags --resources $bigiq_sg_id --tags Key=Name,Value=bigiq

# put inbound rules in bigiq security-group
aws --region $region ec2 authorize-security-group-ingress --group-id $bigiq_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $bigiq_sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $bigiq_sg_id --protocol tcp --port 8514 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $bigiq_sg_id --protocol tcp --port 29015 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $bigiq_sg_id --protocol tcp --port 27017 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $bigiq_sg_id --protocol tcp --port 9997 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $bigiq_sg_id --protocol tcp --port 9300 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $bigiq_sg_id --protocol tcp --port 28015 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $bigiq_sg_id --protocol tcp --port 8008 --cidr 0.0.0.0/0


# enable --enable-dns-hostnames for VPC
echo "Setting --enable-dns-hostname for VPC $vpcid"
aws --region $region ec2 modify-vpc-attribute --vpc-id $vpcid  --enable-dns-hostnames







