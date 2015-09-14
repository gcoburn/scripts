#!/bin/bash
yum -y install mysql-server
service mysqld start
chkconfig mysqld on
/usr/bin/mysqladmin -u root password '$1'
