#!/bin/bash

# version 0.0.1
# This imports a certifcate into AWS region
# using cert and key pair
# This is needed if you want to use ssl on an ELB.

shopt -s -o nounset
declare -rx SCRIPT=${0##*/}


### SET DEFAULTS HERE ###
region=""
cert=""
key=""
### END DEFAULTS ###


# Proccess paramaters

while [ $# -gt 0 ] ; do
        case "$1" in
        -h | --help)
                printf "%s\n" "usage: $SCRIPT  "
                printf "%s\n" "-c location of certificate file"
                printf "%s\n" "-k location of private key file"
                printf "%s\n" "-r region to create VPC in default us-west-2 (Oregon)"
                printf "%s\n" "-h --help"
                printf "%s\n" "Example:"
                printf "%s\n\n" "$SCRIPT r us-east-1 -c /var/tmp/example.crt -k /var/tmp/example.key"

        exit 0
        ;;

        -c ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n" "value for -c missing" >&2
                exit 192
                fi
                cert="$1"
                ;;

       -k ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n" "value for -k is missing" >&2
                exit 192
                fi
                key="$1"
                ;;


      -r ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n" "value for -r is missing" >&2
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



# exit if missing -c, -k, -r
if [ -z "$cert" ]; then
    echo "-c required"
    exit 1
fi

if [ -z "$key" ]; then
    echo "-k required"
    exit 1
fi

if [ -z "$region" ]; then
    echo "-r required"
    exit 1
fi


cert_arn=$(aws --region $region acm import-certificate --certificate file://$cert --private-key file://$key --output text)

echo "cert in region $region"
echo ""

aws --region $region acm describe-certificate --certificate-arn $cert_arn







