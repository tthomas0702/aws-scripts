#!/usr/bin/env python3

"""Lays out a VPC """

#TODO note: Left off working on argparse section
# need to remove old requred arg sections that are for BIG-IQ stuff

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
                        dest='vpc_name',
                        default='default-name',
                        help='name for the VPC')
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
                        help='AWS region to create VPC in, default=us-west-2')
    parser.add_argument('-i',
                        '--aws-access-key-id',
                        action='store',
                        dest='aws_access_key_id',
                        help='aws_access_key_id, if not given values in '
                             '.aws/credintials will be used, these can be set '
                             'by running "aws configure" to set the defaults')
    parser.add_argument('-k',
                        '--aws-secret-access-key',
                        action='store',
                        dest='aws_secret_access_key',
                        help='aws_secret_access_key, if not given values in '
                             '.aws/credintials will be used, these can be set '
                             'by running "aws configure" to set the defaults')


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



# create VPC


# tag it




# create a IGW



# get the auto created route tabel and use for Public subnet



# create a NAT GW




# define subnets




















if __name__ == "__main__":

    SCRIPT_NAME = sys.argv[0]


    OPT = cmd_args()





