#!/bin/bash
yum -y install tomcat6 tomcat6-webapps tomcat6-admin-webapps
service tomcat6 start
chkconfig tomcat6 on
