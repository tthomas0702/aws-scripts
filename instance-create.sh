#!/bin/bash


### SET DEFAULTS HERE ###
name="bigip-noname"
region="us-west-2"
image_id="ami-81c27df9" # BIG-IP v13 good hourly
instance_type="m3.xlarge"
key_name="ech-oregon"
security_group_id="sg-039b1688b66853ad7"
subnet_id="subnet-0524e3b7d6458cbdd"



### END DEFAULTS ###


# Proccess paramaters

while [ $# -gt 0 ] ; do
        case "$1" in
        -h | --help)
                printf "%s\n" "usage: $SCRIPT  "
                printf "%s\n" "-n name of VPC to be created default "test1""
                printf "%s\n" "-s number of subnets to create in each AZ [1,2, or 3] default 3"
                printf "%s\n" "-r region to create VPC in default us-west-2 (Oregon)"
                printf "%s\n" "-h --help"
                printf "%s\n\n" "Most switches are optional if set in the defaults section of the script"
                printf "%s\n" "Example:"
                printf "%s\n\n" "$SCRIPT -n devVPC -s 3 -r us-east-1"

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
                printf "$SCRIPT:$LINENO: %s\n" "number of subnets for -s is missing" >&2
                exit 192
                fi
                subnet_count="$1"
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



## dev rought try ##
aws --region $region ec2 run-instances --image-id $image_id --count 1 --instance-type $instance_type --key-name $key_name --security-group-ids $security_group_id --subnet-id $subnet_id


## to do ##
# Need to modify vpc-create so that it create a securituy group that that can be atttached to let in port 22 and 8443
# Should I leave GUI access at 8443 event when I use a 3 nic setup? or should I change it?
# After I modify the vpc-create then I can get back to testing the "run-instances" command above
