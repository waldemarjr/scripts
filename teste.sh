#!/bin/bash

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

apt install mc -y 1> /dev/null 2> /dev/null
check "install_mc"
