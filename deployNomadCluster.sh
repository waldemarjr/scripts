#!/bin/bash
###################
# CONFLOSS - 2024 #
###################
#
# por Waldemar Dibiazi Junior <waldemarjr@gmail.com>
#
# rev. 003
#
#

sleep 5

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

wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
apt update && sudo apt install nomad consul
check "install_nomad_consul"

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

sleep 3

echo "Waiting gluster volume..."
while [ true ]; do
  gluster volume list |grep nomadvolume 1> /dev/null 2> /dev/null
  if [ $? -eq 0 ]; then
    echo "Mount nomad gluster volume..."
    mount /data/nomad 1> /dev/null 2> /dev/null
    break
  else 
    echo "Volume nomadvolume not found"
  fi
  sleep 1
done
echo "Gluster volume mounted."

if [ `hostname -s` == "node01" ]; then
  echo "Nomad Server configuration..."
  SERVER_IP=`ip a s dev enp1s0 |grep "inet " | xargs |cut -f2 -d" " |cut -f1 -d/`
  wget https://raw.githubusercontent.com/waldemarjr/scripts/main/nomad_server.hcl.tpl -O /etc/nomad.d/server.hcl
  sed -i "s|SERVER_IP|$SERVER_IP|g" /etc/nomad.d/server.hcl
  systemctl enable nomad --now 
  check "nomad_server_service"
  echo "Consul Server configuration..."
  wget https://raw.githubusercontent.com/waldemarjr/scripts/main/rc-local.service -O /etc/systemd/system/rc-local.service
  wget https://raw.githubusercontent.com/waldemarjr/scripts/main/server_rc.local -O /etc/rc.local
  sed -i "s|SERVER_IP|$SERVER_IP|g" /etc/rc.local
  chmod +x /etc/rc.local
  systemctl daemon-reload
  systemctl enable rc-local --now
  check "consul_server_service"
else
  echo "Nomad Client configuration..."
  CLIENT_IP=`ip a s dev enp1s0 |grep "inet " | xargs |cut -f2 -d" " |cut -f1 -d/`
  SERVER_IP=`grep node01 /etc/hosts |cut -f1 -d" "`
  wget https://raw.githubusercontent.com/waldemarjr/scripts/main/nomad_client.hcl.tpl -O /etc/nomad.d/client.hcl
  sed -i "s|SERVER_IP|$SERVER_IP|g" /etc/nomad.d/client.hcl
  sed -i "s|CLIENT_IP|$CLIENT_IP|g" /etc/nomad.d/client.hcl
  systemctl enable nomad --now 
  check "nomad_client_service"
  echo "Consul Client configuration..."
  wget https://raw.githubusercontent.com/waldemarjr/scripts/main/consul_client.hcl.tpl -O /etc/consul.d/consul.hcl
  sed -i "s|SERVER_IP|$SERVER_IP|g" /etc/consul.d/consul.hcl 
  sed -i "s|CLIENT_IP|$CLIENT_IP|g" /etc/consul.d/consul.hcl 
  wget https://raw.githubusercontent.com/waldemarjr/scripts/main/rc-local.service -O /etc/systemd/system/rc-local.service
  wget https://raw.githubusercontent.com/waldemarjr/scripts/main/client_rc.local -O /etc/rc.local
  chmod +x /etc/rc.local
  systemctl daemon-reload
  systemctl enable rc-local --now
  check "consul_client_service"
fi
