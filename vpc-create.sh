#!/bin/bash

# static vars
region="us-west-2"

# get list of az in region
declare azlist=$(aws ec2 --region $region describe-availability-zones --output text --query "AvailabilityZones[].ZoneName")



vpcid_temp=$(aws ec2 --region $region create-vpc --cidr-block 10.0.0.0/16  --query "Vpc.VpcId")
# need to remove " from vpcid var
vpcid="${vpcid_temp%\"}"
vpcid="${vpcid#\"}"

echo "Created VPC $vpcid"

aws ec2 --region $region describe-vpcs --vpc-ids $vpcid


# give VPC Name tag
aws --region $region ec2 create-tags --resources $vpcid --tags Key=Name,Value=vpc-${region}
aws --region $region ec2 create-tags --resources $vpcid --tags Key=Purpose,Value="Deloping bash script"
aws --region $region ec2 create-tags --resources $vpcid --tags Key=sr,Value="SR name or number"

# make igw for vpc
igwid=$(aws --region $region ec2  create-internet-gateway --output text | awk '{print $2}')
aws --region $region ec2 attach-internet-gateway --vpc-id $vpcid --internet-gateway-id $igwid
aws --region $region ec2 create-tags --resources $igwid --tags Key=Name,Value=igw-$region
# create route table
rtbid=$(aws --region $region ec2  create-route-table --vpc-id $vpcid --output text | grep rtb | awk '{print $2}')
echo $rtbid
aws --region $region ec2 create-route --route-table-id $rtbid --destination-cidr-block 0.0.0.0/0 --gateway-id $igwid
aws --region $region ec2 create-tags --resources $rtbid --tags Key=Name,Value=to_igw-$region

# make subnets
third=0

for az in $azlist ;
do
    # Make public subnet for first az
    ((third+=1));
    subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block 10.0.${third}.0/24 --availability-zone $az) ;
    #echo $subnet_result
    #tag subnet
    subnetId=`echo $subnet_result | awk '{print $9}'`
    echo "Public $subnetId" 
    aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=sub-${az}-pub
    # accociate route table to igw 
    aws --region $region ec2 associate-route-table  --subnet-id $subnetId --route-table-id $rtbid

    # make private subnet for first az
    ((third+=1));
    subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block 10.0.${third}.0/24 --availability-zone $az) ;
    #echo $subnet_result
    #tag subnet
    subnetId=`echo $subnet_result | awk '{print $9}'`
    echo "private $subnetId ..."
    aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=sub-${az}-pri

    
done



### to do ###
# It will create route tables and associate Pub subnets to igw
# Do I need to explicitly associate them ?
#
# Next need to make sg groups





