#!/bin/bash

CHANNEL=$1
DELAY=$2

if [ -z "${DELAY}" ]; then
  echo "Marbles UI starting up now"
else
  sleep ${DELAY}
  echo "Marbles UI starting up now after ${DELAY} second delay"
fi

CURRENT_DIR=`pwd`
cd ${ZMARBLES_HOME}/marblesUI/config
cp blockchain_creds1.json.template blockchain_creds1.json
cp blockchain_creds2.json.template blockchain_creds2.json
sed -i s/CHANNEL/${CHANNEL}/g blockchain_creds[12].json
cd ${ZMARBLES_HOME}/marblesUI
if [ ! -d "node_modules" ]; then
  npm install
fi 
nohup gulp marbles1 >marbles1.out 2>&1 &
nohup gulp marbles2 >marbles2.out 2>&1 &
cd ${CURRENT_DIR}

