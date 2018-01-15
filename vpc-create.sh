#!/bin/bash

vpcid_temp=$(aws ec2 --region us-west-2 create-vpc --cidr-block 10.0.0.0/16  --query "Vpc.VpcId")
# need to remove " from vpcid var
vpcid="${vpcid_temp%\"}"
vpcid="${vpcid#\"}"

echo "Created VPC $vpcid"

aws ec2 --region us-west-2 describe-vpcs --vpc-ids $vpcid


# give VPC Name tag
aws --region us-west-2 ec2 create-tags --resources $vpcid --tags Key=Name,Value=dev-temp
aws --region us-west-2 ec2 create-tags --resources $vpcid --tags Key=Purpose,Value="Deloping bash script"
aws --region us-west-2 ec2 create-tags --resources $vpcid --tags Key=sr,Value="SR name or number"




# delete vpc example
#aws ec2 --region us-west-2 delete-vpc --vpc-id "vpc-e101dc98"
echo "To delete"
echo "aws ec2 --region us-west-2 delete-vpc --vpc-id $vpcid"
