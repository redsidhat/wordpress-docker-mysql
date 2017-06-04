#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
GRN='\033[0;32m'
YLW='\033[1;33m'
if [[ -z $1 ]]; then
	echo "${RED}Pass server name as '$1' and mysql password as '$2'. Exiting.${NC}"
	exit
fi
if [[ -z $2 ]]; then
	echo "${RED}Pass mysql password as '$2'. Exiting.${NC}"
	exit
fi
cd terraform
if [[ -z $3 ]]; then
	echo "${YLW}No custom public key filename is passed. \nUsing default publickey (~/.ssh/id_rsa.pub)${NC}"
	PUB_KEY_FILE="$HOME/.ssh/id_rsa.pub"
else
	echo "${YLW}Custom public key file path is $3${NC}"
	PUB_KEY_FILE="$3"
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
	exit
fi

echo "${YLW}Running \"terraform apply\"${NC}"
terraform apply
if [ $? -eq 0 ]; then
    echo "\n\n\"terraform apply\" ran ${GRN}OK\n${NC}"
else
	echo "\n\n\"terraform apply\" ${RED}Failed${NC}. Check above output for more details.\n"
	exit
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
LINE=`cat hosts| grep -n 'wp-docker'|grep -o '^[0-9]*'`
let "LINE++"
awk -v IP="$IP" -v LN="$LINE" 'NR==LN{print IP}1' hosts > hosts.new && mv hosts.new hosts
echo "${GRN}Added new IP to hosts file${NC}"


if [[ -z $4 ]]; then
	echo "${YLW}No custom private key filename is passed. \nUsing default publickey (~/.ssh/id_rsa)${NC}"
	PRIV_KEY_FILE="$HOME/.ssh/id_rsa"
else
	echo "${YLW}Custom private key file path is $3${NC}"
	PRIV_KEY_FILE="$3"
fi

if [ ! -f $PRIV_KEY_FILE ]; then
	echo "${RED}Private key ($PUB_KEY_FILE) is not found.${NC}"
	exit
fi

#Following will replaces privatekey file location ansible.cfg
REPLACE="private_key_file = $PRIV_KEY_FILE"
echo `cat ansible.cfg |sed -e "s|^private_key_file.*|$REPLACE|g" > ansible.cfg.bk && mv ansible.cfg.bk ansible.cfg`
#following edits the mysql dump
echo `cat roles/wordpress/files/wordpress.sql |sed -e "s|example8.com|$1|g" > roles/wordpress/files/wordpress.sql.bk && mv roles/wordpress/files/wordpress.sql.bk roles/wordpress/files/wordpress.sql`

echo "${YLW}Sleeping for 10 seconds before ansible ping\n${NC}\n"
sleep 10
echo "${YLW}Running ansible ping\n${NC}"
ansible wp-docker -i hosts -m ping
if [ $? -eq 0 ]; then
    echo "\n\n\"ansible ping\" ran ${GRN}OK\n${NC}"
else
	echo "\n\n\"ansible ping\" ${RED}Failed. \n${YLW}It could be becuase the aws ec2 instance is still initiating. Please retry.${NC}\nCheck above output for more details.\n"
	exit
fi


echo "${YLW}Applying ansible play-book\n${NC}"
ansible-playbook -i hosts --extra-vars "mysql_password=$2 server_name=$1" site.yml
