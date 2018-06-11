#!/bin/bash
# 
# 
# for SSG 


# version 0.0.2

### SET DEFAULTS HERE ###
name="ssg-noname"
subnet_count="2"
region="us-west-2"

### END DEFAULTS ###

shopt -s -o nounset
declare -rx SCRIPT=${0##*/}


# Proccess paramaters

while [ $# -gt 0 ] ; do
        case "$1" in
        -h | --help)
                printf "%s\n" "usage: $SCRIPT  "
                printf "%s\n" "-n name of VPC to be created default "ssg-noname""
                printf "%s\n" "-s number of subnets to create in each AZ [1 or 2] default 2"
                printf "%s\n" "-r region to create VPC in default us-west-2 (Oregon)"
                printf "%s\n" "-h --help"
                printf "%s\n\n" "Most switches are optional if set in the defaults section of the script"
                printf "%s\n" "Example:"
                printf "%s\n\n" "$SCRIPT -n devVPC -s 2 -r us-east-1"

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




echo "*** Creating VPC in Region $region ***"


# create the basic VPC and save vpc-ip to a var
vpcid_temp=$(aws ec2 --region $region create-vpc --cidr-block 10.0.0.0/16  --query "Vpc.VpcId")
# need to remove " from vpcid var
vpcid="${vpcid_temp%\"}"
vpcid="${vpcid#\"}"

echo "Created VPC $vpcid"


# give VPC Name tag
aws --region $region ec2 create-tags --resources $vpcid --tags Key=Name,Value=vpc-${name}
aws --region $region ec2 create-tags --resources $vpcid --tags Key=Purpose,Value="Deloping bash script"
aws --region $region ec2 create-tags --resources $vpcid --tags Key=sr,Value="SR name or number"


# create igw for vpc
igwid=$(aws --region $region ec2  create-internet-gateway --output text | awk '{print $2}')


# attach igw to VPC and tag it
aws --region $region ec2 attach-internet-gateway --vpc-id $vpcid --internet-gateway-id $igwid
aws --region $region ec2 create-tags --resources $igwid --tags Key=Name,Value=igw-$name


# get route-table-id VPC auto creates and use for the public subnets to get out to internet
rtbid=$(aws --region $region ec2  describe-route-tables --filters "Name=vpc-id,Values=$vpcid" --output text --query RouteTables[0].RouteTableId)
echo "route table id: $rtbid"


# create route in route-table to igw and tag it
aws --region $region ec2 create-route --route-table-id $rtbid --destination-cidr-block 0.0.0.0/0 --gateway-id $igwid 1>/dev/null
aws --region $region ec2 create-tags --resources $rtbid --tags Key=Name,Value=gw-dft-$name


## make subnets in each Availability Zone in VPC ##
# make a list of all Availibilty Zones in region
declare azlist=$(aws ec2 --region $region describe-availability-zones --output text --query "AvailabilityZones[].ZoneName")


# create var for third octect of IP network
third=0
declare -a pubSubnets
declare -a privSubnets

# loop through AZ list to create subnets
for az in $azlist ;
do

    # Make public default subnet for each az
    ((third+=1));
    subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block 10.0.${third}.0/24 --availability-zone $az) ;


    #tag public subnet
    subnetId=`echo $subnet_result | awk '{print $9}'`
    echo "public AZ: $az subnetId: $subnetId net: 10.0.${third}.0/24" 
    aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=public-${az} 


    # append subnetId to PubSubnets array
    pubSubnets+=("$subnetId")

    # enable auto assing mgmt IP on subnet
    # DISABLED
    #aws ec2 --region $region modify-subnet-attribute --subnet-id $subnetId --map-public-ip-on-launch


    # accociate route table to igw with public subnet 
    aws --region $region ec2 associate-route-table  --subnet-id $subnetId --route-table-id $rtbid 1>/dev/null

    # if -s 2 
    if [ "$subnet_count" = "2" ] 
        then
        # make private subnet for each az
        ((third+=1));
        subnet_result=$(aws ec2 --region $region --output text create-subnet --vpc-id $vpcid --cidr-block 10.0.${third}.0/24 --availability-zone $az) ;
        
        # append subnetId to privSubnets array
        privSubnets+=("$subnetId")
	

        #tag private subnet
        subnetId=`echo $subnet_result | awk '{print $9}'`
        echo "private  AZ: $az subnetId: $subnetId net: 10.0.${third}.0/24"
        aws --region $region ec2 create-tags --resources $subnetId --tags Key=Name,Value=private-${az}
    
        # ommenting out to not associate with route-table
        #aws --region $region ec2 associate-route-table  --subnet-id $subnetId --route-table-id $rtbid 1>/dev/null
    fi

