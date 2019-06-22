#!/usr/bin/python3


""" form a VPC and other objects to get a quick new environment """

import boto3
from pprint import pprint

def create_client(service_name, region):
    """ Set up client ex. create_client('ec2', 'us-west-2')"""
    client = boto3.client(service_name, region_name=region)
    
    return client


def create_resource(service_name, region):
    """ Set resource """
    resource = boto3.resource(service_name, region_name=region)

    return resource


if __name__ == '__main__':


    CLIENT = create_client('ec2', 'us-west-2')

    RESOURCE = create_resource('ec2', 'us-west-2')

    # test that client works by get output
    INSTANCES = CLIENT.describe_instances()
    pprint(INSTANCES)


