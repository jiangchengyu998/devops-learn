#!/bin/bash

for (( i=1;i<10000;i++ ));
do
  curl http://192.168.101.102:8090/ping
  # curl http://192.168.101.102:8082/hello
  # curl http://192.168.101.102:8083/hello
  echo ""
  echo "sleep 0.5s"
  sleep 0.1
done