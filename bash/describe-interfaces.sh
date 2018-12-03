#!/bin/bash


### SET DEFAULTS HERE ###
region="us-west-2"

### END DEFAULTS ###


# Proccess paramaters

while [ $# -gt 0 ] ; do
        case "$1" in
        -h | --help)
                printf "%s\n" "usage: $SCRIPT  "
                printf "%s\n" "-r region that you want to describe interface for"
                printf "%s\n" "-h --help"
                printf "%s\n\n" "Most switches are optional if set in the defaults section of the script"
                printf "%s\n" "Example:"
                printf "%s\n\n" "$SCRIPT -r us-east-1"

        exit 0
        ;;

       -r ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n"  "-r requires a region be provided" >&2
                exit 192
                fi
                region="$1"
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



aws --region $region ec2 describe-network-interfaces --query "NetworkInterfaces[].{VM:Attachment.InstanceId, ID:NetworkInterfaceId,AZ:AvailabilityZone,DSC:Description,SubID:SubnetId,IP:PrivateIpAddresses[*].PrivateIpAddress }"
