#!/bin/bash

printf "Hello:\t\t$USER\n"
installer="sudo apt-get update "
rsa=/home/$USER/.ssh/id_rsa

printf "Please answer a few questions about the new deployment with y or n:\n"
read -p 'Will it be prod or dev environenment? ' env
read -p 'What is the project name? ' pname
read -p 'Please provide the domain? ' domain
read -p 'Will you use frontend? ' frontend

if [ $frontend == y ] ; then
      printf " Example of repository: https://github.com/someuser/someproject.git\n"
      read -p 'Please provide the cloning repository for backend: ' frontendrepo
      read -p 'Will you use php? ' php
           if [ $php == y ] ; then
                read -p 'Will you use composer? ' composer
                read -p 'Will you use npm? ' npm
            fi
              read -p 'Will you use npm? ' npm
            fi
read -p 'Will you use backend server? ' backend
  if [ $backend == y ] ; then
        read -p 'Will you use local java? ' java
        read -p 'Please specify which java 8/11: ' javaversion
        read -p 'Will you use npm? ' npm
        read -p 'Will you use local mysql? ' mysql
        printf " Example of repository: https://github.com/someuser/someproject.git\n"
        read -p 'Please provide the cloning repository for backend: ' backendrepo
        read -p 'Whats the backend port? ' backendport
    fi

read -p 'Will you use cms? ' cms
  if [ $cms == y ] ;   then
                printf " Example of repository: https://github.com/someuser/someproject.git\n"
                read -p 'Please provide the cloning repository for backend: ' cmsrepo
                read -p 'What is the cms alias? '  cmsalias
  fi


read -p 'Please provide the ssh user to connect: ' remoteuser
read -p 'Please provide the ssh port to use: ' sshport


ssh -tt "${remoteuser:=ubuntu}"@$domain -p"${sshport:=6776}"
exit
