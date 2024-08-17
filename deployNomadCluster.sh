#!/bin/bash

sleep 20

OUTPUT=/dev/ttyS0

writeLog(){
  echo $1 >> $OUTPUT
}

check(){
  if [ $? -eq 0 ]; then
    writeLog "$1: OK"
    return 0
  else
    writeLog "$1: FAIL"
    return 1
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

apt-get -y install  glusterfs-server glusterfs-common glusterfs-client  1> /dev/null 2> /dev/null
check "install_glusterfs"

mkdir /data/gv0 1> /dev/null 2> /dev/null
check "make_datadir_gluster"

mkdir /data/nomad 1> /dev/null 2> /dev/null
check "make_mountpoint_gluster"

systemctl enable glusterd --now 1> /dev/null 2> /dev/null
check "start_gluster_service"

sleep 5

if [ `hostname -s` == "node01" ]; then
  node02Probe=0;
  node03Probe=0;
  
  while [ true ]; do
    for node in node02 node03; do
      if [ $node02Probe -eq 0 -a $node == "node02" ]; then
        while [ true ]; do
          ping -c10 $node 1> /dev/null 2>/dev/null
          if [ $? -eq 0 ]; then
            break
          fi
          sleep 2
        done
        gluster peer probe $node
        check "probe_gluster_$node"
      elif [ $node03Probe -eq 0 -a $node == "node03" ]; then
        while [ true ]; do
          ping -c10 $node 1> /dev/null 2>/dev/null
          if [ $? -eq 0 ]; then
            break
          fi
          sleep 2
        done
        gluster peer probe $node
        check "probe_gluster_$node"
      fi  
      if [ $? -eq 0 ]; then
        if [ $node02Probe -eq 0 ]; then
          node02Probe=1
        fi
        if [ $node03Probe -eq 0 ]; then
          node03Probe=1
        fi
      fi
      sleep 15
    done
    if [ $node02Probe -eq 1 -a $node03Probe -eq 1 ]; then
        echo "OK" >> $OUTPUT
        break;
    fi
  done
  # Gluster volume create
  /run/scripts/glusterVolumeCreate.sh 1> /dev/null 2> /dev/null
  check "gluster_volume_create"
 
else
  echo OK
  #TOKEN=`cat /run/scripts/token.dat |cut -f1 -d";"`
  #MANAGER_IP=`cat /run/scripts/token.dat |cut -f2 -d";"`
  #docker swarm join --token $TOKEN $MANAGER_IP:2377
fi
