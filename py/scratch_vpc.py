#!/usr/bin/env python3

"""
using git hub examples

https://gist.github.com/nguyendv/8cfd92fc8ed32ebb78e366f44c2daea6

Access key ID:      AKIAJTS6TMIUS64PGL2A
Secret access key:  hFpcVi6XBvUNbK2iYJMzvoXIucGIPoFeYL2Z2FVS

"""


from pprint import pprint
import boto3


AWS_ACCESS_KEY_ID = 'AKIAJTS6TMIUS64PGL2A'
AWS_SECRET_ACCESS_KEY = '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'


EC2 = boto3.resource('ec2',
                     aws_access_key_id=AWS_ACCESS_KEY_ID,
                     aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
                     region_name='us-west-2')


# create VPC
CIDER_BLOCK = '10.0.0.0/16'
VPC_NAME = 'Scratch1'

VPC = EC2.create_vpc(CidrBlock=CIDER_BLOCK)
# we can assign a name to vpc, or any resource, by using tag
VPC.create_tags(Tags=[{"Key": "Name", "Value": VPC_NAME}])
VPC.wait_until_available()
print(VPC.id)





