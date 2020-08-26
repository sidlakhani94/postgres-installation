#!/bin/bash
#Author: Siddharth Lakhani
#Desctiption: Installation of Cassandra


read -p "Enter Cluster Name: " CLUSTER

#Updating current repository

sudo dnf update -y

#Installing Java

java -version &> /dev/null
if [ $? -ne 0 ]; then
    echo "*******Installing Java*********"
    sudo dnf install java-1.8.0-openjdk-devel -y
else
    echo "*******Java is Installed*******"
fi

#Installing Python

python --version &> /dev/null
if [ $? -ne 0 ]; then
    echo "********Installing Python******"
    sudo dnf install python2 -y
else
    echo "*******Python is Installed*****"
fi

#Adding Repository of Cassandra

sudo cp -r $PWD/cassandra.repo /etc/yum.repos.d/cassandra.repo
if [ -f "/etc/yum.repos.d/cassandra.repo" ]; then
    echo "************Installing Cassandra**********"
    sudo dnf install dsc20 -y
    echo "************Installation Completed********"
else
    echo "******Failed to Copy Cassandra Repository*******"
    exit
fi

#Adding Service File of Cassandra

sudo cp -r $PWD/cassandra.service /etc/systemd/system/cassandra.service
if [ -f "/etc/systemd/system/cassandra.service" ]; then
    sudo systemctl daemon-reload
else
    echo "*********Failed to Copy Cassandra Service File***********"
    exit
fi

#Starting Cassandra Service

sudo systemctl start cassandra
sudo systemctl enable cassandra

systemctl is-active --quiet cassandra
if [ $? -ne 0 ]; then
    echo "******Cassandra.service is inactive*******"
    exit
else
    echo "*******Cassandra.service is active********"
fi

#Checking Nodetools Status

mode=$(nodetool netstats | grep 'Mode' | awk '{print $2}')
if [[ "$mode" != "NORMAL" ]]; then
    echo "*****nodetools not working******"
    exit
else
    echo "****Cassandra Installed Successfully***********"
fi

#Configuring Local Cluster Name

sudo sed -i "s/cluster_name: 'Test Cluster'/cluster_name: '$CLUSTER'/g" /etc/cassandra/default.conf/cassandra.yaml
cqlsh -e "UPDATE system.local SET cluster_name = '$CLUSTER' WHERE KEY = 'local'"
nodetool flush system
sudo systemctl restart cassandra
echo "**********Configured Local Cluster Name*************"