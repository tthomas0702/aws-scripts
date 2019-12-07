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


    return parsed_arguments


### END ARGPARSE SECTION ###


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


def get_main_route_table_object(vpc):
    'uses vpc object to get the default main route table auto created'
    main_route_table = []
    for route_table in  list(vpc.route_tables.all()):
        for association in list(route_table.associations):
            if association.main == True:
                main_route_table.append(route_table)
                rt = main_route_table[0]

            return rt

def tagger(object_name, key_name, tag_value):
    'generic tagger'
    object_name.create_tags(Tags=[{"Key": key_name, "Value": tag_value}])    


def make_az_id_list():
    'Make list of AZ ZoneId for this region'
    avail_zones = ec2.client.describe_availability_zones()
    avail_zone_list = avail_zones['AvailabilityZones']
    az_zone_id_list = []
    for zone_dict in avail_zone_list:
        az_zone_id_list.append(zone_dict['ZoneId'])
        
    return az_zone_id_list



if __name__ == "__main__":

    SCRIPT_NAME = sys.argv[0]

    OPT = cmd_args()

    REGION = OPT.region

    AWS_KEY_ID = OPT.aws_access_key_id

    AWS_SECRET_KEY = OPT.aws_secret_access_key

    VPC_CIDR_BLOCK = OPT.vpc_cidr_block

    NAME = OPT.name

    ec2 = Aws(aws_region=REGION, aws_key_id=AWS_KEY_ID, aws_secret_key=AWS_SECRET_KEY)

    # make a VPC for using resourse
    VPC = ec2.resource.create_vpc(
        CidrBlock=VPC_CIDR_BLOCK,)
    VPC.wait_until_available()
    tagger(VPC, "Name", NAME)
    print('Created VPC: {}'.format(VPC.id))

    # make internet gateway
    IGW = ec2.resource.create_internet_gateway()
    tagger(IGW, "Name", '{}-IGW'.format(NAME))
    print('Created Internet Gatway') 

    # attach  IGW to VPC
    print('Attaching internet gateway {} to VPC {}'.format(IGW.id, VPC.id))
    VPC.attach_internet_gateway(InternetGatewayId=IGW.id)

    # tag "main" route table but put no route in it
    MAIN_MGMT_ROUTE_TABLE = get_main_route_table_object(VPC)
    tagger(MAIN_MGMT_ROUTE_TABLE, "Name", '{}-main-rtb'.format(NAME))
    print('MAIN_MGMT_ROUTE_TABLE.id is: {}'.format(MAIN_MGMT_ROUTE_TABLE.id))

    # create route table xx pub subnet and add route to IGW
    MGMT_ROUTE_TABLE = VPC.create_route_table()
    tagger(MGMT_ROUTE_TABLE, "Name", '{}-mgmt-rtb'.format(NAME))
    MGMT_DEFAULT_ROUTE = MGMT_ROUTE_TABLE.create_route(DestinationCidrBlock='0.0.0.0/0', GatewayId=IGW.id)

# Maybe I want to change this to make mgmt,pub, so that the IP will be easier to remember
    print('Creating Subnets...')
    SUBNET_NAME_LIST = ['mgmt', 'pub', 'priv']
    ZONE_ID_LIST = make_az_id_list()
    third_oct = 0
    for subnet_name in SUBNET_NAME_LIST:
        for zone_id in ZONE_ID_LIST:
            third_oct += 1
            subnet = ec2.resource.create_subnet(
            AvailabilityZoneId=zone_id,
            CidrBlock='10.0.{}.0/24'.format(str(third_oct)),
            VpcId=VPC.id,
            DryRun=False
            )
            print('10.0.{}.0/24  {}-{}'.format(str(third_oct), subnet_name, zone_id))
            tagger(subnet, "Name", '{}-{}'.format(subnet_name, zone_id))
            # TODO   Asociate route table if not priv





