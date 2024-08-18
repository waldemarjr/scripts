#!/bin/sh
#
###################
# CONFLOSS - 2024 #
###################
#
# por Waldemar Dibiazi Junior <waldemarjr@gmail.com>
#
# rev. 003
#

sleep 10

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

writeLog "Starting deploy..."

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

echo 'localhost:nomadvolume /data/nomad glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0' >> /etc/fstab
check "config_gluster_fstab"

systemctl daemon-reload

sleep 5

if [ `hostname -s` == "node01" ]; then
  node02Probe=0;
  node03Probe=0;
  
  while [ true ]; do
    echo "Starting probe nodes..."	  
    for node in node02 node03; do
      echo "Node: $node"

      while [ true ]; do
        ping $node -c4
      	timeout --preserve-status 2 telnet $node 24007 > /tmp/_result
        
        grep "Connected to" /tmp/_result 1> /dev/null 2> /dev/null
        if [ $? -eq 0 ]; then
           echo "Connected to peer $node: OK"
           break
        else
          echo "Connected to peer $node: FAIL"
        fi
        
        sleep 2
      done

      gluster peer probe $node 1> /dev/null 2>/dev/null
      check "probe_gluster_$node"
      if [ $node == "node02" -a $? -eq 0 ]; then
             node02Probe=1
      fi
      if [ $node == "node03" -a $? -eq 0 ]; then
             node03Probe=1
      fi     
      sleep 1
    done
    
    if [ $node02Probe -eq 1 -a $node03Probe -eq 1 ]; then
        echo "All probes done" >> $OUTPUT
        break;
    fi
    
    sleep 1
    
  done
  # Gluster volume create
  bash /run/scripts/glusterVolumeCreate.sh 1> /dev/null 2> /dev/null
  check "gluster_volume_create"
 
else
  echo OK
fi

sleep 5 
mount /data/nomad
