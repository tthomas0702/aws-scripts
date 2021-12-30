# aws-scripts
This is sort of a junk drawer where I keep snippets and scripts that I use somtimes to work with AWS related lab setups.
Some scripts are in an abandoned or unfinished/untested state. 

vpcform.py			This creates a VPC and subnets to get started on a AWS lab setup. It also make SGs and routes.  

ssg-vpc-create.sh		create a VPC, ELB to load balance to BIG-IPs, subnets, ASG of web server as pool members for BIG-IP
				This lays a basic setup for use with BIG-IQ 6.x SSG and app deploys			
vpc-create.sh			Used to create a VPC and subnets, may may lack some flexibility 

describe-interfaces.sh
describe-subnets.sh
ls-az.sh
ls-regions.sh
userdata			Used by scripts to store data
userdata_examples


