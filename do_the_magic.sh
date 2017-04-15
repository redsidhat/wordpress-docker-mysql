#!/bin/bash
cd terraform
if [[ -z $1 ]]; then
	echo "No custom public key filename is passed. \nUsing default publickey (~/.ssh/id_rsa.pub)"
	if [ ! -f ~/.ssh/id_rsa.pub ]; then
		echo "Default publickey (~/.ssh/id_rsa.pub) is not found."
	fi
	PUB_KEY=`cat ~/.ssh/id_rsa.pub`
else
	echo "Custom public key file path is $1"
	PUB_KEY=`cat $1`
	echo $PUB_KEY
fi
echo "Updating terraform keypair class with new public key"
REPLACE="  public_key = \\\"$PUB_KEY\\\""
#Following line does a simple sed replace in keypair.tf. 
#Did not use direct file replacement to ensure compatibility on linux and BSD based OSs
echo `cat keypair.tf |sed -e "s|.*public_key.*|$REPLACE|g" > keypair.tf.bk && mv keypair.tf.bk keypair.tf`
#echo `terraform plan`
