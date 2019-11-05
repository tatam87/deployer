#!/bin/bash

printf "Hello:\t\t$USER\n"

user=$USER
rsa=/home/$USER/.ssh/id_rsa

printf " Please answer a few questions about the new deployment with y or n\n"

read -p 'Will you use php? ' php
read -p 'Will you use local mysql? ' mysql
read -p 'Will you use new apache domain? ' apache
read -p 'Please provide the domain to use? ' domain
read -p 'Will you use backend? ' backend
read -p 'Will you use frontend? ' frontend
read -p 'Will you use cms? ' cms
read -p 'Will you use proxy for backend? ' proxyb

if [ $backend == y ] ; then
		read -p 'please provide the cloning repository for backend? ' backendrepo
	fi
if [ $frontend == y ] ;	then
		read -p 'please provide the cloning repository for backend? ' frontendrepo
	fi
if [ $cms == y ] ;   then
                read -p 'please provide the cloning repository for backend? ' cmsrepo
	fi



