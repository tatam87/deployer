#!/bin/bash

printf "Hello $USER\n"
printf "\n\033[0;33mBefore you start confirm tha A record for your domain exists and you have ssh access !\033[0m\n"
printf "\n\033[0;33mThere will be a lot of ssh conections so we will make ssh agent to handle them, please provide the ssh passphrase.\033[0m\n"
echo "----------------------------"
ssh-agent && ssh-add
installer="sudo apt-get update && sudo apt-get install -y rpl "
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

  if [ $java == y ] ; then
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


#path="\/var\/www\/$pname\/$env\/"
path="/var/www/$pname/$env/"
ospath="/var/www/"

if [ $backend == "y" ] ;   then
  cat apache_backproxy_sample | sed "s|domain|$domain|g; s|backendport|$backendport|g; s|path|$path/$backdir|g" > $domain.conf
  cat service_sample | sed "s|project|$pname|g; s|dir|$backdir|g; s|env|$env|g; s|pname|$pname|g; s|portc|$backendport|g" > $pname-$env.service
else
  cat apache_sample | sed "s|domain|$domain|g; s|backend|$path/$backdir|; s|path|$path|g" > $domain.conf
fi

if [ $deployment == "y" ] ;   then
 ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "$apachios && $installer && sudo mkdir -p -v $ospath$pname/$env && sudo chown -R $remoteuser:$remoteuser $ospath$pname/ && sudo chmod -R 775 $ospath$pname/"
fi

if [ $rds == "y" ] ; then
mysql -u$rootuser -p$rootpasswd -h$rdshost -p$rdsport  "<<EOF
CREATE DATABASE $bdshceme;
CREATE USER '$mysqluser'@'localhost' IDENTIFIED BY '$sqluserpass';
GRANT ALL PRIVILEGES ON $bdshceme.* TO '$mysqluser'@'localhost';
FLUSH PRIVILEGES;
exit
EOF"

else
  if  [ $mysql == "y" ] ; then
    read -sp 'Please provide the root mysql password you have or created on deployment: ' rootpasswd
    ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "mysql -uroot -p${rootpasswd}  <<EOF
    CREATE DATABASE $bdshceme;
    CREATE USER '$mysqluser'@'localhost' IDENTIFIED BY '$sqluserpass';
    GRANT ALL PRIVILEGES ON $bdshceme.* TO '$mysqluser'@'localhost';
    FLUSH PRIVILEGES;
    exit
    EOF"
  fi
fi
ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "$installer  && sudo mkdir -p -v $ospath$pname/$env && sudo chown $remoteuser:$remoteuser -R $ospath$pname/ && sudo chmod -R 775 $ospath$pname/ && sudo certbot certonly --apache -d$domain"

if [[ $repos =~ "front" ]] ;   then
    ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd $ospath$pname/$env/ && git clone $frontendrepo && cd $frontdir && git checkout $fbranch"
      if [[ $backend == "y" ]]
        ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd $ospath$pname/$env/$fbranch && cat src/config/config.js.sample | sed 's|/path/to/api|/api/v1/; s|http://localhost:8081|https://$domain|; s|dev|$env|' > src/config/config.js"
      else
          ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd $ospath$pname/$env/$fbranch && cat src/config/config.js.sample | sed 's|http://localhost:8081|https://$domain|; s|dev|$env|' > src/config/config.js"
      fi
    ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd $ospath$pname/$env/$frontdir/ && sh deploy-$env.sh"
    scp -P$sshport $domain.conf $remoteuser@$domain:~/
    ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "sudo mv $domain.conf /etc/apache2/sites-available/ && sudo a2ensite $domain && sudo systemctl reload apache2"
    rm $domain.conf
fi

if [[ $repos =~ "back" ]] ; then
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd $ospath$pname/$env/ && git clone $backendrepo && cd $backdir && git checkout $bbranch && cat src/main/resources/application.yaml.dist | sed 's|database_name|$bdshceme|; s|database_user|$mysqluser|; s|database_password|$sqluserpass|; s|spring_profile|$spring_profile|' > src/main/resources/application.yaml"
      scp -P$sshport $pname-$env.service  $remoteuser@$domain:~/
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "sudo mv $pname-$env.service /etc/systemd/system/ && sudo systemctl daemon-reload && cd $ospath$pname/$env/$bbranch && sh deploy-$env.sh"
      rm $pname-$env.service
fi

if [[ $repos =~ "cms" ]] ; then
      ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}" "cd $ospath$pname/$env/ && git clone $cmsrepo && cd $cmsdir && git checkout $cbranch"
fi
rm $domain.conf
