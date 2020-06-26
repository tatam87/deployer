#!/bin/bash

whiptail --title "Hello $USER" --msgbox "Before you start confirm tha A record for your domain exists and you have ssh access! There will be a lot of ssh conections so we will make ssh agent to handle them, please provide the ssh passphrase." 8 120

ssh-agent && ssh-add

installer="sudo apt-get update "
apachios="sudo apt-get install -y apache2 && sudo a2enmod alias ssl headers proxy proxy_fcgi proxy_http proxy_html rewrite xml2enc && sudo systemctl restart apache2 && sudo add-apt-repository ppa:certbot/certbot && sudo apt-get update && sudo apt-get install -y certbot python-certbot-apache "
rsa=/home/$USER/.ssh/id_rsa
apasimple=apache_sample
apaproxy=apache_backproxy_sample

whiptail --title "Hello $USER" --msgbox "Please answer the questions to continue the deployment." 8 120
env=$(whiptail --inputbox "Please provide the environment type dev/stage/prod:" 8  120 3>&1 1>&2 2>&3)
pname=$(whiptail --inputbox "What is the project name?" 8  120 3>&1 1>&2 2>&3)
domain=$(whiptail --inputbox "Please provide the domain ex test.test.com." 8  120 3>&1 1>&2 2>&3)
remoteuser=$(whiptail --inputbox "Please provide the ssh user to connect:" 8  120 3>&1 1>&2 2>&3)
sshport=$(whiptail --inputbox "Please provide the ssh port to use Default is 22:" 8  120 3>&1 1>&2 2>&3)
sshd="ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=22}""
deployment=$(whiptail --yesno "Is this the first time deploying on this server?" 8 120 3>&1 1>&2 2>&3 ; echo $?)
frontend=$(whiptail --yesno "Will you use frontend?"  8 120 3>&1 1>&2 2>&3 ; echo $?)
if [[ $frontend -eq 0 ]] ; then
    repos="${repos}front"
      frontendrepo=$(whiptail --inputbox "Please provide the cloning repository for frontend:	Example of repository: https://github.com/someuser/someproject.git" 10  120 3>&1 1>&2 2>&3)
      frontdir=`echo $frontendrepo | rev | cut -d / -f1 | rev|cut -d . -f1`
      fbranch=$(whiptail --inputbox "Please provide the branch:" 8  120 3>&1 1>&2 2>&3)
      npm=$(whiptail --yesno "Will you use npm?"  8 120 3>&1 1>&2 2>&3 ; echo $?)

        if [[ $npm -eq 0 ]] ; then
          installer="${installer} && sudo apt-get install -y npm nodejs && sudo npm -g install n && sudo n latest && sudo npm -g install yarn"
        fi
fi

backend=$(whiptail --yesno "Will you use backend?"  8 120 3>&1 1>&2 2>&3 ; echo $?)
  if [[ $backend -eq 0 ]] ; then
      repos="${repos}back"
      php=$(whiptail --yesno "Will you use php?" 8 120 3>&1 1>&2 2>&3 ; echo $?)
           if [[ $php -eq 0 ]] ; then
              installer="${installer}&& sudo apt-get install -y php-fpm php-curl php-bcmath php-intl php-json php-mbstring php-mysql php-soap php-xml php-zip"
	      composer=$(whiptail --yesno "Will you use composer?" 8 120 3>&1 1>&2 2>&3 ; echo $?)
                if [[ "$composer" -eq 0 ]] ; then
                  installer="${installer} composer "
                fi
           fi
      java=$(whiptail --yesno "Will you use Java?" 8 120 3>&1 1>&2 2>&3 ; echo $?)
   #fi

  if [[ $java -eq 0 ]] ; then

    javaversion=$(whiptail --inputbox "Please specify which java 8/11:" 8  120 3>&1 1>&2 2>&3 ; echo $?)
    installer="${installer} && sudo apt-get install -y openjdk-$javaversion-jdk maven"
    release=`$sshd "hostnamectl | grep Operating | sed 's/[^0-9]//g' | head -c 2"`

      if [[ $javaversion == "11" && $release == "16" ]]; then
        $sshd "sudo add-apt-repository ppa:linuxuprising/java && sudo apt-get update"
      fi
    spring_profile=$(whiptail --inputbox "Please specify the spring profile ex. prod:" 8  120 3>&1 1>&2 2>&3 ; echo $?)
  fi

  rds=$(whiptail --yesno "Will you use RDS?" 8 120 3>&1 1>&2 2>&3 ; echo $?)

  if [[ $rds -eq 0 ]] ; then
    rootuser=$(whiptail --inputbox "Please provide the RDS master user?" 8  120 3>&1 1>&2 2>&3)
    rootpasswd=$(whiptail --passwordbox "Please provide the RDS master password:" 8  120 3>&1 1>&2 2>&3)
    mysqluser=$(whiptail --inputbox "Please provide the rdsuser you want to create:" 8  120 3>&1 1>&2 2>&3)
    sqluserpass=$(whiptail --passwordbox "Please provide the rdpassword for the user you want to create:" 8  120 3>&1 1>&2 2>&3)
    bdshceme=$(whiptail --inputbox "Please provide the database name:" 8  120 3>&1 1>&2 2>&3)
    rdshost=$(whiptail --inputbox "Please provide the RDS host url:" 8  120 3>&1 1>&2 2>&3)
    rdsport=$(whiptail --inputbox "Please provide the RDS port:" 8  120 3>&1 1>&2 2>&3)
  fi
  mysql=$(whiptail --yesno "Will you use local mysql?" 8 120 3>&1 1>&2 2>&3 ; echo $?)
      if [[ $mysql -eq 0 ]] ; then
        installer="${installer} && sudo apt-get install -y mysql-server"
	mysqluser=$(whiptail --inputbox "Please provide the user you want to create:" 8  120 3>&1 1>&2 2>&3)
	sqluserpass=$(whiptail --passwordbox "Please provide the password for the user you want to create:" 8  120 3>&1 1>&2 2>&3)
	bdshceme=$(whiptail --inputbox "Please provide the database name:" 8  120 3>&1 1>&2 2>&3)
      fi

  backendrepo=$(whiptail --inputbox "Please provide the cloning repository for backend:   Example of repository: https://github.com/someuser/someproject.git" 10  120 3>&1 1>&2 2>&3)
  backdir=`echo $backendrepo | rev | cut -d / -f1 | rev|cut -d . -f1`
  bbranch=$(whiptail --inputbox "Please provide the branch:" 8  120 3>&1 1>&2 2>&3)
  backendport=$(whiptail --inputbox "Please provide the backend port:" 8  120 3>&1 1>&2 2>&3)

  cms=$(whipetail --yesno "Will you use CMS?" 8 120 3>&1 1>&2 2>&3 ; echo $?)
  if [[ $cms -eq 0 ]] ; then
      repos="${repos}cms"
      cmsrepo=$(whiptail --inputbox "Please provide the cloning repository for CMS:   Example of repository: https://github.com/someuser/someproject.git" 10  120 3>&1 1>&2 2>&3)
      cmsdir=`echo $cmsrepo | rev | cut -d / -f1 | rev|cut -d . -f1`
      cbranch=$(whiptail --inputbox "Please provide the branch:" 8  120 3>&1 1>&2 2>&3)
      cmsalias=$(whiptail --inputbox "What is the alias folder on apache for cms?" 8  120 3>&1 1>&2 2>&3)
  fi
fi
. logic.sh
