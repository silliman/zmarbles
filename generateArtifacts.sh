#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


#set -e

CHANNEL_NAME=$1
: ${CHANNEL_NAME:="mychannel"}

: ${FABRIC_ROOT:="../git/src/github.com/hyperledger/fabric"}
echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

## Using docker-compose template replace private key file names with constants
function replacePrivateKey () {
	ARCH=`uname -s | grep Darwin`
	if [ "$ARCH" == "Darwin" ]; then
		OPTS="-it"
	else
		OPTS="-i"
	fi

	cp docker-compose-template.yaml docker-compose.yaml

        CURRENT_DIR=$PWD
        cd crypto-config/peerOrganizations/unitedmarbles.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yaml
        cd crypto-config/peerOrganizations/marblesinc.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yaml
}

## Generates Org certs using cryptogen tool
function generateCerts (){
	CRYPTOGEN=bin/cryptogen

	if [ -f "$CRYPTOGEN" ]; then
            echo "Using cryptogen -> $CRYPTOGEN"
	    echo
       	    echo "##########################################################"
	    echo "##### Generate certificates using cryptogen tool #########"
	    echo "##########################################################"
	    $CRYPTOGEN generate --config=./crypto-config.yaml
	    echo
	else
	    echo "cryptogen not found. You may need to run ./zmarbles_setup.sh with the init argument"
	fi

}

## Generate orderer genesis block , channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {

	CONFIGTXGEN=bin/configtxgen
	if [ -f "$CONFIGTXGEN" ]; then
            echo "Using configtxgen -> $CONFIGTXGEN"
	    echo "##########################################################"
	    echo "#########  Generating Orderer Genesis block ##############"
	    echo "##########################################################"
	    # Note: For some unknown reason (at least for now) the block file can't be
	    # named orderer.genesis.block or the orderer will fail to launch!
	    FABRIC_CFG_PATH=`pwd` $CONFIGTXGEN -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block

	    echo
	    echo "#################################################################"
	    echo "### Generating channel configuration transaction 'channel.tx' ###"
	    echo "#################################################################"
	    FABRIC_CFG_PATH=`pwd` $CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

	    echo
	    echo "#################################################################"
	    echo "#######    Generating anchor peer update for Org0MSP   ##########"
	    echo "#################################################################"
	    FABRIC_CFG_PATH=`pwd` $CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org0MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org0MSP

	    echo
	    echo "#################################################################"
	    echo "#######    Generating anchor peer update for Org1MSP   ##########"
	    echo "#################################################################"
	    FABRIC_CFG_PATH=`pwd` $CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
	    echo
	else
	    echo "configtxgen not found. You may need to run ./zmarbles_setup.sh with the init argument"
	fi

}

generateCerts
replacePrivateKey
generateChannelArtifacts

