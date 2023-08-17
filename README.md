# Hyperledger Besu 

## Functions

- Privacy-enabled network using Tessera
    - [tessera](./tessera/README.md)
- Monitoring
    - [quoroum-explorer](./monitoring/explorer/README.md)
- Benchmark
    - [Caliper](./benchmark/README.md)
- Public key generation using its private key
    - [Besu export/export-address](./nodes/keymapping.sh)
- extraData
    - [extraData in genesis.json](./config/README.md)

<br>

## How To Run

- run.sh
    - Run default Besu node with input parameter value of node number
    - ```$ ./run.sh 1```
- run-privacy.sh
    - Run privacy-enabled Besu node with input parameter value of node number
    - Should [run tessera node](./tessera/README.md) before run this script
    - ```$ ./run-privacy.sh 1```

<br>

## Settings

### 1. Blocktime

In genesis file([genesis.json](./genesis.json)), 'blockperiodseconds' in QBFT config is value for setting block time in seconds. **Default value was 5s, however, it is changed to 1s.**

<br>

## Sample Accounts

1. 0xfe3b557e8fb62b89f4916b721be55ceb828dbd73
    - 0x8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63
2. 0x627306090abaB3A6e1400e9345bC60c78a8BEf57
    - 0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3
3. 0xf17f52151EbEF6C7334FAD080c5704D77216b732
    - 0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f
4. 0xf0e2db6c8dc6c681bb5d6ad121a107f300e9b2b5
    - 0x8bbbb1b345af56b560a5b20bd4b0ed1cd8cc9958a16262bc75118453cb546df7
5. 0xca843569e3427144cead5e4d5999a3d0ccf92b8e
    - 0x4762e04d10832808a0aebdaa79c12de54afbe006bfffd228b3abcc494fe986f9
6. 0x0fbdc686b912d7722dc86510934589e0aaf3b55a
    - 0x61dced5af778942996880120b303fc11ee28cc8e5036d2fdff619b5675ded3f0
