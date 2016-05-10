#!/bin/bash
#riesal@gmail.com

clear

# always assume we run in 2 zone, A and B
DATACENTER=$1
AVAILZONE=( a b )

isDone() { echo -e "..DONE"; }

function createVPC() {

echo -e "Checking pre-requisites.."

isAwsCli="/usr/local/bin/aws"

if [[ -f "$isAwsCli" ]]; then
  echo -e "AWSCLI command found.. "
  echo -e ".. proceed."
else
  echo -e "AWSCLI command not found.. "
  echo -e ".. VPC installation aborted."
  exit 0
fi

aEIP=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query 'Addresses[*].PublicIp' --region $DATACENTER --output text  | awk '{print NF}' | sort -nu | tail -n 1)

if [[ $aEIP -ge 5 ]]; then
  echo -e "You have reach out maximum EIP quota, please set EIP quota to larger than 5.\nScript aborted.\n"
  exit 0
else
  echo -e "\nSetup VPC in $DATACENTER zone..\n.. this may take a while.\n"

  echo -e "Setup 192.168.0.0/16 cidr block"
  VPC_ID=$(aws ec2 create-vpc --cidr-block 192.168.0.0/16 --region $DATACENTER --output text | awk '{print $6}')
  isDone
  sleep 5

  VPC_STATE=$(aws ec2 describe-vpcs --region $DATACENTER --output text | grep $VPC_ID | awk '{print $6}')
  echo -e "VPC Status: $VPC_STATE\n"
  sleep 5  

  echo -e "Add Octopus $DATACENTER in VPC Tag"
  aws ec2 create-tags --resource $VPC_ID --tags Key=Name,Value="Octopus $DATACENTER" --region $DATACENTER
  sleep 1
  isDone

  echo -e "Setup internet gateway.."
  IGW_ID=$(aws ec2 create-internet-gateway --region $DATACENTER --output text | awk {'print $2'})
  sleep 5
  isDone

  echo -e "Attach the $IGW_ID internet-gateway to $VPC_ID"
  ATT_IGW_ID=$(aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $DATACENTER)
  sleep 1
  isDone

  echo -e "Setup 2 Public Subnets"

  cidrnum=0
  for i in "${AVAILZONE[@]}"
  do
    aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 192.168.$cidrnum.0/24 --region $DATACENTER --availability-zone $DATACENTER$i --output text | awk '{print $2}' | tr -d '[[:space:]]'
    echo -e "Public Subnet $i setup.. DONE"
    #ZONE_NAME=$(echo ''${i^^}'')
    #aws ec2 create-tags --resource $SUBNET_ID --tags Key=Name,Value="Public Subnet $i" --region $DATACENTER
    let cidrnum++
  done

  echo -e "\nSetup 2 Private Subnets"

  for j in "${AVAILZONE[@]}"
  do
    aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 192.168.$cidrnum.0/24 --region $DATACENTER --availability-zone $DATACENTER$j --output text | awk '{print $2}' | tr -d '[[:space:]]'
    echo -e "Private Subnet $j setup.. DONE"
    let cidrnum++
  done

  echo -e "\nAllocate New Elastic IP.."
  myEIP=$(aws ec2 allocate-address --domain vpc --region $DATACENTER --output text | awk '{print $1}' | tr -d '[[:space:]]')
  isDone

  echo -e "\nGet ID of Public Subnet A.."
  PUBLIC_SUBNET_A=$(aws ec2 describe-subnets --region $DATACENTER --output text | grep $VPC_ID | grep 192.168.0.0/24 | awk '{print $8}' | tr -d '[[:space:]]')
  isDone

  echo -e "\nSetup NAT Gateway to Public Subnet A"
  myNATGW=$(aws ec2 create-nat-gateway --subnet-id $PUBLIC_SUBNET_A --allocation-id $myEIP --region $DATACENTER --output text)
  isDone

  echo -e "\nGet all of public-subnet-id"
  pubSubnetA=$(aws ec2 describe-subnets --region $DATACENTER --output text | grep $VPC_ID | grep 192.168.0.0/24 | awk '{print $8}' | tr -d '[[:space:]]')
  pubSubnetB=$(aws ec2 describe-subnets --region $DATACENTER --output text | grep $VPC_ID | grep 192.168.1.0/24 | awk '{print $8}' | tr -d '[[:space:]]')
  isDone

  echo -e "\nGet the default route-table-id "
  rTableIdDef=$(aws ec2 describe-route-tables --region $DATACENTER --output text | grep $VPC_ID | awk '{print $2}' | tr -d '[[:space:]]')
  isDone

  echo -e "\nAssociate all public subnet with default table"
  aws ec2 associate-route-table --route-table-id $rTableIdDef --subnet-id $pubSubnetA --region $DATACENTER
  aws ec2 associate-route-table --route-table-id $rTableIdDef --subnet-id $pubSubnetB --region $DATACENTER
  isDone

  sleep 10

  echo -e "\nAdd routing rule for internet-gateway to default route"
  aws ec2 create-route --route-table-id $rTableIdDef --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $DATACENTER
  sleep 3
  isDone

  echo -e "\nSetup new route table for internal-access"
  rTableIdPri=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $DATACENTER --output text | grep ROUTETABLE | grep $VPC_ID | awk '{print $2}' | tr -d '[[:space:]]')
  isDone

  echo -e "\nNAT Gateway ID: $rTableIdPri \n"
  sleep 10

  echo -e "\nGet both of Private Subnet zone.."
  priSubnetA=$(aws ec2 describe-subnets --region $DATACENTER --output text | grep $VPC_ID | grep 192.168.2.0/24 | awk '{print $8}' | tr -d '[[:space:]]')
  priSubnetB=$(aws ec2 describe-subnets --region $DATACENTER --output text | grep $VPC_ID | grep 192.168.3.0/24 | awk '{print $8}' | tr -d '[[:space:]]')
  isDone

  sleep 5

  echo -e "\nAdd routing for 10.0.0.0/8 and nat-gateway"
  myNATGW=$(aws ec2 describe-nat-gateways --region $DATACENTER --output text | grep -v "NATGATEWAYADDRESS" | grep $VPC_ID | awk '{print $3}' | tr -d '[[:space:]]')
  sleep 3
  aws ec2 create-route --route-table-id $rTableIdPri --destination-cidr-block 0.0.0.0/0 --gateway-id $myNATGW --region $DATACENTER
  isDone

  echo -e "\nAssociate all public subnet with default table"
  aws ec2 associate-route-table --route-table-id $rTableIdPri --subnet-id $priSubnetA --region $DATACENTER
  aws ec2 associate-route-table --route-table-id $rTableIdPri --subnet-id $priSubnetB --region $DATACENTER

  echo -e "\n... New VPC $VPC_ID has been successfully setup, please wait at least 2 minute to get the internet gateway up and running"
  echo -e "... Thank you for using AWS.\n\n"
fi
}

if [[ $DATACENTER =~ 'us-west-1' ]]; then
  AVAILZONE=( a c )
  createVPC
elif [[ $DATACENTER =~ 'ap-northeast-1' ]]; then
  AVAILZONE=( b c )
  createVPC
else
  AVAILZONE=( a b )
  createVPC
fi
