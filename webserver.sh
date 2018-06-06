#!/bin/bash

# ver 0.0.1

# This is not working, maybe should start fresh
#

# This is a script to create amz linux web server
# It assumes 1 subnet
# mgmt-<Availability Zone> for the managment subnet
# e.g. mgmt-us-west-2a
#
#

### SET DEFAULTS HERE ###
name="noname"
region="us-west-2"
imageid="ami-be4051de"  # Amazon Linux 2 LTS Candidate 2 AMI (HVM), SSD Volume Type - ami-be4051de
inst_type="m3.xlarge"

### END DEFAULTS ###

#shopt -s -o nounset
declare -rx SCRIPT=${0##*/}


# Proccess paramaters

while [ $# -gt 0 ] ; do
        case "$1" in
        -h | --help)
                printf "%s\n" "usage: $SCRIPT  "
                printf "%s\n" "-n name of webserver"
                printf "%s\n" "-r region to create VPC in default us-west-2 (Oregon)"
		printf "%s\n" "-a availability zone"
		printf "%s\n" "-d description"
		printf "%s\n" "-s security-group id"
		printf "%s\n" "-t instance type "
		printf "%s\n" "-u user-data /path/file"
		printf "%s\n" "-ls list security-group for region"
		printf "%s\n" "-k key pair name, must already exist for account"
		printf "%s\n" "-l list availabilty Zones for region and exit"
		printf "%s\n" "-p list key pair names for region and exit"
                printf "%s\n" "-h --help"
                printf "%s\n" "This script requires a AZ with three subnets configured. "
		printf "%s\n" "It will configure interface for mgmt, ext, int "
                printf "%s\n" "Example:"
                printf "%s\n\n" "$SCRIPT -r us-east-1 -i ami-81c27df9"

        exit 0
        ;;

        -n ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n" "name for -n missing" >&2
                exit 192
                fi
                name="$1"
                ;;

       -s ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n" "security-group ID must be provided " >&2
                exit 192
                fi
                sgid="$1"
                ;;

       -u ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n" "-u user-data file location must be provided " >&2
                exit 192
                fi
                userdata="$1"
                ;;


        -k ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n" "-k <key_name> missing" >&2
                exit 192
                fi
                keyname="$1"
                ;;

       -t ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n" "-t instance type missing" >&2
                exit 192
                fi
                inst_type="$1"
                ;;



       -l ) shift
                if [ $# -eq 0 ] ; then
                printf "%s\n" "Availability Zone for ${region}:" >&2
		aws ec2 --region $region describe-availability-zones --query "AvailabilityZones[].ZoneName" --output text
                exit 0
                fi
                ;;

       -p ) shift
                if [ $# -eq 0 ] ; then
                printf "%s\n" "Key pairs for ${region}:" >&2
		aws --region $region ec2 describe-key-pairs --query "KeyPairs[*].KeyName" --output table
                exit 0
                fi
                ;;

        -ls ) shift
                if [ $# -eq 0 ] ; then
                printf "%s\n" "security-groups for ${region}:" >&2
		aws --region $region ec2 describe-security-groups --query "SecurityGroups[*].GroupName" --output table
                exit 0
                fi
                ;;



       -r ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n"  "-r requires a region be provided" >&2
                exit 192
                fi
                region="$1"
                ;;

	-a ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n"  "-a requires AZ " >&2
                exit 192
                fi
                az="$1"
                ;;

	-d ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n"  "-d description missing" >&2
                exit 192
                fi
                description="$1"
                ;;



        -* ) printf "$SCRIPT:$LINENO: %s\n"  "switch $1 not supported" >&2
             exit 192
             ;;

        * ) printf "$SCRIPT:$LINENO: %s\n"  "extra argument or missing switch" >&2
            exit 192
            ;;


        esac
        shift
done




## created interfaces in the AZ specified

if [ -z "$az" ]
then
    echo "-a Availabilty Zone is required"
    exit 192
