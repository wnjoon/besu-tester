# Benchmark using Caliper

## Init

```
$ npm install -g --only=prod @hyperledger/caliper-cli@0.5.0
$ caliper bind --caliper-bind-sut besy:1.4 --caliper-bind-args=-g 
```

## Run

Run [run.sh](./run.sh) with input parameter indicates benchmark phase.

```
$ ./run.sh 1
```

## Structure

- [src](./src/)
    - Smartcontract and its test scripts
- [workspace](./workspace/)
    - Test configurations categorized with number with named 'phase'
    - Should modify some values indicates system-based information such as network