#!/bin/bash

#export java so the call from jenkins works
export PATH=$PATH:/opt/vmware-jre/bin

#go into the cloud client directory
cd /opt/vmware/cloudclient/

#execute the application request so the new build gets pulled from the binary repository
./cloudclient.sh vra catalog request submit --groupid '"Biteback Corp IT"' --id '"Bass Player Search"' --description $1 --reason testing --export /root/catalogRequest.txt

