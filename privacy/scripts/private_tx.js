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

    // console.log("get value from node2 using account2 - success");
    // await ptm.getValueAtAddress(
    //   besu.node2.url,
    //   "node2",
    //   privateTxReceipt.contractAddress,
    //   contractAbi,
    //   accounts.user2.privateKey,
    //   tessera.peer2.publicKey,
    //   tessera.peer1.publicKey
    // );

    // console.log("get value - failed (wrong contract address)");
    // await ptm.getValueAtAddress(
    //   besu.node2.url,
    //   "node2",
    //   "0x3f72b022aa96751d66f4205f014e189cac8bc995",
    //   contractAbi,
    //   accounts.user2.privateKey,
    //   tessera.peer2.publicKey,
    //   tessera.peer1.publicKey
    // );

    // console.log("get value - failed (wrong privateFor)");
    // await ptm.getValueAtAddress(
    //   besu.node2.url,
    //   "node2",
    //   privateTxReceipt.contractAddress,
    //   contractAbi,
    //   accounts.user2.privateKey,
    //   tessera.peer2.publicKey,
    //   tessera.peer3.publicKey
    // );

    // console.log("get value - failed (wrong privateFrom)");
    // await ptm.getValueAtAddress(
    //   besu.node3.url,
    //   "node3",
    //   privateTxReceipt.contractAddress,
    //   contractAbi,
    //   accounts.user3.privateKey,
    //   tessera.peer3.publicKey,
    //   tessera.peer1.publicKey
    // );


  }).catch(console.error);

    // Get value
    // await ptm.getValueAtAddress(
    //   besu.node3.url,
    //   "node3",
    //   privateTxReceipt.contractAddress,
    //   contractAbi,
    //   accounts.user1.privateKey,
    //   tessera.peer1.publicKey,
    //   tessera.peer2.publicKey
    // );


  // createContractReceipt
  // .then(console.log(createContractReceipt))
  // .catch(console.err);
  // )
  //   .then(async function (privateTxReceipt) {
  //     console.log("Address of transaction: ", privateTxReceipt.contractAddress);
  //     let newValue = 123;

  //     //wait for the blocks to propogate to the other nodes
  //     await new Promise((r) => setTimeout(r, 20000));
  //     console.log(
  //       "Use the smart contracts 'get' function to read the contract's constructor initialized value .. "
  //     );
  //     await getValueAtAddress(
  //       besu.node1.url,
  //       "Member1",
  //       privateTxReceipt.contractAddress,
  //       contractAbi,
  //       besu.node1.accountPrivateKey,
  //       tessera.peer1.publicKey,
  //       tessera.peer3.publicKey
  //     );
  //     console.log(
  //       `Use the smart contracts 'set' function to update that value to ${newValue} .. - from member1 to member3`
  //     );
  //     await setValueAtAddress(
  //       besu.node1.url,
  //       privateTxReceipt.contractAddress,
  //       newValue,
  //       contractAbi,
  //       besu.node1.accountPrivateKey,
  //       tessera.peer1.publicKey,
  //       tessera.peer3.publicKey
  //     );
  //     //wait for the blocks to propogate to the other nodes
  //     await new Promise((r) => setTimeout(r, 20000));
  //     console.log(
  //       "Verify the private transaction is private by reading the value from all three members .. "
  //     );
  //     await getValueAtAddress(
  //       besu.node1.url,
  //       "Member1",
  //       privateTxReceipt.contractAddress,
  //       contractAbi,
  //       besu.node1.accountPrivateKey,
  //       tessera.peer1.publicKey,
  //       tessera.peer3.publicKey
  //     );
  //     await getValueAtAddress(
  //       besu.node2.url,
  //       "Member2",
  //       privateTxReceipt.contractAddress,
  //       contractAbi,
  //       besu.node2.accountPrivateKey,
  //       tessera.peer2.publicKey,
  //       tessera.peer1.publicKey
  //     );
  //     await getValueAtAddress(
  //       besu.node3.url,
  //       "Member3",
  //       privateTxReceipt.contractAddress,
  //       contractAbi,
  //       besu.node3.accountPrivateKey,
  //       tessera.peer3.publicKey,
  //       tessera.peer1.publicKey
  //     );
  //   })
    // .catch(console.error);
}




if (require.main === module) {
  main();
}

module.exports = exports = main;
