#!/usr/bin/python3


""" form a VPC and other objects to get a quick new environment """

import boto3



# client interface
s3_client = boto3.client('s3')

# resource
s3_resource = boto3.resource('s3')



