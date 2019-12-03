#!/usr/bin/env python3

"""Lays out a VPC """

import argparse
from pprint import pprint
import sys
import time
import boto3


### Arguments parsing section ###
def cmd_args():
    """Handles command line arguments given."""
    parser = argparse.ArgumentParser(description='This is a tool for forming'
                                                 'a VPC')
    parser.add_argument('-d',
                        '--debug',
                        action='store_true',
                        default=False,
                        help='enable debug')
    parser.add_argument('-v',
                        '--verbose',
                        action='store_true',
                        default=False,
                        help='enable verbose for options that have it')
    parser.add_argument('-n',
                        '--name',
                        action='store',
                        dest='name',
                        default='default-name',
                        required=True,
                        help='name for the VPC and tags in it')
    parser.add_argument('-s',
                        '--subnet-count',
                        action='store',
                        dest='subnet_count',
                        default='2',
                        help='Number of subnets to create in each AZ, default=2')
    parser.add_argument('-p',
                        '--prefix',
                        action='store',
                        dest='network_prefix',
                        default='10.0.',
                        help='network prefix for subnets, default=10.0.')
    parser.add_argument('-l',
                        '--list-pools',
                        action='store_true',
                        default=False,
                        help='list the UUIDs for existing regkey pools, requires no args')
    parser.add_argument('-r',
                        '--region',
                        action='store',
                        dest='region',
                        default='us-west-2',
                        required=True,  # force, not use .aws/config
                        help='AWS region to create VPC in, default=us-west-2')
    parser.add_argument('-i',
                        '--aws-access-key-id',
                        action='store',
                        dest='aws_access_key_id',
                        required=True,  # force, not use .aws/credetials
                        help='aws_access_key_id, if not given values in '
                             '.aws/credintials will be used, these can be set '
                             'by running "aws configure" to set the defaults')
    parser.add_argument('-k',
                        '--aws-secret-access-key',
                        action='store',
                        dest='aws_secret_access_key',
                        required=True,  # force, not use .aws/credetials
                        help='aws_secret_access_key, if not given values in '
                             '.aws/credintials will be used, these can be set '
                             'by running "aws configure" to set the defaults')
    parser.add_argument('-t',
                        '--tag',
                        action='store',
                        dest='tag',
                        help='The string given here will be used in creating tags')
    parser.add_argument('-b',
                        '--vpc-cidr-block',
                        action='store',
                        dest='vpc_cidr_block',
                        required=False,
                        default='10.0.0.0/16', 
                        help='base network for VPC default: 10.0.0.0/16')



    parsed_arguments = parser.parse_args()

    # debug set print parser info
    if parsed_arguments.debug is True:
        print(parsed_arguments)

    # required args here
    #if parsed_arguments.address is None:
    #    parser.error('-a target address is required, '
    #                 'use mgmt for local')
    #if parsed_arguments.install_pool_uuid:
    #    if parsed_arguments.reg_key is None:
    #        parser.error('-i requires -r')
    #if parsed_arguments.modify_pool_uuid:
    #    if parsed_arguments.add_on_key_list is None:
    #        parser.error('-m requires -A and -r')
    #    elif parsed_arguments.reg_key is None:
    #        parser.error('-m requires -A and -r')

    return parsed_arguments

### END ARGPARSE SECTION ###

'''
client: low-level AWS service access, all api
Resource: higher-level, object-oriented API
session: stores configuration information (primarily credentials and selected region)
    - allows you to create service clients and resources
    - boto3 creates a default session for you when needed
'''


class Aws:
    """class to connect to AWS"""
    def __init__(self, aws_region=None, aws_key_id=None, aws_secret_key=None):
        self.session = boto3.Session(
            aws_access_key_id=aws_key_id,
            aws_secret_access_key=aws_secret_key,
            region_name=aws_region
            )
        #self.ec2_client = self.session.client('ec2') 
        #self.ec2_resource = self.session.resource('ec2')
        self.client = self.session.client('ec2')
        self.resource = self.session.resource('ec2')


if __name__ == "__main__":

    SCRIPT_NAME = sys.argv[0]

    OPT = cmd_args()

    REGION = OPT.region

    AWS_KEY_ID = OPT.aws_access_key_id

    AWS_SECRET_KEY = OPT.aws_secret_access_key

    VPC_CIDR_BLOCK = OPT.vpc_cidr_block

    NAME = OPT.name

    ec2 = Aws(aws_region=REGION, aws_key_id=AWS_KEY_ID, aws_secret_key=AWS_SECRET_KEY)

    # describe all instances
    #INSTANCES = ec2.client.describe_instances()
    #pprint(INSTANCES)


    ## example: make a simple VPC for test using client
    #RESPONSE = ec2.client.create_vpc(
    #    CidrBlock=VPC_CIDR_BLOCK,)
    #print('VPC:')
    #pprint(RESPONSE)


    # make a VPC for using resourse
    VPC = ec2.resource.create_vpc(
        CidrBlock=VPC_CIDR_BLOCK,)
    VPC.wait_until_available()
    print('Created VPC: {}'.format(VPC.id))
    # next use VPC object to add tag for vpc
    VPC.create_tags(Tags=[{"Key": "Name", "Value": NAME}])


    # make internet gateway
    IGW_NAME = '{}-IGW'.format(NAME)
    IGW = ec2.resource.create_internet_gateway()
    print('Created Internet Gatway {}'.format(IGW.id))

    print('Tag IGW Name: {}'.format(IGW_NAME))
    IGW.create_tags(Tags=[{"Key": "Name", "Value": IGW_NAME}])

    # attach  IGW to VPC
    print('attach_internet_gateway {} to VPC {}'.format(IGW.id, VPC.id))
    VPC.attach_internet_gateway(InternetGatewayId=IGW.id)


    #TODO consider using the main route table instead of creating a new on below
    # how do I find it?  with the "main" attribute?

    # create route table and route to IGW
    TABLE_NAME = '{}-rtb-igw'.format(NAME)
    ROUTE_TABLE = VPC.create_route_table()
    ROUTE = ROUTE_TABLE.create_route(DestinationCidrBlock='0.0.0.0/0', GatewayId=IGW.id)
    ROUTE_TABLE.create_tags(Tags=[{"Key": "Name", "Value": TABLE_NAME}])

    # NExt...
    # make subnets for each AZ




















