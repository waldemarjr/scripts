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
