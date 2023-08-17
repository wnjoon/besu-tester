# Configs

## ExtraData

Official document website for extraData is linked to [here](https://besu.hyperledger.org/23.4.0/private-networks/how-to/configure/consensus/qbft#extra-data).

Since this practice code doesn't have validators when it initialized, genesis file doesn't need to set extraData with validators. 

In [toEncode.json](./extraData/toEncode.json), only an address is written.  
It indicates bootstrap node's public key generated from [its private key](../nodes/config/node1).

### Public Key

Official document website for public key generation is linked to [here](https://besu.hyperledger.org/public-networks/reference/cli/subcommands#public-key).

toEncode.json  
```json
[
    "0x93917cadbace5dfce132b991732c6cda9bcc5b8a"
]
```

Generate from besu client function  
```
$ besu public-key export-address --node-private-key-file=${bootstrap node's private key}
$ 2023-08-17 13:36:16.836+09:00 | main | INFO  | KeyPairUtil | Loaded public key 0x8208a3f344695d44e9cf2c023683cbea7b9343e2f70a5e804bd2c93858e945f8f91439eef96a4ab6c47ff06637d6fbe6472f96de1655a1bee57ea896654f3a22 from /Users/a85653/Workspace/besu-tester/./nodes/config/node1
0x93917cadbace5dfce132b991732c6cda9bcc5b8a
```