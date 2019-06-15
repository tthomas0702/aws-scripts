#!/usr/bin/env python3

"""List s3 buckets for credentials set in 'aws configure' """

import boto3
from pprint import pprint


s3 = boto3.resource('s3')

# Print out bucket names
for bucket in s3.buckets.all():
    print(bucket.name)




