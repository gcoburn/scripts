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
echo "WARNING PLEASE VERIFY THAT YOUR PUPPET MASTER VERSION IS SUPPORTED BEFORE PROCEEDING!" | tee -a prepPuppetMaster.log
read -e -p "Are you currently running Puppet Enterprise v3.0.1 to v3.2.2 or Open Source v3.2.4 to v3.6.2? y/n " PUPPETVERSION
if [ ${PUPPETVERSION} = "y" ]
    then
    read -e -p "Please enter your fully qualified App Services hostname or IP address: " HOSTNAME
    read -e -p "What major version of App Services are you running? (example 6.0, 6.1, 6.2) " VERSION
else
    tput setaf 1; echo "Your version of puppet is not yet supported or certified"; tput sgr 0
    exit 1
fi

# Detect the operating system in order to install the specific comonents needed$
if [[ -f /etc/redhat-release ]]
    then
    DL_CMD="yum -y install"
elif [[ -f /etc/lsb-release ]]
    then
    DL_CMD="apt-get install -y"
else
    tput setaf 1; echo "ERROR: We can not determine your operating system or it isn't supported for this script" | tee -a prepPuppetMaster.log ; tput sgr 0
    exit
fi

echo "installing wget, unzip, and ruby" | tee -a prepPuppetMaster.log
$DL_CMD wget ruby unzip

echo "downloading ruby script" | tee -a prepPuppetMaster.log
wget http://$HOSTNAME/artifacts/solutions/puppet/RegisterWithAppD.rb
chmod 777 ./RegisterWithAppD.rb

echo "creating symbolic link" | tee -a prepPuppetMaster.log
ln -s /usr/local/bin/puppet /usr/bin

#Verifying the successful download of all the tools.
# is the ruby script available
if [[ ! -f RegisterWithAppD.rb ]] ; then
    tput setaf 1; echo "ERROR: The ruby script needed to register this with application services did not successfully download. Please review the details in the log" | tee -a prepPuppetMaster.log ; tput sgr 0
    exit 1
fi

# Optional JRE and CLI, if yes we will download and configure both components for your environment
read -e -p "Optional: Would you like to download and configure JRE and the Application Servies CLI? y/n " OPTIONAL
if [ ${OPTIONAL} = "y" ]
    then
    # Calculate the JRE build number based off the version of Application Services deployed, if it is not 6.0 or above exit the script
    if [ ${VERSION} = "6.2" ]
        then JAVA="jre-1.7.0_72-"
    elif [ ${VERSION} = "6.1" ]
        then JAVA="jre-1.7.0_51-"
    elif [ ${VERSION} = "6.0" ]
        then JAVA="jre-1.7.0_45-"
    else
        tput setaf 1; echo "Your version of Application Services is not on the supported list to register with the puppet master. Supported versions include 6.0, 6.1, and 6.2" | tee -a prepPuppetMaster.log
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

    # Set the JRE file from the input data
    JRE=${JAVA}${KERNEL}
    echo "We will download the follwing JRE build $JRE" | tee -a prepPuppetMaster.log

    echo "downloading java runtime needed" | tee -a prepPuppetMaster.log
    wget http://$HOSTNAME/agent/$JRE

    echo "making jre directory" | tee -a prepPuppetMaster.log
    mkdir /opt/vmware-jre

    echo "unzipping jre to /opt/vmware-jre" | tee -a prepPuppetMaster.log
    unzip -d /opt/vmware-jre ./$JRE

    echo "downloading the darwin_cli.jar" | tee -a prepPuppetMaster.log
    wget http://$HOSTNAME/tools/darwin-cli.jar

    # is the darwin-cli.jar available
    if [[ ! -f darwin-cli.jar ]] ; then
        tput setaf 1; echo "ERROR: The darwin-cli.jar did not successfully download. Please review the details in the log" | tee -a prepPuppetMaster.log ; tput sgr0
        exit
    fi
    # is JAVA available
    if [[ ! -f /opt/vmware-jre/bin/java ]] ; then
        tput setaf 1; echo "ERROR: JRE is not available. Please review the details in the log" | tee -a prepPuppetMaster.log ; tput sgr 0
        exit
    fi

    echo "cleaning up JRE files" | tee -a prepPuppetMaster.log
    rm -f ./$JRE
else
    echo "You chose not to install the optional components" | tee -a prepPuppetMaster.log
fi

# Ready for puppet registration now
tput setaf 2; echo "All the components needed to register this puppet master with application services are ready" | tee -a prepPuppetMaster.log ; tput sgr 0

# Prompt user to verify if they wish to invoke the registration script
read -e -p "Do you wish to invoke the ruby registration script now? y/n " INVOKE
if [ ${INVOKE} = "y" ]
    then
    read -e -p "Please enter the business group that your admin user is a member of NOTE, IF THERE ARE SPACES IN THE NAME YOU MUST USE DOUBLE QUOTES: " GROUP
    read -e -p "Please enter your tenant NOTE, IF THERE ARE SPACES IN THE NAME YOU MUST USE DOUBLE QUOTES: " TENANT
    read -e -p "Please enter your deployment environment NOTE, IF THERE ARE SPACES IN THE NAME YOU MUST USE DOUBLE QUOTES: " DEPLOYMENTENV
    read -e -p "Please enter the userid that you used to create the cloud provider and deployment environment: " USERID
    read -s -e -p "Please enter the password: " PASSWORD
    ruby RegisterWithAppD.rb -i $HOSTNAME -u  -p $PASSWORD -t $TENANT -g $GROUP -d $DEPLOYMENTENV
else
    echo "Your puppet master is now ready to be registered with application services! Please review the README for next steps" | tee -a prepPuppetMaster.log
fi

# Write file for the next steps the user needs to take
echo "Next steps!" >> README
echo "Run the following commands - if you downloaded the CLI and JRE it can be done from this server, otherwise it can be run directly from Application Services:" >> README
echo "export JAVA_HOME=/opt/vmware-jre/bin/java" >> README
echo "export PATH=$PATH:/opt/vmware-jre/bin" >> README
echo "" >> README
echo "java -jar ./darwin-cli.jar" >> README
echo "" >> README
echo "Once the CLI is launched you will execute the following:" >> README
echo "login —username —password —serverUrl https://appServices.fqdn:8443/darwin" >> README
echo "import-puppet-manifests —typeFilter “^mysql$” —shared true" >> README

echo "All steps in the script have been completed and can be reviewed in the prepPuppetMaster.log. Review the README file created for the next steps to import manifests." | tee -a prepPuppetMaster.log





