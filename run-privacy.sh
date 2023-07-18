#!/bin/bash

ID=$1
BOOTNODEIP=127.0.0.1
TESSERAIP=127.0.0.1
LOGLEVEL=DEBUG

if [ -d nodes/node${ID} ]; then
      rm -Rf nodes/node${ID}
fi

sleep 1

besu \
 --genesis-file=genesis.json \
 --node-private-key-file=nodes/config/node${ID} \
 --p2p-host=0.0.0.0 \
 --p2p-port=3030${ID} \
 --host-allowlist=* \
 --Xdns-enabled=true \
 --rpc-http-enabled=true \
 --rpc-http-host=0.0.0.0 \
 --rpc-http-port=2200${ID} \
 --rpc-http-api=EEA,WEB3,ETH,NET,TRACE,DEBUG,ADMIN,TXPOOL,PERM,QBFT,PRIV \
 --rpc-ws-enabled=true \
 --rpc-ws-host=0.0.0.0 \
 --rpc-http-cors-origins=* \
 --rpc-ws-port=2300${ID} \
 --rpc-ws-api=EEA,WEB3,ETH,NET,TRACE,DEBUG,ADMIN,TXPOOL,PERM,QBFT,PRIV \
 --bootnodes=enode://8208a3f344695d44e9cf2c023683cbea7b9343e2f70a5e804bd2c93858e945f8f91439eef96a4ab6c47ff06637d6fbe6472f96de1655a1bee57ea896654f3a22@${BOOTNODEIP}:30301 \
 --discovery-enabled=true \
 --metrics-enabled=true \
 --metrics-host=0.0.0.0 \
 --metrics-port=3200${ID} \
 --min-gas-price=0 \
 --logging=${LOGLEVEL} \
 --privacy-enabled \
 --privacy-url=http://${TESSERAIP}:910${ID} \
 --privacy-public-key-file=${PWD}/tessera/keys/peer${ID}/key.pub \
 --data-path=nodes/node${ID}/data ;
