#!/bin/bash

if [ -z ${1} ]; then
  echo "Error: Please specify the channel name."
  echo "Usage: setup-marbles.sh <channel-name>"
  echo ""
  exit 1
fi

CHANNEL=${1}

echo "#####################################"
echo "# Creating channel ${CHANNEL}"
echo "#####################################"
sleep 10
# Create channel
. scripts/setpeer 1 1
peer channel create -o orderer.blockchain.com:7050 -c ${CHANNEL} -f channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/blockchain.com/orderers/orderer.blockchain.com/msp/tlscacerts/tlsca.blockchain.com-cert.pem

echo "#################################################"
echo "# peer0.unitedmarbles.com joining channel ${CHANNEL}"
echo "#################################################"
sleep 2
# Channel join
. scripts/setpeer 0 0
peer channel join -b ${CHANNEL}.block 


echo "#################################################"
echo "# peer1.unitedmarbles.com joining channel ${CHANNEL}"
echo "#################################################"
sleep 2
. scripts/setpeer 0 1
peer channel join -b ${CHANNEL}.block


echo "#################################################"
echo "# peer0.marblesinc.com joining channel ${CHANNEL}"
echo "#################################################"
sleep 2
. scripts/setpeer 1 0
peer channel join -b ${CHANNEL}.block


echo "#################################################"
echo "# peer1.marblesinc.com joining channel ${CHANNEL}"
echo "#################################################"
sleep 2
. scripts/setpeer 1 1
peer channel join -b ${CHANNEL}.block

# Update Anchor peers
echo "#################################################"
echo "# Updating anchor peer for unitedmarbles.com"
echo "#################################################"
sleep 2
. scripts/setpeer 0 0
peer channel create -o orderer.blockchain.com:7050 -c ${CHANNEL} -f channel-artifacts/Org0MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/blockchain.com/orderers/orderer.blockchain.com/msp/tlscacerts/tlsca.blockchain.com-cert.pem

echo "#################################################"
echo "# Updating anchor peer for marblesinc.com"
echo "#################################################"
sleep 2
. scripts/setpeer 1 0
peer channel create -o orderer.blockchain.com:7050 -c ${CHANNEL} -f channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/blockchain.com/orderers/orderer.blockchain.com/msp/tlscacerts/tlsca.blockchain.com-cert.pem

# Install marbles chaincode on peer0/org0 and peer0/org1
echo "#########################################################"
echo "# installing marbles chaincode on peer0.unitedmarbles.com"
echo "#########################################################"
sleep 2
. scripts/setpeer 0 0
peer chaincode install -n marbles -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/marbles
echo "#########################################################"
echo "# installing marbles chaincode on peer0.marblesinc.com"
echo "#########################################################"
sleep 2
. scripts/setpeer 1 0
peer chaincode install -n marbles -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/marbles

# Instantiate marbles chaincode
echo "#############################################################################"
echo "# instantiating marbles chaincode on channel ${CHANNEL} from peer0.unitedmarbles.com"
echo "#   this will take a few seconds while a new Docker image is being built"
echo "#############################################################################"
sleep 2
. scripts/setpeer 0 0
peer chaincode instantiate -o orderer.blockchain.com:7050 -C ${CHANNEL} -n marbles -v 1.0 -c '{"Args":["init","1"]}' -P "OR ('Org0MSP.member','Org1MSP.member')" --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/blockchain.com/orderers/orderer.blockchain.com/msp/tlscacerts/tlsca.blockchain.com-cert.pem
sleep 10

# Create marbles owner
echo "#############################################################################"
echo "# invoking marbles chaincode on channel ${CHANNEL} from peer0.unitedmarbles.com"
echo "#   Creating new Marbles owner named 'john'"
echo "#############################################################################"
peer chaincode invoke -C ${CHANNEL} -o orderer.blockchain.com:7050 -n marbles -c '{"Args":["init_owner","o0000000000001","john","Marbles Inc"]}' --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/blockchain.com/orderers/orderer.blockchain.com/msp/tlscacerts/tlsca.blockchain.com-cert.pem
sleep 5

# Create marble 
echo "#############################################################################"
echo "# invoking marbles chaincode on channel ${CHANNEL} from peer0.unitedmarbles.com"
echo "#   Creating new marble for 'john'"
echo "#############################################################################"
peer chaincode invoke -C ${CHANNEL} -o orderer.blockchain.com:7050 -n marbles -c '{"Args":["init_marble","m0000000000001","blue","35","o0000000000001","Marbles Inc"]}' --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/blockchain.com/orderers/orderer.blockchain.com/msp/tlscacerts/tlsca.blockchain.com-cert.pem


# Create 2nd marbles owner
. scripts/setpeer 1 0
echo "#############################################################################"
echo "# invoking marbles chaincode on channel ${CHANNEL} from peer0.marblesinc.com"
echo "#   Creating new Marbles owner named 'barry'"
echo "#   this will take a few seconds while a new Docker image is being built"
echo "#############################################################################"
peer chaincode invoke -C ${CHANNEL} -o orderer.blockchain.com:7050 -n marbles -c '{"Args":["init_owner","o0000000000002","barry","United Marbles"]}' --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/blockchain.com/orderers/orderer.blockchain.com/msp/tlscacerts/tlsca.blockchain.com-cert.pem
sleep 5

# Create marble for 2nd owner
echo "#############################################################################"
echo "# invoking marbles chaincode on channel ${CHANNEL} from peer0.marblesinc.com"
echo "#   Creating new marble for 'barry'"
echo "#############################################################################"
peer chaincode invoke -C ${CHANNEL} -o orderer.blockchain.com:7050 -n marbles -c '{"Args":["init_marble","m0000000000002","green","35","o0000000000002","United Marbles"]}' --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/blockchain.com/orderers/orderer.blockchain.com/msp/tlscacerts/tlsca.blockchain.com-cert.pem

