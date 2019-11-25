#!/bin/bash

printf "Hello $USER\n"
printf "\n\033[0;33mBefore you start confirm tha A record for your domain exists and you have ssh access !\033[0m\n"
printf "\n\033[0;33mThere will be a lot of ssh conections so we will make ssh agent to handle them, please provide the ssh passphrase.\033[0m\n"
echo "----------------------------"
ssh-agent && ssh-add
installer="sudo apt-get update "
apachios="sudo apt-get install -y apache2 && sudo a2enmod alias ssl headers proxy proxy_fcgi proxy_http proxy_html rewrite xml2enc && sudo systemctl restart apache2 && sudo add-apt-repository ppa:certbot/certbot && sudo apt-get update && sudo apt-get install -y certbot python-certbot-apache "
rsa=/home/$USER/.ssh/id_rsa

apasimple=apache_sample
apaproxy=apache_backproxy_sample

printf "\n\033[0;33mPlease answer the questions for deployment with y or n or as suggested. \033[0m\n"
read -e -i "prod" -p 'Please provide the environment type dev/stage/prod: ' env
read -e -i "someproject" -p 'What is the project name? ' pname
read -e -i "test.test.com" -p 'Please provide the domain? ' domain
read -e -i "ubuntu" -p 'Please provide the ssh user to connect: ' remoteuser
read -e -i "6776" -p 'Please provide the ssh port to use: ' sshport
read -e -i "y" -p 'Is that the first time deployng on this server? ' deployment

echo "----------------------------"
read -e -i "y" -p 'Will you use frontend? ' frontend

if [ $frontend == y ] ; then
    repos="${repos}front"
      printf " Example of repository: https://github.com/someuser/someproject.git\n"
      read -p 'Please provide the cloning repository for frontend: ' frontendrepo
      frontdir=`echo $frontendrepo | rev | cut -d / -f1 | rev|cut -d . -f1`
      read -e -i "$env" -p "Please provide the branch: "  fbranch
      read -e -i "y" -p 'Will you use npm? ' npm
        if [ $npm == y ] ; then
          installer="${installer} && sudo apt-get install -y npm nodejs && sudo npm -g install n && sudo n latest && sudo npm -g install yarn"
        fi
fi

echo "----------------------------"

read -e -i "y" -p 'Will you use backend server? ' backend
  if [ $backend == y ] ; then
      repos="${repos}back"
      read -e -i "n" -p 'Will you use php? ' php
           if [ $php == y ] ; then
              installer="${installer}&& sudo apt-get install -y php-fpm php-curl php-bcmath php-intl php-json php-mbstring php-mysql php-soap php-xml php-zip"
              read -e -i "y" -p 'Will you use composer? ' composer
                if [ "$composer" == y ] ; then
                  installer="${installer} composer "
                fi
          fi
 fi

 read -e -i "y" -p 'Will you use java? ' java

  if [ $java == "y" ] ; then
    read -e -i "11" -p 'Please specify which java 8/11: ' javaversion
    installer="${installer} && sudo apt-get install -y openjdk-$javaversion-jdk maven"
    release=`ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "hostnamectl | grep Operating | sed 's/[^0-9]//g' | head -c 2"`

      if [[ $javaversion == "11" && $release == "16" ]]; then
        ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "sudo add-apt-repository ppa:linuxuprising/java && sudo apt-get update"
      fi
    read -e -i "prod" -p 'Please provide the spring profile: ' spring_profile
  fi
  read -e -i "n" -p 'Will you use RDS: ' rds
  if [ $rds == "y" ] ; then
    read -p 'Please provide the RDS master user: ' rootuser
    read -p 'Please provide the RDS master password: ' rootpasswd
    read -p 'Please provide the rdsuser you want to create: ' mysqluser
    read -p 'Please provide the RDS user pasword you want to create: ' sqluserpass
    read -p 'Please provide the database name: ' bdshceme
    read -p 'Please provide the RDS host url: ' rdshost
    read -p 'Please provide the RDS port: ' rdsport
  else
    read -e -i "y" -p 'Will you use mysql on the server? ' mysql
      if [ $mysql == "y" ] ; then
        installer="${installer} && sudo apt-get install -y mysql-server"
        read -p 'Please provide sql user: ' mysqluser
        read -sp 'Please provide user password: ' sqluserpass
        read -p 'Please provide the database name: ' bdshceme
      fi
  fi
  printf " Example of repository: https://github.com/someuser/someproject.git\n"
  read -p 'Please provide the cloning repository for backend: ' backendrepo
  backdir=`echo $backendrepo | rev | cut -d / -f1 | rev|cut -d . -f1`
  read -e -i "$env" -p "Please provide the branch: "  bbranch
  read -e -i "5000" -p 'Whats the backend port? ' backendport

echo "----------------------------"

read -e -i "n" -p 'Will you use cms? ' cms
  if [ $cms == y ] ;   then
      repos="${repos}cms"
      printf " Example of repository: https://github.com/someuser/someproject.git\n"
      read -p 'Please provide the cloning repository for cms: ' cmsrepo
      cmsdir=`echo $cmsrepo | rev | cut -d / -f1 | rev|cut -d . -f1`
      read -e -i "$env" -p "Please provide the branch: "  cbranch
      read -p 'What is the cms alias? '  cmsalias
  fi

. logic.sh
