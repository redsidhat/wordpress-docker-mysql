#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
GRN='\033[0;32m'
YLW='\033[1;33m'
cd terraform
if [[ -z $1 ]]; then
	echo "${YLW}No custom public key filename is passed. \nUsing default publickey (~/.ssh/id_rsa.pub)${NC}"
	PUB_KEY_FILE="$HOME/.ssh/id_rsa.pub"
else
	echo "${YLW}Custom public key file path is $1${NC}"
	PUB_KEY_FILE="$1"
fi

if [ ! -f $PUB_KEY_FILE ]; then
	echo "${RED}Publickey ($PUB_KEY_FILE) is not found.${NC}"
	exit 2
fi

PUB_KEY=`cat $PUB_KEY_FILE`

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
echo "${YLW}Getting IP from terraform${NC}"
IP=`terraform output | awk '{print $3}'`
echo "${GRN}IP: $IP ${NC}"
echo "${YLW}Switching directory to ansible${NC}"
cd ../ansible
echo "${YLW}cleaning up the hosts file if there is any old ips present in it${NC}"
#following or is for linux vs bsd
sed '/.*wp-docker\]$/,/^\[.*/{//!d;}' hosts > hosts.bk || sed '/.*wp-docker\]$/,/^\[.*/{//!d}' hosts>hosts.bk
mv hosts.bk hosts
awk -v IP=$IP 'NR==5{print IP}1' hosts > hosts.new && mv hosts.new hosts
echo "${GRN}Added new IP to hosts file${NC}"

