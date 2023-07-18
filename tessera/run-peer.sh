#!/bin/bash

ID=$1
BOOTSTRAP_IP=localhost
BOOTSTRAP_PORT=9000
PEERDIR=${PWD}/peers/peer${ID}

echo "==== Generate key pair ===="

if [ ! -d keys/peer${ID} ]; then
      mkdir -p keys/peer${ID}
      tessera -keygen -filename ${PWD}/keys/peer${ID}/key
fi

echo "\n==== Generate tessera config file ===="

if [ -d ${PEERDIR} ]; then
      rm -Rf ${PEERDIR}
fi

mkdir -p ${PEERDIR}

cp ${PWD}/template/config_peer.json ${PEERDIR}/config.json

sed -i "s|_id_|${ID}|g" "${PEERDIR}/config.json"
sed -i "s|_bootstrapip_|${BOOTSTRAP_IP}|g" "${PEERDIR}/config.json"
sed -i "s|_bootstrapport_|${BOOTSTRAP_PORT}|g" "${PEERDIR}/config.json"
sed -i "s|\"_isbootstrap_\"|${ISBOOTSTRAP}|g" "${PEERDIR}/config.json"

# mv config.json ${PEERDIR}

echo "\n==== Run tessera node ===="

if [ -d ${PWD}/tessera${ID} ]; then
      rm -Rf ${PWD}/tessera${ID}
      sleep 3
fi

tessera --configfile ${PEERDIR}/config.json -o mode="orion"



