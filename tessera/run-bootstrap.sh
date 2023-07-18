#!/bin/bash

BOOTSTRAP_IP=localhost
BOOTSTRAP_PORT=9000
BOOTSTRAPDIR=${PWD}/peers/bootstrap

echo "==== Generate key pair ===="

if [ ! -d keys/bootstrap ]; then
      mkdir -p keys/bootstrap
      tessera -keygen -filename ${PWD}/keys/bootstrap/key
fi

echo "\n==== Generate tessera bootstrap config file ===="

if [ -d ${BOOTSTRAPDIR} ]; then
      rm -Rf ${BOOTSTRAPDIR}
fi

mkdir -p ${BOOTSTRAPDIR}

cp ${PWD}/template/config_bootstrap.json ${BOOTSTRAPDIR}/config.json

echo "\n==== Run tessera node ===="

# mv config.json ${BOOTSTRAPDIR}
tessera --configfile ${BOOTSTRAPDIR}/config.json -o mode="orion"



