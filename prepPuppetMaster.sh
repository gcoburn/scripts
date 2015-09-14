#!/bin/bash

# prepPuppetMaster Script is provided by Gary Coburn, Automation Specialist
#   This has been created to streamline the needed components
#   in order to register and import the manifests as services
#   into Application Services
# This is completely unsupported and has only been tested with the following components
# Application Services 6.1 and 6.2 (will test with 6.0 soon)
# PuppetMaster Enterprise 3.2.3
# CentOS and Ubuntu x64 (although x86 should work too)

# Initiate script, issue warnings and verify puppet master version
echo "WARNING PLEASE VERIFY THAT YOUR PUPPET MASTER VERSION IS SUPPORTED BEFORE PROCEEDING!"
read -e -p "Are you currently running Puppet Enterprise v3.0.1 to v3.2.2 or Open Source v3.2.4 to v3.6.2? y/n" PUPPETVERSION
if [ ${PUPPETVERSION} = "y" ]
    then
    read -e -p "Please enter your fully qualified App Services hostname or IP address: " HOSTNAME
    read -e -p "What major version of App Services are you running? (example 6.0, 6.1, 6.2) " VERSION
else
    tput setaf 1; echo "Your version of puppet is not yet supported or certified"; tput sgr 0
    exit 1
fi


# Calculate the JRE build number based off the version of Application Services deployed, if it is not 6.0 or above exit the script
if [ ${VERSION} = "6.2" ]
    then JAVA="jre-1.7.0_72-"
elif [ ${VERSION} = "6.1" ]
    then JAVA="jre-1.7.0_51-"
elif [ ${VERSION} = "6.0" ]
    then JAVA="jre-1.7.0_45-"
else
    tput setaf 1; echo "Your version of Application Services is not on the supported list to register with the puppet master. Supported versions include 6.0, 6.1, and 6.2"
    exit 1
fi

# Get the specific OS version (ie x86 or x86_64)
KERNEL=$(uname -m)
if [ ${KERNEL} = "x86_64" ]
    then
    KERNEL=lin64.zip
else
    KERNEL=lin32.zip
fi

# Detect the operating system in order to install the specific comonents needed$
if [[ -f /etc/redhat-release ]]
    then
    DL_CMD="yum -y install"
elif [[ -f /etc/lsb-release ]]
    then
    DL_CMD="apt-get install -y"
else
    tput setaf 1; echo "ERROR: We can not determine your operating system or it isn't supported for this script"; tput sgr 0
    exit
fi

# Set the JRE file from the input data
JRE=${JAVA}${KERNEL}
echo "We will download the follwing JRE build $JRE"

echo "installing wget, unzip, and ruby"
$DL_CMD wget ruby unzip

echo "downloading ruby script"
wget http://$HOSTNAME/artifacts/solutions/puppet/RegisterWithAppD.rb
chmod 777 ./RegisterWithAppD.rb

echo "downloading java runtime needed"
wget http://$HOSTNAME/agent/$JRE

echo "making jre directory"
mkdir /opt/vmware-jre

echo "unzipping jre to /opt/vmware-jre"
unzip -d /opt/vmware-jre ./$JRE

echo "exporting java path"
export JAVA_HOME=/opt/vmware-jre/bin/java
export PATH=$PATH:/opt/vmware-jre/bin

echo "creating symbolic link"
ln -s /usr/local/bin/puppet /usr/bin

echo "downloading the darwin_cli.jar"
wget http://$HOSTNAME/tools/darwin-cli.jar

#Verifying the successful download of all the tools.
# is the ruby script available
if [[ ! -f RegisterWithAppD.rb ]] ; then
    tput setaf 1; echo "ERROR: The ruby script needed to register this with application services did not successfully download. Please review the details in the log"; tput sgr 0
    exit
fi
# is the darwin-cli.jar available
if [[ ! -f darwin-cli.jar ]] ; then
    tput setaf 1; echo "ERROR: The darwin-cli.jar did not successfully download. Please review the details in the log"; tput sgr0
    exit
fi
# is JAVA available
if [[ ! -f /opt/vmware-jre/bin/java ]] ; then
    tput setaf 1; echo "ERROR: JRE is not available. Please review the details in the log"; tput sgr 0
exit
fi

echo "cleaning up files"
rm -f ./$JRE

tput setaf 2; echo "All the components needed to register this puppet master with application services are ready"; tput sgr 0

read -e -p "Do you wish to invoke the ruby registration script now? y/n" INVOKE
if [ ${INVOKE} = "y" ]
    then
    read -e -p "Please enter the business group that your admin user is a member of NOTE, IF THERE ARE SPACES IN THE NAME YOU MUST USE DOUBLE QUOTES: " GROUP
    read -e -p "Please enter your tenant NOTE, IF THERE ARE SPACES IN THE NAME YOU MUST USE DOUBLE QUOTES: " TENANT
    read -e -p "Please enter your deployment environment NOTE, IF THERE ARE SPACES IN THE NAME YOU MUST USE DOUBLE QUOTES: " DEPLOYMENTENV
    read -e -p "Please enter the userid that you used to create the cloud provider and deployment environment: " USERID
    read -s -e -p "Please enter the password: " PASSWORD
    ruby RegisterWithAppD.rb -i $HOSTNAME -u  -p $PASSWORD -t $TENANT -g $GROUP -d $DEPLOYMENTENV
else
    echo "The registration script is ready to be run when you are! Just execute ruby RegisterWithAppD.rb -i HOSTNAME -u UID -p PASS -t TENANT -g GROUP -d DEPLOYMENTENV"
fi

# Additional commands worth note, after you verified the puppet master is registered
# execute java -jar ./darwin-cli.jar
# login —username —password —serverUrl https://appServices.fqdn:8443/darwin
# import-puppet-manifests —typeFilter “^mysql$” —shared true