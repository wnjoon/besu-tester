#!/bin/bash

npm install --only=prod @hyperledger/caliper-cli@0.5.0
npx caliper bind --caliper-bind-sut besu:1.4