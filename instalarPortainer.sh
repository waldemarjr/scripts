#!/bin/bash
#
# Instalação do Orquestrador Portainer
#
# Minicurso - Criando um cluster de aplicações utilizando containers Docker. 
#
# Semana Paulo Freire - 2024
#
# ETEC de Santa Rosa de Viterbo - 2024
#
# Waldemar Dibiazi Junior <waldemar.junior3@etec.sp.gov.br>
#
# Rev. 003
#

writeLog(){
  echo $1
}


check(){
  if [ $? -eq 0 ]; then
    writeLog "$1: OK"
  else
    writeLog "$1: FAIL"
  fi
}


echo "------------------------------------------------"
echo "Iniciando a instalação do Orquestrador Portainer"
echo "------------------------------------------------"
echo
echo

rm -rf /data/orquestrador 1> /dev/null 2> /dev/null
mkdir -p /data/orquestrador 1> /dev/null 2> /dev/null
check "Criando diretório de dados e configurações do Orquestrador..."

docker network rm ClusterNet 1> /dev/null 2> /dev/null
docker network create -d overlay --subnet 10.0.10.0/24 ClusterNet 1> /dev/null 2> /dev/null
check "Criando rede virtual para utilização interna no Cluster..."

docker service rm orquestrador 1> /dev/null 2> /dev/null 
docker service create --name orquestrador -p 9000:9000 --constraint 'node.role == manager' --mount type=bind,src=/data/orquestrador,dst=/data --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock portainer/portainer -H unix:///var/run/docker.sock  1> /dev/null 2> /dev/null 
check "Instalando o Orquestrador Portainer..."

