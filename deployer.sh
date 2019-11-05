#!/bin/bash

printf "Hello:\t\t$USER\n"

rsa=/home/$USER/.ssh/id_rsa

printf "Please answer a few questions about the new deployment with y or n or else specified:\n"
read -p 'Will it be prod or dev environenment? ' env
read -p 'Will you use php? ' php
read -p 'Will you use local mysql? ' mysql
read -p 'Will you use local java? ' java
	if [ $java == y ] ; then
                read -p 'Please specify which java 8/11: ' javaversion
        fi

read -p 'Will you use new apache domain? ' apache
	if [ $apache == y ] ; then
                read -p 'Please provide the domain? ' domain
        fi

read -p 'Will you use backend server? ' backend
read -p 'Will you use frontend? ' frontend
read -p 'Will you use cms? ' cms


if [ $backend == y ] ; then
		printf " Example of repository: https://github.com/someuser/someproject.git\n"
		read -p 'Please provide the cloning repository for backend: ' backendrepo
		read -p 'Whats the backend port? ' backendport
	fi
if [ $frontend == y ] ;	then
		printf " Example of repository: https://github.com/someuser/someproject.git\n"
		read -p 'Please provide the cloning repository for backend: ' frontendrepo
	fi
if [ $cms == y ] ;   then
		printf " Example of repository: https://github.com/someuser/someproject.git\n"
                read -p 'Please provide the cloning repository for backend: ' cmsrepo
		read -p 'What is the cms alias? '  cmsalias
	fi



