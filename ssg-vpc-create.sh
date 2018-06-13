#!/bin/bash
# 
# 
# for SSG 


# version 0.0.4

shopt -s -o nounset
declare -rx SCRIPT=${0##*/}


### SET DEFAULTS HERE ###
name="ssg-noname"
subnet_count="2"
region=""
key_pair=""
# web tier ami 
# Amazon Linux AMI 2018.03.0 (HVM), SSD Volume Type - ami-922914f7
web_ami="ami-922914f7"
instance_type="t2.micro"

### END DEFAULTS ###


# Proccess paramaters

while [ $# -gt 0 ] ; do
        case "$1" in
        -h | --help)
                printf "%s\n" "usage: $SCRIPT  "
                printf "%s\n" "-n name of VPC to be created default "ssg-noname""
                printf "%s\n" "-s number of subnets to create in each AZ [1 or 2] default 2"
                printf "%s\n" "-r region to create VPC in default us-west-2 (Oregon)"
		printf "%s\n" "-k key pair name (requred)"
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

	-k ) shift
                if [ $# -eq 0 ] ; then
                printf "$SCRIPT:$LINENO: %s\n"  "-k requires a key pair name" >&2
                exit 192
                fi
                key_pair="$1"
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


# exite if -k not given
if [ -z "$key_pair" ]; then
    echo "-k required"
    exit 1
fi

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
echo "auto created route table id: $rtbid"


# create route in route-table to igw and tag it
aws --region $region ec2 create-route --route-table-id $rtbid --destination-cidr-block 0.0.0.0/0 --gateway-id $igwid 1>/dev/null
aws --region $region ec2 create-tags --resources $rtbid --tags Key=Name,Value=gw-dft-$name


# create route table for Private subnets
priv_route_table_id=`aws --region $region ec2 create-route-table --vpc-id $vpcid --output text --query 'RouteTable.RouteTableId'`
aws --region $region ec2 create-tags --resources $priv_route_table_id --tags Key=Name,Value=priv-sub
echo "route table for Private Subnets ID:  $priv_route_table_id"



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
    echo "public   AZ: $az subnetId: $subnetId net: 10.0.${third}.0/24" 
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
    
        # associate private subnet with private route table
        aws --region $region ec2 associate-route-table  --subnet-id $subnetId --route-table-id $priv_route_table_id 1>/dev/null
    fi

done


# find the default security-group that gets auto created with VPC creation 
sgid=$(aws ec2 --region $region  describe-security-groups --filter "Name=vpc-id,Values=$vpcid" --query "SecurityGroups[].GroupId" --output text)
echo "VPC security-group:         $sgid"


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


# create web-servers security-group
web_sg_id=$(aws --region $region ec2 create-security-group --group-name web-server --description "Group for 22, 80, and 443" --vpc-id $vpcid --output text)
echo "web-server security-group:  $web_sg_id"
# tag bigip web security-group
aws --region $region ec2 create-tags --resources $web_sg_id --tags Key=Name,Value=web-servers

# put inbound rules in web-servers security-group
aws --region $region ec2 authorize-security-group-ingress --group-id $web_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $web_sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $web_sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0

# create bastion security-group
bastion_sg_id=$(aws --region $region ec2 create-security-group --group-name bastion --description "Bastion group for 22" --vpc-id $vpcid --output text)
echo "bastion security-group:     $bastion_sg_id"
# tag bastion security-group
aws --region $region ec2 create-tags --resources $bastion_sg_id --tags Key=Name,Value=web-servers

# put inbound rules in bastion security-group
aws --region $region ec2 authorize-security-group-ingress --group-id $bastion_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0


# create ELB sg
elb_sg_id=$(aws --region $region ec2 create-security-group --group-name elb --description "ELB for 22, 80, and 443" --vpc-id $vpcid --output text)
echo "ELB  security-group:        $elb_sg_id"
aws --region $region ec2 create-tags --resources $elb_sg_id --tags Key=Name,Value=ELB-ssg

# put inbound rules in bigip elb security-group
aws --region $region ec2 authorize-security-group-ingress --group-id $elb_sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $elb_sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0
aws --region $region ec2 authorize-security-group-ingress --group-id $elb_sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0


# create ELB
echo "Creating ELB --load-balancer-name ssg-elb"
elb_create=`aws --region $region elb create-load-balancer --load-balancer-name ssg-elb --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" --subnets ${pubSubnets[@]} --security-groups $elb_sg_id`

# configure health check
health_check=`aws --region $region elb configure-health-check --load-balancer-name ssg-elb --health-check Target=TCP:22,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3`


# remove the listners
aws --region $region elb delete-load-balancer-listeners --load-balancer-name ssg-elb --load-balancer-ports 80


# create EIP for NAT GW for private subnets
nat_eip_id=`aws --region $region ec2 allocate-address --output text --query AllocationId`
echo "creating EIP for NAT GW: $nat_eip_id"
aws --region $region ec2 create-tags --resources $nat_eip_id --tags Key=Name,Value=NAT-GW


# create NAT GW
nat_id=`aws --region $region ec2 create-nat-gateway --subnet-id $pubSubnets --allocation-id $nat_eip_id --output text --query "NatGateway.NatGatewayId"`
echo "created NAT GW $nat_id"

# pausing to give NAT GW a little time to spin up
n=10
echo "Pausing $n seconds to give Nat Gateway time to spin up before adding to route table"
sleep $n


# create route in Pivate sub route-table to NAT and tag it
aws --region $region ec2 create-route --route-table-id $priv_route_table_id --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat_id 1>/dev/null
echo "adding 0.0.0.0/0 route to Privae subnet route table to point via NAT GW $nat_id"

## setup ASG web tier ##

#create launch config
aws --region $region autoscaling create-launch-configuration --launch-configuration-name ${name}-launch-config --key-name $key_pair --image-id $web_ami --instance-type $instance_type --user-data file://userdata/ssg-web-launch-config.txt --no-associate-public-ip-address --security-groups $web_sg_id

launch_conf_name=`aws --region $region autoscaling describe-launch-configurations --launch-configuration-names ${name}-launch-config --query "LaunchConfigurations[*].LaunchConfigurationName" --output text`

echo "Created Launch Config: $launch_conf_name"

# create ASG
# create csv list for of private subnets for ASG
csv_subnets=$(echo ${privSubnets[@]} | tr ' ' ',')

aws --region $region autoscaling create-auto-scaling-group --auto-scaling-group-name ${name}-asg --launch-configuration-name $launch_conf_name  --min-size 1 --max-size 3 --desired-capacity 1 --default-cooldown 300 --vpc-zone-identifier $csv_subnets

asg_name=$(aws --region $region autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${name}-asg --output text --query 'AutoScalingGroups[*].AutoScalingGroupName')
echo "Created ASG $asg_name"


## NEED to create scaling policies in the group aboube ##
## need to tag instances launced
## need work...


# Pre-DELETE VPC listx
echo " *** Before deleting VPC you will need to remove ***"
echo "aws --region $region elb delete-load-balancer --load-balancer-name ssg-elb"
echo "aws --region $region ec2 delete-nat-gateway --nat-gateway-id $nat_id"
echo "sleep 30"
echo "aws --region $region ec2 release-address --allocation-id $nat_eip_id"
echo "aws --region $region autoscaling delete-auto-scaling-group --auto-scaling-group-name ${name}-asg"
echo "aws --region $region autoscaling delete-launch-configuration --launch-configuration-name $launch_conf_name"
