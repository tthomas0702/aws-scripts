#!/bin/bash

# give list AZ for regin given.
# take region as first arg
#
# ls-az.sh <region>
#
# ap-south-1
# eu-west-3
# eu-west-2
# eu-west-1
# ap-northeast-2
# ap-northeast-1
# sa-east-1
# ca-central-1
# ap-southeast-1
# ap-southeast-2
# eu-central-1
# us-east-1
# us-east-2
# us-west-1
# us-west-2



aws ec2 --region $1 describe-availability-zones --query "AvailabilityZones[].ZoneName"

# I need to make a better one that takes arg of Region and then use --filter and --query to get result
