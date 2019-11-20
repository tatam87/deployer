#!/bin/bash

printf "Hello: $USER\n"

installer="sudo apt-get update "
apachios="sudo apt-get install -y apache2 && sudo a2enmod alias ssl headers proxy proxy_fcgi proxy_http proxy_html rewrite xml2enc && sudo systemctl restart apache2 && sudo add-apt-repository ppa:certbot/certbot && sudo apt-get update && sudo apt-get install -y certbot python-certbot-apache "
rsa=/home/$USER/.ssh/id_rsa

apasimple=apache_sample
apaproxy=apache_backproxy_sample

printf "Please answer a few questions about the new deployment with y or n:\n"
read -p 'Please provide the environment type dev/stage/prod :' env
read -p 'What is the project name? ' pname
read -p 'Please provide the domain? ' domain
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
      read -e -i "y" -p 'Will you use yarn for frontend? ' yarnf
fi

echo "----------------------------"

read -e -i "y" -p 'Will you use backend server? ' backend
  if [ $backend == y ] ; then
      repos="${repos}back"
      read -e -i "y" -p 'Will you use php? ' php
           if [ $php == y ] ; then
                installer="${installer}&& sudo apt-get install -y php-fpm php-curl php-bcmath php-intl php-json php-mbstring php-mysql php-soap php-xml php-zip"
                read -e -i "y" -p 'Will you use composer? ' composer
                  if [ "$composer" == y ] ; then
                    installer="${installer} composer "
                  fi
          fi
 fi

 read -e -i "y" -p 'Will you use local java? ' java

  if [ $java == y ] ; then
    read -e -i "11" -p 'Please specify which java 8/11: ' javaversion
    installer="${installer} && sudo apt-get install -y openjdk-$javaversion-jdk maven"
  fi

	if [ "$npm" != "y" ] ; then
        read -e -i "y" -p 'Will you use npm? ' npm
        if [ $npm == y ] ; then
          installer="${installer} && sudo apt-get install -y npm && sudo npm -g install n && sudo n latest && sudo npm -g install yarn"
        fi
  read -e -i "y" -p 'Will you use yarn for backend? ' yarnb
	fi

  read -e -i "y" -p 'Will you use local mysql? ' mysql
    if [ $mysql == y ] ; then
      installer="${installer} && sudo apt-get install -y mysql-server"
      read -p 'Please provide sql user: ' mysqluser
      read -sp 'Please provide user password: ' sqluserpass
      read -p 'Please provide the database name: ' bdshceme
    fi

  printf " Example of repository: https://github.com/someuser/someproject.git\n"
  read -p 'Please provide the cloning repository for backend: ' backendrepo
  backdir=`echo $backendrepo | rev | cut -d / -f1 | rev|cut -d . -f1`
  read -e -i "$env" -p "Please provide the branch: "  bbranch
  read -p 'Whats the backend port? ' backendport

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


read -e -i "ubuntu" -p 'Please provide the ssh user to connect: ' remoteuser
read -e -i "6776" -p 'Please provide the ssh port to use: ' sshport

path="\/var\/www\/$pname\/$env\/"
ospath="/var/www/"

if [ $backend == y ] ;   then
  cat apache_backproxy_sample | sed "s/domain/$domain/g; s/backendport/$backendport/g; s/path/$path/g" > $domain.conf
  cat service_sample | sed "s/project/$pname/g; s/dir/$backdir/g; s/env/$env/g; s/pname/$pname/g; s/portc/$backendport/g" > $pname.service
fi

cat apache_sample | sed "s/domain/$domain/g; s/backend/$path\/$backdir/; s/path/$path/g" > $domain.conf

if [ $deployment == y ] ;   then
 ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "$apachios && $installer && sudo mkdir -p /$ospath/$pname/$env && sudo chown -R $remoteuser:www-data /$ospath/$pname/ && sudo chmod -R 775 /$ospath/$pname/"
fi

ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "$installer  && sudo mkdir -p $ospath/$pname/$env && sudo chown $remoteuser:www-data -R /$ospath/$pname/ && sudo chmod -R 775 /$ospath/$pname/"

if [[ $repos =~ "front" ]] ;   then
    ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd /$ospath/$pname/$env/ && git clone $frontendrepo && cd $frontdir && git checkout $fbranch"
      if [ $yarnf == y ] ; then
            ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd /$ospath/$pname/$env/$frontdir/"
      fi
    scp -P$sshport $domain.conf $remoteuser@$domain:~/
    ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "sudo mv $domain.conf /etc/apache2/sites-available/ && sudo a2ensite $domain && sudo systemctl reload apache2"
fi

if [[ $repos =~ "back" ]] ; then
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd /$ospath/$pname/$env/ && git clone $backendrepo && cd $backdir && git checkout $bbranch"
      scp -P$sshport $pname.service  $remoteuser@$domain:~/
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "sudo mv $pname.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl start $pname"

        if  [ $mysql == y ] ; then
          read -sp 'Please provide the root mysql password you have or created on deployment: ' rootpasswd
          ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "mysql -uroot -p${rootpasswd}  <<EOF
          CREATE DATABASE $bdshceme
          CREATE USER ${mysqluser}@localhost IDENTIFIED BY '${sqluserpass}'
          GRANT ALL PRIVILEGES ON ${bdshceme}.* TO '${mysqluser}'@'localhost'
          FLUSH PRIVILEGES;
          EOF"
        fi
fi

if [[ $repos =~ "cms" ]] ; then
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd /$ospath/$pname/$env/ && git clone $cmsrepo && cd $cmsdir && git checkout $cbranch"
fi
