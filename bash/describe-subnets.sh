#!/bin/bash


### SET DEFAULTS HERE ###
region="us-west-2"

### END DEFAULTS ###


# Proccess paramaters

while [ $# -gt 0 ] ; do
        case "$1" in
        -h | --help)
                printf "%s\n" "usage: $SCRIPT  "
                printf "%s\n" "-a availabilityZone "
                printf "%s\n" "-r region default us-west-2 (Oregon)"
                printf "%s\n" "-h --help"
                printf "%s\n\n" "Most switches are optional if set in the defaults section of the script"
                printf "%s\n" "Example:"
                printf "%s\n\n" "$SCRIPT -r us-east-1 -a us-east-1a"

        exit 0
        ;;

        -a ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n" "availabilityZone is missing" >&2
                exit 192
                fi
                az="$1"
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

if [ -z "$az" ]
then
	output=$(aws --region $region ec2 describe-subnets --query "Subnets[*].[{AZ:AvailabilityZone,SubnetId:SubnetId,CidrBlock:CidrBlock}, Tags[?Key=='Name']]" | grep -v '[]}[{]\|Name')
        n=0
	echo "            **************************************"
        printf '%s\n' "$output" | while IFS= read -r line
        do
	    if [ "$n" -eq 4 ]
	    then	    
	        echo "            **************************************"
		n=0
	    fi	
            echo "$line"
	    n=$((n+1))
        done

else
	output=$(aws --region us-west-2 ec2 describe-subnets --filters "Name=availabilityZone, Values=$az" --query "Subnets[*].[{AZ:AvailabilityZone,SubnetId:SubnetId,CidrBlock:CidrBlock}, Tags[?Key=='Name']]" | grep -v '[]}[{]\|Name')
	        n=0
        echo "            **************************************"
        printf '%s\n' "$output" | while IFS= read -r line
        do
            if [ "$n" -eq 4 ]
            then
                echo "            **************************************"
                n=0
            fi
            echo "$line"
            n=$((n+1))
        done

fi


