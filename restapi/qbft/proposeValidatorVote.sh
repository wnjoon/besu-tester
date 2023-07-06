#!/bin/bash

ADDRESS=$1

curl -X POST --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["${ADDRESS}",true], "id":1}' http://localhost:22001
