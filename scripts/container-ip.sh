#!/bin/bash
#
# container-ip - get the container's ip provided as argument
#
# usage: container-ip <container_name>
#
# Miguel Do Vale Lopes 21.05.2021

if [ $# -eq 0 ] 
then
  echo "Please provide a container's name"
  exit 1
fi

docker inspect "$1" | grep "\"IPAddress\"" | head -n 1 | sed "s/\(\"\|,\| \)//g" | cut -d ':' -f 2
exit 0
