#!/bin/bash

OUTPUT=/dev/ttyS0

writeLog(){
  echo $1 >> $OUTPUT
}

check(){
  if [ $? -eq 0 ]; then
    writeLog "update: OK"
  else
    writeLog "update: FAIL"
  fi
}

apt update 1> /dev/null 2> /dev/null
check

apt install mc -y 1> /dev/null 2> /dev/null
check
