#!/bin/bash

printf "Hello:\t\t$USER\n"
installer="sudo apt-get update "
apachios="sudo apt-get install -y apache2 && sudo a2enmod alias ssl headers proxy proxy_fcgi proxy_http proxy_html rewrite xml2enc && sudo systemctl restart apache2 && sudo add-apt-repository ppa:certbot/certbot && sudo apt-get update && sudo apt-get install -y certbot python-certbot-apache "
rsa=/home/$USER/.ssh/id_rsa
apasimple=apache_sample
apaproxy=apache_backproxy_sample
printf "Please answer a few questions about the new deployment with y or n:\n"
read -p 'Please provide the environenment ex:prod/dev : ' env
read -p 'What is the project name? ' pname
read -p 'Please provide the domain? ' domain
read -p 'Is that the first time deployng on this server? ' deployment
read -p 'Will you use frontend? ' frontend

if [ $frontend == y ] ; then
    repos="${repos}front"
      printf " Example of repository: https://github.com/someuser/someproject.git\n"
      read -p 'Please provide the cloning repository for frontend: ' frontendrepo
      read -p "Please provide the branch: "  fbranch
      read -p 'Will you use php? ' php
           if [ $php == y ] ; then
                    installer="${installer}&& sudo apt-get install -y php-fpm php-curl php-bcmath php-intl php-json php-mbstring php-mysql php-soap php-xml php-zip"
                read -p 'Will you use composer? ' composer
                  if [ "$composer" == y ] ; then
                    installer="${installer} composer "
                  fi
            read -p 'Will you use npm? ' npm
              if [ $npm == y ] ; then
                installer="${installer} && sudo apt-get install -y npm nodejs && sudo npm -g install n && sudo n latest"
              fi
	fi
fi
read -p 'Will you use backend server? ' backend
  if [ $backend == y ] ; then
      repos="${repos}back"
        read -p 'Will you use local java? ' java
              if [ $java == y ] ; then
                read -p 'Please specify which java 8/11: ' javaversion
                installer="${installer} && sudo apt-get install -y openjdk-$javaversion-jdk maven"
              fi
	      if [ "$npm" != "y" ] ; then
        read -p 'Will you use npm? ' npm

        if [ $npm == y ] ; then
          installer="${installer} && sudo apt-get install -y npm && sudo npm -g install n && sudo npm -n latest"
        fi
	fi
        read -p 'Will you use local mysql? ' mysql
        if [ $mysql == y ] ; then
          installer="${installer} && sudo apt-get install -y mysql-server"
          read -p 'Please provide sql user: ' mysqluser
          read -p 'Please provide user password: ' sqluserpass
          read -p 'Please provide the database name: ' bdshceme
        fi
        printf " Example of repository: https://github.com/someuser/someproject.git\n"
        read -p 'Please provide the cloning repository for backend: ' backendrepo
        read -p "Please provide the branch: "  bbranch
        read -p 'Whats the backend port? ' backendport
    fi

read -p 'Will you use cms? ' cms
  if [ $cms == y ] ;   then
                repos="${repos}cms"
                printf " Example of repository: https://github.com/someuser/someproject.git\n"
                read -p 'Please provide the cloning repository for cms: ' cmsrepo
                read -p "Please provide the branch: "  cbranch
                read -p 'What is the cms alias? '  cmsalias
  fi


read -p 'Please provide the ssh user to connect: ' remoteuser
read -p 'Please provide the ssh port to use: ' sshport

path="\/var\/www\/$env\/$pname\/"
ospath="/var/www/"
servicepath="/etc/systemd/system/$env-$pname.service"

cat apache_sample | sed "s/domain/$domain/; s/path/$path/g" > $domain.conf
if [ $deployment == y ] ;   then
 ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "$apachios && $installer && sudo mkdir -p $ospath/$env/$pname && sudo chown $remoteuser:www-date -R $ospath/$env && sudo chmod -R 775 $$ospath/$env/"
  else
    ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "$installer  && sudo mkdir -p $ospath/$env/$pname && sudo chown $remoteuser:www-data -R $ospath/$env/ && sudo chmod -R 775 $ospath/$env/ "
  fi
case $repos in
    "front")
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd /$ospath/$env/$pname/ && git clone $frontendrepo"
    ;;
    "back")
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd /$ospath/$env/$pname/ && git clone $backendrepo"
    ;;
    "cms")
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd /$ospath/$env/$pname/ && git clone $cmsrepo"
    ;;
    "frontback")
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd /$ospath/$env/$pname/ && git clone $frontendrepo && git clone $backendrepo"
    ;;
    "frontbackcms")
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd /$ospath/$env/$pname/ git clone $frontendrepo && git clone $backendrepo && git clone $cmsrepo "
    ;;
    *)
  esac
rm $domain.conf
