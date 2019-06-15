#!/usr/bin/env python3

"""Lays out a VPC """



from __future__ import print_function
import argparse
from base64 import b64encode
import json
from pprint import pprint
import sys
import time
import boto3
import urllib3
import requests


### Arguments parsing section ###
def cmd_args():
    """Handles command line arguments given."""
    parser = argparse.ArgumentParser(description='This is a tool for working'
                                                 'with regkey pool on BIG-IQ')
    parser.add_argument('-d',
                        '--debug',
                        action="store_true",
                        default=False,
                        help='enable debug')
    parser.add_argument('-v',
                        '--verbose',
                        action="store_true",
                        default=False,
                        help='enable verbose for options that have it')
    parser.add_argument('-a',
                        '--address',
                        action="store",
                        dest="address",
                        help='IP address of the target host')
    parser.add_argument('-u',
                        '--username',
                        action="store",
                        dest="username",
                        default='admin',
                        help='username for auth to host')
    parser.add_argument('-p',
                        '--password',
                        action="store",
                        dest="password",
                        default='admin',
                        help='password for auth to host')
    parser.add_argument('-l',
                        '--list-pools',
                        action="store_true",
                        default=False,
                        help='list the UUIDs for existing regkey pools, requires no args')
    parser.add_argument('-o',
                        '--offerings',
                        action="store",
                        dest="pool_uuid",
                        help='take UUID of pool as arg and list the offerings for a pool'
                             ' use -v to also show the active modules')
    parser.add_argument('-r',
                        '--regkey',
                        action="store",
                        dest="reg_key",
                        help='takes and stores the regkey for use in other options')
    parser.add_argument('-A',
                        '--add-on-keys',
                        action="store",
                        dest="add_on_key_list",
                        help='takes string of comma sep addon keys for use by other options')
    parser.add_argument('-i',
                        '--install-offering',
                        action="store",
                        dest="install_pool_uuid",
                        help='takes pool UUID as arg and installs new offering,'
                             'requires -r, -A can be used to install addon keys at'
                             'the same time')
    parser.add_argument('-m',
                        '--modify-offering-addons',
                        action="store",
                        dest="modify_pool_uuid",
                        help='takes pool UUID as arg and installs addon to offering,'
                             'requires -A [addon_key_list] and -r reg_key')


    parsed_arguments = parser.parse_args()

    # debug set print parser info
    if parsed_arguments.debug is True:
        print(parsed_arguments)


    # required args here
    if parsed_arguments.address is None:
        parser.error('-a target address is required, '
                     'use mgmt for local')
    if parsed_arguments.install_pool_uuid:
        if parsed_arguments.reg_key is None:
            parser.error('-i requires -r')
    if parsed_arguments.modify_pool_uuid:
        if parsed_arguments.add_on_key_list is None:
            parser.error('-m requires -A and -r')
        elif parsed_arguments.reg_key is None:
            parser.error('-m requires -A and -r')

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

