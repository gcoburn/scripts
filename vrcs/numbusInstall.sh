#/bin/bash
cd /opt/
wget http://usnx67.na.intranet.msd:8080/setupFiles/nimsoft-robot.x86_64.rpm
wget http://usnx67.na.intranet.msd:8080/setupFiles/nms-robot-vars.cfg
rpm -ivh nimsoft-robot.x86_64.rpm --prefix=/opt/nimsoft
/opt/nimsoft/nimsoft/install/RobotConfigurer.sh
service nimbus start
