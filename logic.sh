#!/bin/bash
path="/var/www/$pname/$env/"
ospath="/var/www/"

if [[ $backend -eq 0 ]] ;   then
  cat apache_backproxy_sample | sed "s|domain|$domain|g; s|frontend|$path$frontdir/dist|; s|backendport|$backendport|g; s|path|$path/$backdir|g" > $domain.conf
    if [[ $java -eq 0 ]] ;   then
      cat service_sample | sed "s|project|$pname|g; s|dir|$backdir|g; s|env|$env|g; s|pname|$pname|g; s|userch|$remoteuser|g; s|portc|$backendport|g" > $pname-$env.service
    fi
else
  cat apache_sample | sed "s|domain|$domain|g; s|backend|$path/$backdir|; s|path|$path$frontdir/dist|g" > $domain.conf
fi

if [[ $deployment -eq 0 ]] ;   then
 $sshd "$apachios && $installer && sudo mkdir -p -v $ospath$pname/$env && sudo chown -R $remoteuser:$remoteuser $ospath$pname/ && sudo chmod -R 775 $ospath$pname/"
fi

if [[ $rds -eq 0 ]] ; then
  mysql -u$rootuser -p$rootpasswd -h$rdshost -P $rdsport  "<<EOF
  CREATE DATABASE $bdshceme;
  CREATE USER '$mysqluser'@'%' IDENTIFIED BY '$sqluserpass';
  GRANT ALL PRIVILEGES ON $bdshceme.* TO '$mysqluser'@'%';
  FLUSH PRIVILEGES;
  exit
  EOF"

else
  if  [[ $mysql -eq 0 ]] ; then
	rootpasswd=$(whiptail --passwordbox "Please provide the root password you have or created on deployment:" 8  120 3>&1 1>&2 2>&3)
	$sshd "mysql -uroot -p${rootpasswd} <<EOF
	exit
	EOF"
	normallogin=$?
	$sshd "sudo mysql"
	sudologin=$?

	    if [ $normallogin -eq 0 ] ; then
		$sshd "mysql -uroot -p$rootpasswd  <<EOF
		CREATE DATABASE $bdshceme;
		CREATE USER '$mysqluser'@'%' IDENTIFIED BY '$sqluserpass';
		GRANT ALL PRIVILEGES ON $bdshceme.* TO '$mysqluser'@'%';
		FLUSH PRIVILEGES;
		exit
		EOF"
	    fi
	    if [ $sudologin -eq 0 ] ; then
                $sshd "sudo mysql  <<EOF
		ALTER USER 'root'@'%' IDENTIFIED BY '$rootpasswd';
                CREATE DATABASE $bdshceme;
                CREATE USER '$mysqluser'@'%' IDENTIFIED BY '$sqluserpass';
                GRANT ALL PRIVILEGES ON $bdshceme.* TO '$mysqluser'@'%';
                FLUSH PRIVILEGES;
                exit
                EOF"
          else
		echo "Something went wrong!"
		fi
  	   fi
fi
$sshd "$installer  && sudo mkdir -p -v $ospath$pname/$env && sudo chown $remoteuser:$remoteuser -R $ospath$pname/ && sudo chmod -R 775 $ospath$pname/ && sudo certbot certonly --apache -d$domain"

if [[ $repos =~ "front" ]] ;   then
    $sshd "cd $ospath$pname/$env/ && git clone $frontendrepo && cd $frontdir && git checkout $fbranch && git config credential.helper store && git pull"
      if [[ $backend == "y" ]] ; then
        $sshd "cd $ospath$pname/$env/$fbranch && cat src/config/config.js.sample | sed 's|/path/to/api|/api/v1/; s|http://localhost:8081|https://$domain|; s|dev|$env|' > src/config/config.js"
      else
          $sshd "cd $ospath$pname/$env/$fbranch && cat src/config/config.js.sample | sed 's|http://localhost:8081|https://$domain|; s|dev|$env|' > src/config/config.js"
      fi
    $sshd "cd $ospath$pname/$env/$frontdir/ && sh deploy-$env.sh"
    scp -P$sshport $domain.conf $remoteuser@$domain:~/
    $sshd "sudo mv $domain.conf /etc/apache2/sites-available/ && sudo a2ensite $domain && sudo systemctl reload apache2"
    rm $domain.conf
fi

if [[ $repos =~ "back" ]] ; then
    if [[ $java -eq 0 ]] ; then
            $sshd "cd $ospath$pname/$env/ && git clone $backendrepo && cd $backdir && git checkout $bbranch && cat src/main/resources/application.yaml.dist | sed 's|database_name|$bdshceme|; s|database_user|$mysqluser|; s|database_password|$sqluserpass|; s|spring_profile|$spring_profile|' > src/main/resources/application.yaml"
            scp -P$sshport $pname-$env.service  $remoteuser@$domain:~/
            $sshd "sudo mv $pname-$env.service /etc/systemd/system/ && sudo systemctl daemon-reload && cd $ospath$pname/$env/$backdir && git config credential.helper store && sh deploy-$env.sh"
            rm $pname-$env.service
    fi

    if [[ $php -eq 0 ]] ; then
      $sshd "cd $ospath$pname/$env/ && git clone $backendrepo && cd $backdir && git checkout $bbranch && cat config/config.php.sample | sed 's|database_name|$bdshceme|; s|database_user|$mysqluser|; s|database_password|$sqluserpass|' > config/config.php"
      $sshd "cd $ospath$pname/$env/$backdir && git config credential.helper store && sh deploy-$env.sh"

    fi
fi

if [[ $repos =~ "cms" ]] ; then
      $sshd "cd $ospath$pname/$env/ && git clone $cmsrepo && cd $cmsdir && git checkout $cbranch"
fi
rm $domain.conf
whiptail --title "Dear $USER" --msgbox "The deployer has finshed." 8 120
