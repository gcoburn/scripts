#!/bin/bash
service tomcat6 shutdown
cd /usr/share/tomcat6/webapps
wget --no-check-certificate $warFile
service tomcat6 start
