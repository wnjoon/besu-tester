#!/bin/bash

npx caliper launch manager \
    --caliper-bind-sut besu:1.4 \
    --caliper-workspace . \
    --caliper-benchconfig benchmarks/scenario/simple/config.yaml \
    --caliper-networkconfig networks/besu/qbft.json