fi

if [ -z "$sgid" ]
then
    echo "-s security-group-id is required"
    echo -e  " Try:\naws --region us-west-2 ec2 describe-security-groups --query "SecurityGroups[*].{GroupName:GroupName, GroupId:GroupId}"\n"
    exit 192
fi

if [ -z "$keyname" ]
then
    echo "-k existing key pair name required"
    exit 192
fi


# function for tagging
# usage:
# tagit <resource ID> <key value> <Value value>
tagit () {
    aws --region $region ec2 create-tags --resources $1 --tags Key=$2,Value=$3
}


### Create interfaces that will be used by webserver ###

# get subnetId for mgmt in AZ
filter_val="mgmt-${az}"
subnetid=$(aws --region $region ec2 describe-subnets --filters "Name=tag:Name,Values=${filter_val}" --query "Subnets[*].SubnetId" --output text)

# create mgmt interface
mgmt_ifid=$(aws --region $region ec2 create-network-interface --subnet-id $subnetid --description "mgmt $az" --groups $sgid --query "NetworkInterface.NetworkInterfaceId")
mgmt_ifid=`echo $mgmt_ifid | tr -d '"'`  # remove quote marks that end up in var
echo "mgmt_ifid $mgmt_ifid"
tagit $mgmt_ifid "Name" mgmt-${name}


### Next... create EIP, tagit and associtate with mgmt-ip
# aws --region $region ec2 allocate-address

# create EIP for mgmt
eip_raw=$(aws --region $region ec2 allocate-address --output text)
eip_id=`echo $eip_raw | cut -d ' ' -f1`
eip_addr=`echo $eip_raw | cut -d ' ' -f3`
tagit $eip_id Name mgmt-${name}
echo -e "mgmt EIP:	$eip_addr"
mgmt_eip=$eip_addr

# associate EIP with mgmt interface
mgmt_eip_alloc_id=$(aws --region $region ec2 associate-address --allocation-id $eip_id --network-interface-id $mgmt_ifid)
mgmt_eip_map_raw=$(aws --region $region ec2 describe-addresses --filter "Name=network-interface-id,Values=$mgmt_ifid" --query "Addresses[*].[PublicIp, PrivateIpAddress]" --output text)
echo -e "mgmt EIP `echo $mgmt_eip_map_raw | cut -d " " -f1` maps--to---> `echo $mgmt_eip_map_raw | cut -d " " -f2`"


### Create instance ###
echo "Using AMI-ID: $imageid"
echo "Instance type: $inst_type"
echo "Key Pair: $keyname"

if [ "$userdata" ]
then
    inst_id=$(aws --region $region ec2 run-instances --image-id $imageid --user-data file://${userdata} --count 1 --instance-type $inst_type --key-name $keyname --network-interfaces "[{\"DeviceIndex\":0,\"NetworkInterfaceId\":\"$mgmt_ifid\"}, {\"DeviceIndex\":1,\"NetworkInterfaceId\":\"$ext_ifid\"}, {\"DeviceIndex\":2,\"NetworkInterfaceId\":\"$int_ifid\"}]" --query "Instances[*].InstanceId" --output text)
else
    inst_id=$(aws --region $region ec2 run-instances --image-id $imageid --count 1 --instance-type $inst_type --key-name $keyname --network-interfaces "[{\"DeviceIndex\":0,\"NetworkInterfaceId\":\"$mgmt_ifid\"}, {\"DeviceIndex\":1,\"NetworkInterfaceId\":\"$ext_ifid\"}, {\"DeviceIndex\":2,\"NetworkInterfaceId\":\"$int_ifid\"}]" --query "Instances[*].InstanceId" --output text)
fi

tagit $inst_id "Name" ${name}-${az}
echo "Created InstanceId: $inst_id"


# print connection info
echo -e "\nTo connect via ssh:"
echo -e "ssh admin@${mgmt_eip} -i $keyname"





