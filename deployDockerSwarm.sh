#!/bin/bash

sleep 20

OUTPUT=/dev/ttyS0

writeLog(){
  echo $1 >> $OUTPUT
}

check(){
  if [ $? -eq 0 ]; then
    writeLog "$1: OK"
  else
    writeLog "$1: FAIL"
  fi
}

apt update 1> /dev/null 2> /dev/null
check "update"

apt install apt-transport-https ca-certificates curl gnupg lsb-release -y > /dev/null 2> /dev/null
check "install_others"

install -m 0755 -d /etc/apt/keyrings 1> /dev/null 2> /dev/null 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg 1> /dev/null 2> /dev/null 
check "install_gpg_docker_repo"

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
check "install_docker_repo"

apt update 1> /dev/null 2> /dev/null

sleep 5

apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 1> /dev/null 2> /dev/null
check "install_docker"

systemctl enable docker --now
check "enable_docker"

sleep 30

if [ `hostname -s` == "node01" ]; then
  docker swarm init --default-addr-pool 10.20.0.0/16 |grep "join --token"
else
  TOKEN=`cat /run/scripts/token.dat |cut -f1 -d;`
  MANAGER_IP=`cat /run/scripts/token.dat |cut -f2 -d";"`
  docker swarm join --token $TOKEN $MANAGER_IP:2377
fi

