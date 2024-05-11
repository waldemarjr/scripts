#!/bin/bash
#
# Instalação do Docker
#
# Minicurso - Criando um cluster de aplicações utilizando containers Docker. 
#
# ETEC de Santa Rosa de Viterbo - 2024
#
# por Waldemar Dibiazi Junior
#
# Rev. 002
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


echo "--------------------------------"
echo "Iniciando a instalação do Docker"
echo "--------------------------------"
echo
echo

apt update 1> /dev/null 2> /dev/null
check "Atualizando pacotes do sistema..."

apt install apt-transport-https ca-certificates curl gnupg lsb-release -y > /dev/null 2> /dev/null
check "Instalando pacotes diversos..."

install -m 0755 -d /etc/apt/keyrings 1> /dev/null 2> /dev/null 
rm -f /etc/apt/keyrings/docker.gpg 1> /dev/null 2> /dev/null 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg 1> /dev/null 2> /dev/null 
check "Instalando chave de acesso a repositorio Docker..."

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
check "Instalando as configuracoes do repositorio Docker..."

apt update 1> /dev/null 2> /dev/null

sleep 5

apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 1> /dev/null 2> /dev/null
check "Instalando o Docker..." 

systemctl enable docker --now 1> /dev/null 2> /dev/null
check "Ativando o Docker para inicializar durante o boot do sistema..."
