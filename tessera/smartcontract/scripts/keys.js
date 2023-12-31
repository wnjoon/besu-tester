// WARNING: the keys here are demo purposes ONLY. Please use a tool like EthSigner for production, rather than hard coding private keys

module.exports = {
  tessera: {
    bootstrap: {
      publicKey: "wnQD1lXvnv58e59LiJgJzeMwGZV6czkWWjxh4XjdETQ=",
    },
    peer1: {
      publicKey: "nJbepYc4JFciq+yLyw+w+6D172+6iE82evIw3sX03zQ=",
    },
    peer2: {
      publicKey: "ykTpKy53P1JmVsbVDe4FcWV8RPuJbjUvGzQe/6BeM3A=",
    },
    peer3: {
      publicKey: "N/p82nI3vMpB8oadUNuiMaEScuD7ZaOmxff7BeT26lI=",
    },
  },
  besu: {
    node1: {
      name: "node1",
      url: "http://localhost:22001",
      wsUrl: "ws://localhost:23001",
      privateUrl: "http://localhost:9081",
      // nodekey:
      //   "0xb9a4bd1539c15bcc83fa9078fe89200b6e9e802ae992f13cd83c853f16e8bed4",
      // accountAddress: "0xf0e2db6c8dc6c681bb5d6ad121a107f300e9b2b5",
      accountPrivateKey:
        "8bbbb1b345af56b560a5b20bd4b0ed1cd8cc9958a16262bc75118453cb546df7",
    },
    node2: {
      name: "node2",
      url: "http://localhost:22002",
      wsUrl: "ws://localhost:23002",
      privateUrl: "http://localhost:9082",
      // nodekey:
      //   "f18166704e19b895c1e2698ebc82b4e007e6d2933f4b31be23662dd0ec602570",
      // accountAddress: "0xca843569e3427144cead5e4d5999a3d0ccf92b8e",
      accountPrivateKey:
        "4762e04d10832808a0aebdaa79c12de54afbe006bfffd228b3abcc494fe986f9",
    },
    node3: {
      name: "node3",
      url: "http://localhost:22003",
      wsUrl: "ws://localhost:23003",
      privateUrl: "http://localhost:9083",
      // nodekey:
      //   "4107f0b6bf67a3bc679a15fe36f640415cf4da6a4820affaac89c8b280dfd1b3",
      // accountAddress: "0x0fbdc686b912d7722dc86510934589e0aaf3b55a",
      accountPrivateKey:
        "61dced5af778942996880120b303fc11ee28cc8e5036d2fdff619b5675ded3f0",
    },
  },
  accounts: {
    user1: {
      address: "0xfe3b557e8fb62b89f4916b721be55ceb828dbd73",
      privateKey: "8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63"
    },
    user2: {
      address: "0x627306090abaB3A6e1400e9345bC60c78a8BEf57",
      privateKey: "c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3"
    },
    user3: {
      address: "0xf17f52151EbEF6C7334FAD080c5704D77216b732",
      privateKey: "ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f"
    },
  },
};
