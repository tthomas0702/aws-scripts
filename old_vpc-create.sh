#!/bin/bash

# vpc-create.sh version 0.0.1

# edit this to desired region
# to get region list:
# aws ec2 --region us-west-2 describe-regions --query "Regions[].RegionName" --output text 
region="us-west-2"
echo "*** Creating VPC in Region $region ***"

# name of vpc
name="test1"

# create the basic VPC and save vpc-ip to a var
vpcid_temp=$(aws ec2 --region $region create-vpc --cidr-block 10.0.0.0/16  --query "Vpc.VpcId")
# need to remove " from vpcid var
vpcid="${vpcid_temp%\"}"
vpcid="${vpcid#\"}"

echo "Created VPC $vpcid"


# give VPC Name tag
aws --region $region ec2 create-tags --resources $vpcid --tags Key=Name,Value=vpc-${name}
aws --region $region ec2 create-tags --resources $vpcid --tags Key=Purpose,Value="Deloping bash script"
aws --region $region ec2 create-tags --resources $vpcid --tags Key=sr,Value="SR name or number"


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
    subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block 10.0.${third}.0/24 --availability-zone $az) ;


    #tag mgmt subnet
    subnetId=`echo $subnet_result | awk '{print $9}'`
    echo "mgmt subnetId: $subnetId" 
    aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=mgmt-${az} 

    # enable auto assing mgmt IP on subnet
    aws ec2 --region $region modify-subnet-attribute --subnet-id $subnetId --map-public-ip-on-launch


    # accociate route table to igw with mgmt subnet 
    aws --region $region ec2 associate-route-table  --subnet-id $subnetId --route-table-id $rtbid 1>/dev/null


    # make ext subnet for first az
    ((third+=1));
    subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block 10.0.${third}.0/24 --availability-zone $az) ;
     

    #tag ext subnet
    subnetId=`echo $subnet_result | awk '{print $9}'`
    echo "ext subnetId: $subnetId"
    aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=ext-${az}
    
    # accociate route table to igw with ext subnet, but have not enabled public IP, this subnet is for Virtual Servers 
    aws --region $region ec2 associate-route-table  --subnet-id $subnetId --route-table-id $rtbid 1>/dev/null

done


# find the default security-group that gets auto created with VPC creation 
sgid=$(aws ec2 --region $region  describe-security-groups --filter "Name=vpc-id,Values=$vpcid" --query "SecurityGroups[].GroupId" --output text)
echo "VPC security-group: $sgid"


# describe and tag security-group
aws --region $region ec2  create-tags --resources $sgid --tags Key=Name,Value=open-sg-${name}

# the sg group above is wide open. I have not decided if I should create one here that is more specic and make the one above deny all...




