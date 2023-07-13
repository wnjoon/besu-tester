#!/bin/bash

ID=$1
ISBOOTSTRAP=$2
BOOTSTRAP_IP=localhost
BOOTSTRAP_PORT=9001

echo "==== Generate key pair ===="

if [ ! -d keys/key${ID} ]; then
      mkdir -p keys/key${ID}
      tessera -keygen -filename ${PWD}/keys/key${ID}/key
fi

echo "\n==== Generate tessera config file ===="

if [ -d tessera${ID} ]; then
      rm -Rf tessera${ID}
fi

mkdir -p tessera${ID}

if [ ${ISBOOTSTRAP} == true ]; then
      cp config_template_bootstrap.json config.json
      sed -i "s|_id_|${ID}|g" "config.json"
else
      cp config_template.json config.json
      sed -i "s|_id_|${ID}|g" "config.json"
      sed -i "s|_bootstrapip_|${BOOTSTRAP_IP}|g" "config.json"
      sed -i "s|_bootstrapport_|${BOOTSTRAP_PORT}|g" "config.json"
      sed -i "s|\"_isbootstrap_\"|${ISBOOTSTRAP}|g" "config.json"
fi


echo "\n==== Run tessera node ===="

mv config.json tessera${ID}
tessera --configfile tessera${ID}/config.json -o mode="orion"



