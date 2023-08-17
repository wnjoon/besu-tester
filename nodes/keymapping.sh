#!/bin/bash

OPT=$1
LOC=$2

# Besu official website link : https://besu.hyperledger.org/public-networks/reference/cli/subcommands#public-key

# If OPT = export
# besu public-key export [--node-private-key-file=<file>] [--to=<key-file>] [--ec-curve=<ec-curve-name>]
# Outputs the node public key to standard output or to the file specified by --to=<key-file>. 
# You can output the public key associated with a specific private key file using the --node-private-key-file option. 
# The default elliptic curve used for the key is secp256k1. Use the --ec-curve option to choose between secp256k1 or secp256r1.

# if OPT = export-address
# besu public-key export-address [--node-private-key-file=<file>] [--to=<address-file>] [--ec-curve=<ec-curve-name>]
# Outputs the node address to standard output or to the file specified by --to=<address-file>. 
# You can output the address associated with a specific private key file using the --node-private-key-file option. 
# The default elliptic curve used for the key is secp256k1. Use the --ec-curve option to choose between secp256k1 or secp256r1.

# Example
# $ besu public-key export-address --node-private-key-file=./nodes/config/node1

besu public-key ${OPT} --node-private-key-file=${LOC}
 