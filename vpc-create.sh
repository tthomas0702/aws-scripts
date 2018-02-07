#!/bin/bash

# vpc-create.sh version 0.0.1

# edit this to desired region
# to get region list:
# aws ec2 --region us-west-2 describe-regions --query "Regions[].RegionName" --output text 
region="us-west-2"
echo "*** Creating VPC in Region $region ***"

# create the basic VPC and save vpc-ip to a var
vpcid_temp=$(aws ec2 --region $region create-vpc --cidr-block 10.0.0.0/16  --query "Vpc.VpcId")
# need to remove " from vpcid var
vpcid="${vpcid_temp%\"}"
vpcid="${vpcid#\"}"

echo "Created VPC $vpcid"


# give VPC Name tag
aws --region $region ec2 create-tags --resources $vpcid --tags Key=Name,Value=vpc-${region}
aws --region $region ec2 create-tags --resources $vpcid --tags Key=Purpose,Value="Deloping bash script"
aws --region $region ec2 create-tags --resources $vpcid --tags Key=sr,Value="SR name or number"


# create igw for vpc
igwid=$(aws --region $region ec2  create-internet-gateway --output text | awk '{print $2}')


# attahce igw to VPC and tag it
aws --region $region ec2 attach-internet-gateway --vpc-id $vpcid --internet-gateway-id $igwid
aws --region $region ec2 create-tags --resources $igwid --tags Key=Name,Value=igw-$region


# get route-table-id VPC auto creates and use for the public subnets to get out to internet
rtbid=$(aws --region $region ec2  describe-route-tables --filters "Name=vpc-id,Values=$vpcid" --output text --query RouteTables[0].RouteTableId)
#rtbid=$(aws --region $region ec2  create-route-table --vpc-id $vpcid --output text | grep rtb | awk '{print $2}')
echo "route table id: $rtbid"


# create route in route-table to igw and tag it
aws --region $region ec2 create-route --route-table-id $rtbid --destination-cidr-block 0.0.0.0/0 --gateway-id $igwid 1>/dev/null
aws --region $region ec2 create-tags --resources $rtbid --tags Key=Name,Value=pub-rtb-$region


## make subnets in each Availability Zone in VPC ##
# make a list of all Availibilty Zones in region
declare azlist=$(aws ec2 --region $region describe-availability-zones --output text --query "AvailabilityZones[].ZoneName")


# create var for third octect of IP network
third=0


# loop through AZ list to create subnets
for az in $azlist ;
do

    # Make public default subnet for each az
    ((third+=1));
    subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block 10.0.${third}.0/24 --availability-zone $az) ;


    #tag public subnet
    subnetId=`echo $subnet_result | awk '{print $9}'`
    echo "Public subnetId: $subnetId" 
    aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=pub-${az} 

    # enable auto assing Public IP on subnet
    aws ec2 --region $region modify-subnet-attribute --subnet-id $subnetId --map-public-ip-on-launch


    # accociate route table to igw with public subnet 
    aws --region $region ec2 associate-route-table  --subnet-id $subnetId --route-table-id $rtbid 1>/dev/null


    # make private subnet for first az
    ((third+=1));
    subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block 10.0.${third}.0/24 --availability-zone $az) ;
     

    #tag private subnet
    subnetId=`echo $subnet_result | awk '{print $9}'`
    echo "private subnetId: $subnetId"
    aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=pri-${az}
    
done


# find the default security-group that gets auto created with VPC creation 
sgid=$(aws ec2 --region $region  describe-security-groups --filter "Name=vpc-id,Values=$vpcid" --query "SecurityGroups[].GroupId" --output text)
echo "VPC security-group: $sgid"


# describe and tag security-group
aws --region $region ec2  create-tags --resources $sgid --tags Key=Name,Value=open-sg-${region}

# the sg group above is wide open. I have not decided if I should create one here that is more specic and make the one above deny all...




