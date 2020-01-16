#!/bin/bash

# ver 0.0.1
# TODO
# 1) fix the help text to match script
# 2) add fucntion to list a specific security-group details

### SET DEFAULTS HERE ###
list=false
region="us-west-2"

### END DEFAULTS ###

shopt -s -o nounset
declare -rx SCRIPT=${0##*/}


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


    -l ) shift
      list=true
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


function list_security_groups_in_region {
  aws --region $region ec2 describe-security-groups --query 'SecurityGroups[*].GroupName'
}


main()
{
  if [ "$list" = true ]; then
    list_security_groups_in_region
  fi  
}
main "$@"



#aws --region us-west-2 ec2 describe-security-groups --query 'SecurityGroups[*].GroupName'


