# Tessera

## Run bootstrap

In this practice, Tessera nodes will be connected with bootstrap node.  
To run bootstrap node, execute [run-bootstrap.sh](./run-bootstrap.sh) script.  
Bootstrap node has static variables in [keys/bootstrap](./keys/bootstrap/) directory.  
Bootstrap node config file is [config-boostrap.json](./template/config_bootstrap.json).  

**Hyperledger Besu requires orion mode when Tessera node is executed**

## Run Tessera node

**To run Tessera node, BOOTSTRAP NODE SHOULD BE ALREADY EXECUTED AND RUNNING**

To run bootstrap node, execute [run-peer.sh](./run-peer.sh) script with input parameter indicates peer number.  
If input number is never used before, script will generate key pair in [keys/peerX](./keys/) directory.

