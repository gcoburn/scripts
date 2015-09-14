#!/bin/bash
yum -y install nginx
service nginx start
chkconfig nginx on
