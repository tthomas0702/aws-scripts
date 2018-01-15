#!/bin/bash

aws ec2 --region us-west-2 describe-regions --query "Regions[].RegionName" --output text
