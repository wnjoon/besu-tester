#!/bin/bash

PHASENUM=$1
WORKSPACE=workspace/phase${PHASENUM}

if [ ! -d node_modules ]; then
    source init.sh 
fi

npx caliper launch manager \
    --caliper-workspace  ${WORKSPACE} \
    --caliper-benchconfig benchconfig.yaml \
    --caliper-networkconfig networkconfig.json