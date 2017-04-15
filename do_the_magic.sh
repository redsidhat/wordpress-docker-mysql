#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
GRN='\033[0;32m'
YLW='\033[1;33m'
cd terraform
if [[ -z $1 ]]; then
	echo "${YLW}No custom public key filename is passed. \nUsing default publickey (~/.ssh/id_rsa.pub)${NC}"
	if [ ! -f ~/.ssh/id_rsa.pub ]; then
		echo "${RED}Default publickey (~/.ssh/id_rsa.pub) is not found.${NC}"
		exit 2
	fi
	PUB_KEY=`cat ~/.ssh/id_rsa.pub`
else
	echo "${YLW}Custom public key file path is $1${NC}"
	if [ ! -f $1 ]; then
		echo "${RED}Custom publickey ($1) is not found.${NC}"
		exit 2
	fi
	PUB_KEY=`cat $1`
#	echo $PUB_KEY
fi
echo "${YLW}Updating terraform keypair class with new public key${NC}"
REPLACE="  public_key = \\\"$PUB_KEY\\\""
#Following line does a simple sed replace in keypair.tf. 
#Did not use direct file replacement to ensure compatibility on linux and BSD based OSs
echo `cat keypair.tf |sed -e "s|.*public_key.*|$REPLACE|g" > keypair.tf.bk && mv keypair.tf.bk keypair.tf`
echo "${GRN}Updated keyfile.${NC} \n"
echo "${YLW}Running \"terraform plan\"${NC}"
terraform plan
if [ $? -eq 0 ]; then
    echo "\n\n\"terraform plan\" ran ${GRN}OK${NC}\n"
else
	echo "\n\n\"terraform plan\" ${RED}failed${NC}. Check above output for more details.\n"
	exit 2
fi

echo "${YLW}Running \"terraform apply\"${NC}"
terraform apply
if [ $? -eq 0 ]; then
    echo "\n\n\"terraform apply\" ran ${GRN}OK\n${NC}"
else
	echo "\n\n\"terraform apply\" ${RED}Failed${NC}. Check above output for more details.\n"
fi
IP=`terraform output | awk '{print $3}'`
