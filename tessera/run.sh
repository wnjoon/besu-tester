#!/bin/bash

ID=$1

echo "==== Generate key pair ===="

if [ ! -d keys/key${ID} ]; then
      mkdir -p keys/key${ID}
fi

tessera -keygen -filename ${PWD}/keys/key${ID}/key

echo "\n==== Generate tessera config file ===="

if [ ! -d tessera${ID} ]; then
      mkdir -p tessera${ID}
fi

cp config_template.json config.json

sed -i "s|_id_|${ID}|g" "config.json"

mv config.json tessera${ID}

echo "\n==== Run tessera node ===="

tessera --configfile tessera${ID}/config.json -o mode="orion"



