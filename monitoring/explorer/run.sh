#!/bin/bash

docker stop besu-explorer
docker rm besu-explorer

docker run -d \
-p 25000:25000/tcp \
-v ${PWD}/config.json:/app/config.json \
-v ${PWD}/env:/app/.env.production \
--name besu-explorer \
consensys/quorum-explorer:latest