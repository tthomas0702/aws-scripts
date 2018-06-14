#!/bin/bash


# usage:
# The first arg is the 4th oct for sefip
# The second arg is the 4th oct of floating selfip


### SET DEFAULTS HERE ###

### END DEFAULTS ###

shopt -s -o nounset
declare -rx SCRIPT=${0##*/}

if [ $# -eq 0 ] ; then
        printf "%s\n" "Type --help for help."
        exit 192
fi
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

