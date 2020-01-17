#!/bin/bash

# ver 0.0.1
# TODO
#
# 1) add fucntion to list a specific security-group details

### SET DEFAULTS HERE ###
list=false
region=""

### END DEFAULTS ###

shopt -s -o nounset
declare -rx SCRIPT=${0##*/}


# Proccess paramaters
while [ $# -gt 0 ] ; do
  case "$1" in
    -h | --help)
      printf "%s\n" "usage: $SCRIPT  "
      printf "%s\n" "-l list all security-groups for the region given in -r"
      printf "%s\n" "-d describe details for security-group given (Not implimented yet"
      printf "%s\n" "-r region to list security-groups (required)"
      printf "%s\n" "-h --help"
      printf "%s\n\n" "<ADD INFO HERE>"
      printf "%s\n" "Example:"
      printf "%s\n\n" "$SCRIPT -l -r us-east-1"

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

# check for required options
if [ -z $region ]
then
  echo "option -r is required"
  exit 1
fi

function list_security_groups_in_region {
  aws --region $region ec2 describe-security-groups --query 'SecurityGroups[*].GroupName'
}


main()
{
  if [ "$list" = true ]
  then
    list_security_groups_in_region
  fi  
}
main "$@"



#aws --region us-west-2 ec2 describe-security-groups --query 'SecurityGroups[*].GroupName'


