#!/bin/bash


### SET DEFAULTS HERE ###
name="noname"
region="us-west-2"
imageid="ami-81c27df9"  # BIG-IP v13 Good

### END DEFAULTS ###


# Proccess paramaters

while [ $# -gt 0 ] ; do
        case "$1" in
        -h | --help)
                printf "%s\n" "usage: $SCRIPT  "
                printf "%s\n" "-n name of big-ip"
                printf "%s\n" "-r region to create VPC in default us-west-2 (Oregon)"
		printf "%s\n" "-a availability zone"
		printf "%s\n" "-d description"
		printf "%s\n" "-s security-group id"
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

# get subnet for a az
#aws --region $region ec2 describe-subnets --filters "Name=tag:Name,Values=ext-us-west-2c"
#aws --region $region ec2 describe-subnets --filters "Name=tag:Name,Values=mgmt-us-west-2c"

#filter_val="mgmt-${az}"
#aws --region $region ec2 describe-subnets --filters "Name=tag:Name,Values=${filter_val}" --query "Subnets[*].SubnetId" --output text




## create inteface for mgmt ##
# get subnetId for mgmt in AZ
filter_val="mgmt-${az}"
subnetid=$(aws --region $region ec2 describe-subnets --filters "Name=tag:Name,Values=${filter_val}" --query "Subnets[*].SubnetId" --output text)

# create mgmt interface
mgmt_ifid=$(aws --region $region ec2 create-network-interface --subnet-id $subnetid --description "mgmt $az" --groups $sgid --query "NetworkInterface.NetworkInterfaceId")
mgmt_ifid=`echo $mgmt_ifid | tr -d '"'`
echo "mgmt_ifid $mgmt_ifid"
aws --region $region ec2 create-tags --resources $mgmt_ifid --tags Key=Name,Value=${name}-mgmt



## create inteface for ext ##
# get subnetId for ext in AZ
filter_val="ext-${az}"
subnetid=$(aws --region $region ec2 describe-subnets --filters "Name=tag:Name,Values=${filter_val}" --query "Subnets[*].SubnetId" --output text)

# create interface
ext_ifid=$(aws --region $region ec2 create-network-interface --subnet-id $subnetid --description "ext $az" --groups $sgid --query "NetworkInterface.NetworkInterfaceId")
ext_ifid=`echo $ext_ifid | tr -d '"'`
echo "ext_ifid $ext_ifid"
aws --region $region ec2 create-tags --resources $ext_ifid --tags Key=Name,Value=${name}-ext


## create inteface for int ##
# get subnetId for int in AZ
filter_val="int-${az}"
subnetid=$(aws --region $region ec2 describe-subnets --filters "Name=tag:Name,Values=${filter_val}" --query "Subnets[*].SubnetId" --output text)

# create interface
int_ifid=$(aws --region $region ec2 create-network-interface --subnet-id $subnetid --description "int $az" --groups $sgid --query "NetworkInterface.NetworkInterfaceId")
int_ifid=`echo $int_ifid | tr -d '"'`
echo "int_ifid $int_ifid"
aws --region $region ec2 create-tags --resources $int_ifid --tags Key=Name,Value=${name}-int



### interfaces created .... now run-instance...









#aws --region us-west-2 ec2 run-instances --image-id ami-81c27df9 --count 1 --instance-type m3.xlarge --key-name ech-oregon --network-interfaces '[{"DeviceIndex":0,"NetworkInterfaceId":"eni-0f61fba9bd8b986ff"}, {"DeviceIndex":1,"NetworkInterfaceId":"eni-0ff2f96180f884fc0"}, {"DeviceIndex":2,"NetworkInterfaceId":"eni-09c1955f398527ceb"}]'