done


# find the default security-group that gets auto created with VPC creation 
sgid=$(aws ec2 --region $region  describe-security-groups --filter "Name=vpc-id,Values=$vpcid" --query "SecurityGroups[].GroupId" --output text)
echo "VPC security-group: $sgid"


# describe and tag default security-group
aws --region $region ec2  create-tags --resources $sgid --tags Key=Name,Value=open-sg-${name}


# create mgmt security-group
mgmt_sg_id=$(aws --region $region ec2 create-security-group --group-name Bigip-mgmt --description "Group for 22, 443, and 8443" --vpc-id $vpcid --output text)
echo "big-ip-mgmt security-group: $mgmt_sg_id"
# tag bigip mgmt security-group
aws --region $region ec2 create-tags --resources $mgmt_sg_id --tags Key=Name,Value=bigip-mgmt


# put inbound rules in bigip mgmt security-group
aws --region $region ec2 authorize-security-group-ingress --group-id $mgmt_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $mgmt_sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $mgmt_sg_id --protocol tcp --port 8443 --cidr 0.0.0.0/0


# create ELB sg
elb_sg_id=$(aws --region $region ec2 create-security-group --group-name elb --description "ELB for 22, 80, and 443" --vpc-id $vpcid --output text)
echo "ELB  security-group: $elb_sg_id"
aws --region $region ec2 create-tags --resources $elb_sg_id --tags Key=Name,Value=ELB-ssg

# put inbound rules in bigip elb security-group
aws --region $region ec2 authorize-security-group-ingress --group-id $elb_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $elb_sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $elb_sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0


# create ELB
echo "Creating ELB ${name}-elb, you will need to remove this befoe you can delete the VPC"
echo "    aws --region $region elb delete-load-balancer --load-balancer-name ssg-elb"
elb_create=`aws --region $region elb create-load-balancer --load-balancer-name ssg-elb --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" --subnets ${pubSubnets[@]} --security-groups $elb_sg_id`

# configure health check
health_check=`aws --region $region elb configure-health-check --load-balancer-name ssg-elb --health-check Target=TCP:22,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3`


# remove the listners
aws --region $region elb delete-load-balancer-listeners --load-balancer-name ssg-elb --load-balancer-ports 80



# create NAT GW for private subnets
# create EIP
nat_eip_id=`aws --region $region ec2 allocate-address --output text --query AllocationId`
echo " creating EIP for NAT GW: $nat_eip_id"
aws --region $region ec2 create-tags --resources $nat_eip_id --tags Key=Name,Value=NAT-GW
echo " EIP need to be deleted before EIP can be deleted"
echo "    aws --region $region ec2 release-address --allocation-id $nat_eip_id"


# create NAT GW
nat_id=`aws --region $region ec2 create-nat-gateway --subnet-id $pubSubnets --allocation-id $nat_eip_id --output text --query "NatGateway.NatGatewayId"`
echo " created NAT GW $nat_id"
echo " to remove:"
echo "    aws --region $region ec2 delete-nat-gateway --nat-gateway-id $nat_id"


# next create route table for private subnet to point to NAT GW $nat_id 




# then ... ASG stuff for web server



