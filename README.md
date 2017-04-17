# Simple completly automated wordpress deploying

This does the following

  - Launch a new servers in aws
  - configure the server with ansible
  - deploy a simple wordpress post

 -------each above points will be explained here-------

# Prerequisites
1. Terraform and ansible installed
2. Add ACCESS KEY and SECRET KEY in terraform/.creds
3. Default ssh key pair or custom new ones. 

# Usage
``
sh do_the_magic.sh VIRTUAL_HOSTNAME_FOR_WEBSITE PASSWORD_FOR_MYSQL optional [SSH_PUBLIC_KEY_FULLPATH SSH_PRIVATE_KEY_FULLPATH]
``
Server name or virtualhostname for youe website and mysql password are mandatory parameters. By default the script uses ~/.ssh/id_rsa and ~/.ssh/id_rsa.pub keypair. 
I have not tested the script with custom ssh key pair.

##### note: Known problems/improvements
* The script seems to fail in two steps when ran for the first time.  
  1. While ansible doing the ping for first time. This is becuase of the server is provisioned but not initialised compeltely
  2. While adding new database in docker myswl. I did not get enough time to figure out why this happenes.
Both cases running the script again will solve it.
* Wordpress uses root mysql creds
* Mysql password passed through terminal is a huge risk. Need to improve to configuration file or env varibales
* This solution is not throughly tested in all environments. This is ran and tested multiple times on macbook where binarys are based on BSD. (Sceptic about sed)
