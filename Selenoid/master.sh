#!/bin/bash
echo "install docker"
sudo apt-get remove docker docker-engine docker.io
sudo apt-get update
sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

sudo sed -i -e 's+ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock+ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:4243+g' /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo service docker restart
sudo curl http://localhost:4243/version




echo "run selenoid"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${HOME}:/root -e OVERRIDE_HOME=${HOME} aerokube/cm:latest-release selenoid start --vnc --tmpfs 128 --last-versions 2

echo "run selenoid-ui"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${HOME}:/root -e OVERRIDE_HOME=${HOME} aerokube/cm:latest-release selenoid-ui start --port 8181

echo "install java"
sudo apt update
sudo apt -y install openjdk-8-jdk

wget -p -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get -y install jenkins

echo "Skipping the initial setup"
echo 'JAVA_ARGS="-Djenkins.install.runSetupWizard=false"' >> /etc/default/jenkins

echo "Setting up users"
sudo rm -rf /var/lib/jenkins/init.groovy.d
sudo mkdir /var/lib/jenkins/init.groovy.d
sudo cp -v /vagrant/01_globalMatrixAuthorizationStrategy.groovy /var/lib/jenkins/init.groovy.d/
sudo cp -v /vagrant/02_createAdminUser.groovy /var/lib/jenkins/init.groovy.d/
sudo cp -v /vagrant/03_agentNodeLabel /var/lib/jenkins/init.groovy.d/

sudo service jenkins restart
sleep 1m

echo "Installing jenkins plugins"
JENKINSPWD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
rm -f jenkins_cli.jar.*
wget -q http://localhost:8080/jnlpJars/jenkins-cli.jar
while IFS= read -r line
do
  list=$list' '$line
done < /vagrant/jenkins-plugins.txt
java -jar ./jenkins-cli.jar -auth admin:$JENKINSPWD -s http://localhost:8080 install-plugin $list

echo "Restarting Jenkins"
sudo service jenkins restart

echo "initialAdminPassword"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

sudo add-apt-repository ppa:openjdk-r/ppa
sudo apt-get update
sudo apt -y install openjdk-11-jdk
sleep 1m
