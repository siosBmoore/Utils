#!/bin/bash

build() {
        scp bmoore@ci.sc.steeleye.com:/var/lib/jenkins/jobs/cloud-orchestrator-service/workspace/pkg/version /var/lib/jenkins/jobs/cloud-orchestrator-service/workspace/pkg/
        mvn clean install && cd pkg && make && cd ..
}

target=$1
shift
if [ -z "$target" ]
then
        echo "Please supply target machine"
        return
fi

echo "Building and deploying to $target"
build
if [ $? -eq 0 ]
then
        mkdir -p /home/ben/staging
        cd /home/ben/staging
        rm *
        apt-get update
        apt-get download cloud-orchestrator
        ssh -i /home/ben/cldo-sioss-rsa-4096 root@"$target" 'rm /home/sioss/cloud-orchestrator*.deb'
        scp -i /home/ben/cldo-sioss-rsa-4096 cloud-orchestrator*.deb root@"$target":/home/sioss
        ssh -i /home/ben/cldo-sioss-rsa-4096 root@"$target" 'cd /home/sioss/ && dpkg -i ./cloud-orchestrator*.deb'
        cd /mnt/c/Users/Ben/Work/cloud-orchestrator-service
        ssh -i /home/ben/cldo-sioss-rsa-4096 root@"$target" 'iptables -A INPUT -p tcp -m tcp --dport 9875 -j ACCEPT'
        ssh -i /home/ben/cldo-sioss-rsa-4096 root@"$target" 'iptables -A INPUT -p tcp -m tcp --dport 9881 -j ACCEPT'
fi
