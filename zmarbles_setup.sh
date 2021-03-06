#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


UP_DOWN="$1"
CH_NAME="$2"
CLI_TIMEOUT="$3"
IF_COUCHDB="$4"

: ${CLI_TIMEOUT:="10"}
: ${ZMARBLES_HOME:="`pwd`"}

export ZMARBLES_HOME

COMPOSE_FILE=docker-compose.yaml
COMPOSE_FILE_COUCH=docker-compose-couch.yaml

function printHelp () {
	echo "Usage: ./zmarbles_setup.sh <up|down|restart|init> <\$channel-name> <\$cli_timeout> <couchdb>"
        echo ""
        echo "The arguments must be in order."
        echo ""
        echo "up|down|restart|init is required"
        echo ""
        echo "\$channel-name defaults to mychannel"
        echo "\$cli_timeout defaults to 10 seconds"
        echo "couchdb will be used instead of leveldb if couchdb is specified"
        echo ""
        echo "up and down are self-explanatory"
        echo "restart combines 'down' and 'up'" 
        echo "init is intended for one-time use and gets the Hyperledger Fabric v1.0.3 Docker images"
        echo " and also gets the cryptogen and configtxgen binaries and puts them in a directory"
        echo " named 'bin' in your current directory."  
        echo ""
}

function validateArgs () {
	if [ -z "${UP_DOWN}" ]; then
		echo "Option up / down / restart / init not mentioned"
		printHelp
		exit 1
	fi
	if [ -z "${CH_NAME}" ]; then
		echo "setting to default channel 'mychannel'"
		CH_NAME=mychannel
	fi
}

function clearContainers () {
        CONTAINER_IDS=$(docker ps -aq)
        if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
                echo "---- No containers available for deletion ----"
        else
                docker rm -f $CONTAINER_IDS
        fi
}

function removeUnwantedImages() {
        DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
                echo "---- No images available for deletion ----"
        else
                docker rmi -f $DOCKER_IMAGE_IDS
        fi
}

function networkUp () {
    #Generate all the artifacts that includes org certs, orderer genesis block,
    # channel configuration transaction
    source generateArtifacts.sh $CH_NAME
    
    ./hostScripts/start-marblesUI.sh $CH_NAME 360 &

    if [ "${IF_COUCHDB}" == "couchdb" ]; then
      CHANNEL_NAME=$CH_NAME TIMEOUT=$CLI_TIMEOUT docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH up -d 2>&1
    else
      CHANNEL_NAME=$CH_NAME TIMEOUT=$CLI_TIMEOUT docker-compose -f $COMPOSE_FILE up -d 2>&1
    fi
    if [ $? -ne 0 ]; then
	echo "ERROR !!!! Unable to pull the images "
	exit 1
    fi
    docker logs -f cli
}

function networkDown () {
  
    if [ "${IF_COUCHDB}" == "couchdb" ]; then
      CHANNEL_NAME=$CH_NAME TIMEOUT=$CLI_TIMEOUT docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH down 2>&1
    else
      CHANNEL_NAME=$CH_NAME TIMEOUT=$CLI_TIMEOUT docker-compose -f $COMPOSE_FILE down 2>&1
    fi

    #Cleanup the chaincode containers
    clearContainers

    #Cleanup images
    removeUnwantedImages

    #shut down Marbles UI    
    ./hostScripts/stop-marblesUI.sh 

    # reset hashes in the Marbles UI configuration files
    ./hostScripts/clean-hash.sh

    # remove orderer block and other channel configuration transactions and certs
    rm -rf ~/.hfc-key-store/* channel-artifacts/*.block channel-artifacts/*.tx crypto-config docker-compose.yaml

}

function getBinariesAndDockerImages () {

  FABRIC_VERSION="$1"
  : ${FABRIC_VERSION:="1.1.0-preview"}
  
  case "${FABRIC_VERSION}" in
    1.1.0-preview) 
      ;;
    1.0.4) 
      ;;
    1.0.3)
      ;;
    1.0.2)
      ;;
    1.0.1)
      ;;
    1.0.0)
      ;;
    *) echo "invalid version specified with init argument"
       printHelp
       exit 1    
  esac
  
  VERSION=${FABRIC_VERSION} ./bootstrap.sh

}
        
validateArgs

#Create the network using docker compose
if [ "${UP_DOWN}" == "up" ]; then
	networkUp
elif [ "${UP_DOWN}" == "down" ]; then ## Clear the network
	networkDown
elif [ "${UP_DOWN}" == "restart" ]; then ## Restart the network
	networkDown
	networkUp
elif [ "${UP_DOWN}" == "init" ]; then ## Restart the network
	getBinariesAndDockerImages $2 
else
	printHelp
	exit 1
fi
