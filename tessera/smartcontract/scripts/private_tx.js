const path = require("path");
const fs = require("fs-extra");
const Web3 = require("web3");
const Web3Quorum = require("web3js-quorum");
const ptm = require("./private_tx_module");

const { tessera, besu, accounts } = require("./keys.js");
const chainId = 1337;

const contractJsonPath = path.resolve(
  __dirname,
  "../",
  "contracts",
  "SimpleStorage.json"
);
const contractJson = JSON.parse(fs.readFileSync(contractJsonPath));
const contractBytecode = contractJson.evm.bytecode.object;
const contractAbi = contractJson.abi;


async function main() {

  ptm.createContract(
    besu.node1.url,
    accounts.user1.privateKey,
    tessera.peer1.publicKey,
    tessera.peer2.publicKey
  ).then(async function (privateTxReceipt) {
    console.log("Address of transaction: ", privateTxReceipt.contractAddress);
    await new Promise((r) => setTimeout(r, 20000));
    console.log("Use the smart contracts 'get' function to read the contract's constructor initialized value .. ");
    
    console.log("get value from node1 using account1");
    await ptm.getValueAtAddress(
      besu.node1.url,
      "node1",
      privateTxReceipt.contractAddress,
      contractAbi,
      accounts.user1.privateKey,
      tessera.peer1.publicKey,
      tessera.peer2.publicKey
    )
    .then(console.log("success\n"))
    console.log("\n")

    console.log("get value from node1 using account2");
    await ptm.getValueAtAddress(
      besu.node1.url,
      "node1",
      privateTxReceipt.contractAddress,
      contractAbi,
      accounts.user2.privateKey,
      tessera.peer1.publicKey,
      tessera.peer2.publicKey
    )
    .then(console.log("success\n"))
    console.log("\n")
    
    console.log("get value from node3 using account2 with tessera peer1 (wrong connection");
    await ptm.getValueAtAddress(
      besu.node3.url,
      "node3",
      privateTxReceipt.contractAddress,
      contractAbi,
      accounts.user2.privateKey,
      tessera.peer1.publicKey,
      tessera.peer2.publicKey
    )
    .then(console.log("success\n"))
    console.log("\n")


  }).catch(console.error);

}




if (require.main === module) {
  main();
}

module.exports = exports = main;
