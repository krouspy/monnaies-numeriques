## Practical Work 4

For this PW we will work with [Quorum](https://github.com/ConsenSys/quorum) an Ethereum-like with private features.

#### Clean up

On previous PWs we have setup things like Bitcoin, Lightning and Ethereum nodes that we don't need anymore so we can remove them.

```bash
# stop services
$ sudo supervisorctl stop lnd
$ sudo systemctl stop nbxplorer.service
$ sudo systemctl stop bitcoind.service
$ sudo systemctl stop btcpayserver.service
$ sudo systemctl stop supervisor.service
$ sudo systemctl stop geth.service

# disable services
$ sudo systemctl disable nbxplorer.service
$ sudo systemctl disable bitcoind.service
$ sudo systemctl disable btcpayserver.service
$ sudo systemctl disable supervisor.service
$ sudo systemctl disable geth.service
```

Since we remove them, we need also to update UFW so that ports are not open for nothing.
Remove all and let only ssh open.

```bash
$ sudo ufw status numbered
> Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 22                         ALLOW IN    Anywhere                   # allow SSH
[ 2] 22 (v6)                    ALLOW IN    Anywhere (v6)              # allow SSH
```

**Note**: we will disable ufw while we setup everything.

```bash
$ sudo ufw disable
```

#### Uninstall Geth

Quorum is a fork of Geth so we should remove it to avoid collisions.

```bash
$ sudo su - ethereum
$ sudo apt autoremove
$ rm -rf ~/.ethereum
```

#### Install Quorum

Create new user.

```bash
$ sudo adduser quorum
$ sudo adduser sudo quorum
$ sudo su - quorum
```

Geth is written in Golang so we can either install Go for `quorum user` or use the one we installed under `admin` by using symlinks.

```bash
$ sudo ln -s /home/administrateur1/go /home/quorum/go
```

We added the `GOPATH` variable the the `.bashrc` of administrateur1.

```bash
$ cat /home/administrateur1/.bashrc | grep GOPATH
> export GOPATH=/home/administrateur1/go
  export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin:$RUSTPATH
```

So let's also create a symlink to it.

```bash
$ sudo ln -s /home/administrateur1/.bashrc /home/quorum/.bashrc
```

Build from source code.

```bash
# https://docs.goquorum.consensys.net/en/latest/HowTo/GetStarted/Install/
$ git clone https://github.com/ConsenSys/quorum.git
$ cd quorum
$ make all
```

To launch our node we need to have access to `geth` and `bootnode` located inside `~/quorum/build/bin` folder.

```bash
$ sudo ln -s ~/quorum/build/bin/geth /usr/local/bin/geth
$ sudo ln -s ~/quorum/build/bin/bootnode /usr/local/bin/bootnode
```

Create folder where we will store our node data.

```bash
$ mkdir ~/nodes
```

Create the genesis.json, it will tell Geth how to init our node.

```json
# ~/nodes/genesis.json

{
    "config": {
        "chainId": 10,
        "homesteadBlock": 0,
        "eip150Block": 0,
        "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "eip155Block": 0,
        "eip158Block": 0,
        "byzantiumBlock": 0,
        "constantinopleBlock": 0,
        "istanbul": {
            "epoch": 30000,
            "policy": 0,
            "ceil2Nby3Block": 0
        },
        "txnSizeLimit": 64,
        "maxCodeSize": 0,
        "isQuorum": true
    },
    "nonce": "0x0",
    "timestamp": "0x5f6cbdb3",
    "extraData": "0x0000000000000000000000000000000000000000000000000000000000000000f8aff8699470321a0da7cf207c4d478b10c5a0a76c5384305394e7795c20b99941a76264eeb865e3d5805150c8dd9425de15950725892e2f8d2cd3fed1527697f1e92e9411df31077b9e6972318c17b30a8aee75534ca4519418d8821d25e2f46d0f87bb9792f1ba78ff16175db8410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0",
    "gasLimit": "0xe0000000",
    "difficulty": "0x1",
    "mixHash": "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
    "coinbase": "0x0000000000000000000000000000000000000000",
    "alloc": {
        "11df31077b9e6972318c17b30a8aee75534ca451": {
            "balance": "0x446c3b15f9926687d2c40534fdb564000000000000"
        },
        "18d8821d25e2f46d0f87bb9792f1ba78ff16175d": {
            "balance": "0x446c3b15f9926687d2c40534fdb564000000000000"
        },
        "25de15950725892e2f8d2cd3fed1527697f1e92e": {
            "balance": "0x446c3b15f9926687d2c40534fdb564000000000000"
        },
        "70321a0da7cf207c4d478b10c5a0a76c53843053": {
            "balance": "0x446c3b15f9926687d2c40534fdb564000000000000"
        },
        "e7795c20b99941a76264eeb865e3d5805150c8dd": {
            "balance": "0x446c3b15f9926687d2c40534fdb564000000000000"
        }
    },
    "number": "0x0",
    "gasUsed": "0x0",
    "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000"
}
```

Init node.

```bash
$ cd ~/nodes
$ geth --datadir data init genesis.json
```

Then add the static-nodes.json to data folder

```json
# ~/nodes/data/static-nodes.json

[
	"enode://f5f177e2f1ccea7262eaa4f24ff6e8b309941ea5dfdede3fe6572fa33fb3b5698cb4eed5a5c827f30e6f8d7be438ebb05480834b2cb8b5547d55efd294e74255@mesimf595420-0009.westeurope.cloudapp.azure.com:30303?discport=0",
	"enode://32d422fbd665dffd592354b60bb04a9b54f070f5573a9fcd1c301e9887327ad020c90cc3bd976dd5caa9c889e45b0781fe5f33868117d8e8ed83509d91674265@mesimf595420-0009.westeurope.cloudapp.azure.com:30304?discport=0",
	"enode://6d16e21887a01d6fb5a5b079bd2c7353ef19226b5b807d8bc5c8564a0118a2494bdc50bcfe8329e2c14d72c6f1083e32979d08d8e48bc1bca221adb2d71165c6@mesimf595420-0009.westeurope.cloudapp.azure.com:30305?discport=0",
	"enode://15333f3e4b261f5248f3daf0da2a5a777a54865163a1b283f8e21574756c4447081a3096ed22a40da2cb9c4746779e798efebbd61da2cf842d17486be3c390dd@mesimf595420-0009.westeurope.cloudapp.azure.com:30306?discport=0",
	"enode://db9ad0f757f7a762ddae19b13c16873eb83d8517f6e3089974ac6e26571171aec3d7241a191734622c79018be82930058d6a5f491bb8a9f1e02b0dcb3fd1bcb3@mesimf595420-0009.westeurope.cloudapp.azure.com:30307?discport=0"
]
```

Create startup file at `~/nodes/start.sh`.

```sh
#!/bin/bash

PRIVATE_CONFIG=ignore nohup geth --datadir data --nodiscover --istanbul.blockperiod 5 --syncmode full --mine --minerthreads 1 --verbosity 5 --networkid 180618 --rpc --rpcaddr 0.0.0.0 --rpcport 22000 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul --emitcheckpoints --port 30303 2>>node.log &
```

```bash
$ sh start.sh
# or make it executable
$ chmod +x start.sh
$ ./start.sh
```

We can check if it is working by attaching to the node and retrieve the last block number.

```bash
# open geth console
$ geth attach data/geth.ipc
$ eth.blockNumber
> 16782
```

**Note**: In my case, when I check the logs, it seems I'm running into node connectivity issues. I don't know how to fix that (UFW is disabled).

```bash
$ tail -f node.log
> Failed RLPx handshake
```

### Validators

To become a validator, we need the majority of other existing validators to agree. The first step is to be `proposed` by an already `existing validator`. So if we have access to validator nodes then we can connect to them and propose the new node.

Before we need the address of the new node.

```bash
# connect to node
$ geth attach ./data/geth.ipc
$ istanbul.nodeAddress
> "0xe4317ecad384ae7c6485c90351e56c7ada230457"
```

Then if you have access to validators, connect to them. Else, contact the persons that have access. In both cases, the process is to log into the majority (3 of 5 for example) and propose the new node address.

```bash
# repeat for more than half of the number of validators
$ istanbul.propose("0xe4317ecad384ae7c6485c90351e56c7ada230457", true)
```

If everything is going fine, we can check is the new node has been accepted as a validator.

```bash
$ istanbul.getValidators()
> [..., "0xe4317ecad384ae7c6485c90351e56c7ada230457"]
```

And also add the enode of the new validator to the `static-nodes.json` file.

```bash
$ admin.nodeInfo.enode
> enode://df70a753e4ba5eef6bd3830b4eb831654361cd5a62a7238e195aeed6a91b592a139a668a1416702a161018a922df84232f2e31f0e2d96a2b9748d8df4964d177@127.0.0.1:30303?discport=0
```

Replace `127.0.0.1` with your `ip address` in order to be seen.

```bash
$ ps aux | grep geth
$ kill <PID>
$ nvim ~/nodes/data/static-nodes.json
```

```json
$ ~/nodes/data/static-nodes.json

{
    "enode://df70a753e4ba5eef6bd3830b4eb831654361cd5a62a7238e195aeed6a91b592a139a668a1416702a161018a922df84232f2e31f0e2d96a2b9748d8df4964d177@<ip_address>:30303?discport=0",
    ...
}
```

### Deploy public contract

First let's create an acount.

```bash
$ geth attach data/geth.ipc
$ web3.personal.newAccount()
> "0xa594a9345bc97415c5a678ac9473cc0f69f32887"
```

By default the account is locked because our node will encrypt the associated and also disables the api to unlock it. We can restart our node with `--allow-insecure-unlock` flag to open the api. Obviously, this is a not something we should authorize so don't forget to remove this flag later.

1. Stop node

```bash
$ ps aux | grep geth
$ kill <PID>
```

2. Modify start.sh

```sh
#!/bin/bash

PRIVATE_CONFIG=ignore nohup geth --datadir data --nodiscover --istanbul.blockperiod 5 --syncmode full --mine --minerthreads 1 --verbosity 5 --networkid 180618 --rpc --rpcaddr 0.0.0.0 --rpcport 22000 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul --emitcheckpoints --allow-insecure-unlock --port 30303 2>>node.log &
```

3. Start node

```bash
$ sh start.sh
```

4. Unlock account

```bash
$ geth attach data/geth.ipc
$ web3.personal.unlockAccount("0xa594a9345bc97415c5a678ac9473cc0f69f32887")
> Password
true
$ web3.personal.listWallets
> [{
      accounts: [{...}],
      status: "Unlocked",
      url: "keystore:///home/quorum/nodes/data/keystore/UTC--2020-09-27T14-10-27.720952833Z--a594a9345bc97415c5a678ac9473cc0f69f32887"
  }],
```

5. Smart contract

Here a simple smart contract.

```javascript
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.6.1;

contract Storage {
  string public value;

  function setValue(string memory _value) public {
    value = _value;
  }
}
```

We need two things in order to deploy our smart contract:

    - contract abi
    - contract bytecode

We can use [Remix](https://remix.ethereum.org/) to get them. Also make sure to **not** use a too recent solidity compiler, GoQuorum is not as "advanced" as Geth.

![alt remix](./assets/smart-contract.png 'smart contract')

The **bytecode** variable contains a field named **object**, that's the one we need (with 0x appended).

Then inside geth console.

```javascript
> var bytecode =
  '0x608060405234801561001057600080fd5b5061030c806100206000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c80633fa4f2451461003b57806393a09352146100be575b600080fd5b610043610179565b6040518080602001828103825283818151815260200191508051906020019080838360005b83811015610083578082015181840152602081019050610068565b50505050905090810190601f1680156100b05780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b610177600480360360208110156100d457600080fd5b81019080803590602001906401000000008111156100f157600080fd5b82018360208201111561010357600080fd5b8035906020019184600183028401116401000000008311171561012557600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509192919290505050610217565b005b60008054600181600116156101000203166002900480601f01602080910402602001604051908101604052809291908181526020018280546001816001161561010002031660029004801561020f5780601f106101e45761010080835404028352916020019161020f565b820191906000526020600020905b8154815290600101906020018083116101f257829003601f168201915b505050505081565b806000908051906020019061022d929190610231565b5050565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061027257805160ff19168380011785556102a0565b828001600101855582156102a0579182015b8281111561029f578251825591602001919060010190610284565b5b5090506102ad91906102b1565b5090565b6102d391905b808211156102cf5760008160009055506001016102b7565b5090565b9056fea264697066735822122083a57babc3b7f930ac180224ebafee3db05b9c2eb96e57e539bee9154e5019be64736f6c63430006000033';

> var abi = [
  {
    inputs: [{ internalType: 'string', name: '_value', type: 'string' }],
    name: 'setValue',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [],
    name: 'value',
    outputs: [{ internalType: 'string', name: '', type: 'string' }],
    stateMutability: 'view',
    type: 'function',
  },
];

> var contract = eth.contract(abi);
> var instance = contract.new({
  from: eth.accounts[0],
  data: bytecode,
  gas: 0x47b760,
});

> instance
{
  abi: [{
      inputs: [{...}],
      name: "setValue",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function"
  }, {
      inputs: [],
      name: "value",
      outputs: [{...}],
      stateMutability: "view",
      type: "function"
  }],
  address: "0x7a9ab50a3311eafc59c38b073ed248a627579a7b",
  transactionHash: "0x67e005b1c769250f3e43dad07651ffd947613e327b7cfdb9c08f9663344609b5",
  allEvents: function(),
  setValue: function(),
  value: function()
}

```

We can see the transaction.

```
> eth.getTransaction("0x67e005b1c769250f3e43dad07651ffd947613e327b7cfdb9c08f9663344609b5")
{
  blockHash: "0xcb11f3518ad3a53cde0b6bb17998e1409973421d176a9540bd9b1a556616cbc3",
  blockNumber: 33877,
  from: "0xa594a9345bc97415c5a678ac9473cc0f69f32887",
  gas: 4700000,
  gasPrice: 0,
  hash: "0x67e005b1c769250f3e43dad07651ffd947613e327b7cfdb9c08f9663344609b5",
  input: "0x608060405234801561001057600080fd5b5061030c806100206000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c80633fa4f2451461003b57806393a09352146100be575b600080fd5b610043610179565b6040518080602001828103825283818151815260200191508051906020019080838360005b83811015610083578082015181840152602081019050610068565b50505050905090810190601f1680156100b05780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b610177600480360360208110156100d457600080fd5b81019080803590602001906401000000008111156100f157600080fd5b82018360208201111561010357600080fd5b8035906020019184600183028401116401000000008311171561012557600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600081840152601f19601f820116905080830192505050505050509192919290505050610217565b005b60008054600181600116156101000203166002900480601f01602080910402602001604051908101604052809291908181526020018280546001816001161561010002031660029004801561020f5780601f106101e45761010080835404028352916020019161020f565b820191906000526020600020905b8154815290600101906020018083116101f257829003601f168201915b505050505081565b806000908051906020019061022d929190610231565b5050565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061027257805160ff19168380011785556102a0565b828001600101855582156102a0579182015b8281111561029f578251825591602001919060010190610284565b5b5090506102ad91906102b1565b5090565b6102d391905b808211156102cf5760008160009055506001016102b7565b5090565b9056fea264697066735822122083a57babc3b7f930ac180224ebafee3db05b9c2eb96e57e539bee9154e5019be64736f6c63430006000033",
  nonce: 0,
  r: "0x6a6a5899c969d4b063f32f32c0028ca800b832f02494267560acae160eb4655b",
  s: "0x6accf504473a48e27fabfdab1f8634db0b08dbafbcfa67b390abbc3f3e513849",
  to: null,
  transactionIndex: 0,
  v: "0x37",
  value: 0
}
```

Our smart contract is now deployed!

Also note the `v: "0x37"` that indicates it is a public contract.

### [Tessera](https://github.com/ConsenSys/tessera) - Privacy Transaction Manager

Follow [instructions](https://github.com/ConsenSys/tessera) to install Tessera.

Tessera is built in Java so we need to install.

```bash
# check if java is already installed
$ java -version
# if it not installed
$ sudo apt install default-jre
# then you should see something like this
$ java -version
> openjdk version "11.0.8" 2020-07-14
OpenJDK Runtime Environment (build 11.0.8+10-post-Ubuntu-0ubuntu118.04.1)
OpenJDK 64-Bit Server VM (build 11.0.8+10-post-Ubuntu-0ubuntu118.04.1, mixed mode, sharing)
```

We will build it from source so we also need [Maven](https://linuxize.com/post/how-to-install-apache-maven-on-ubuntu-18-04/).

```bash
$ sudo apt update
$ sudo apt install maven
$ mvn -version
> Apache Maven 3.6.0
Maven home: /usr/share/maven
Java version: 11.0.8, vendor: Ubuntu, runtime: /usr/lib/jvm/java-11-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "5.4.0-1025-azure", arch: "amd64", family: "unix"
```

Then build Tessera.

```bash
$ git clone https://github.com/ConsenSys/tessera
$ cd tessera
$ mvn install
```

I didn't succeed to make this part work, when building Tessera I ran into this issue and I didn't have much time left to resolve it.

```bash
[INFO] acceptance-test .................................... SUCCESS [04:21 min]
[INFO] jmeter-test ........................................ FAILURE [15:59 min]
[INFO] encryption-kalium .................................. SKIPPED
[INFO] data-migration ..................................... SKIPPED
[INFO] service-loader-ext ................................. SKIPPED
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  31:05 min
[INFO] Finished at: 2020-09-27T13:26:26Z
```

But the next steps to setup Tessera are describe [here](https://github.com/ConsenSys/tessera#running-tessera).

### Deploy private contract

The process to deploy a private contract is almost the same as the process to deploy a public contract. The only difference is that we pass a field called `privateFor` when deploying the contract. And nodes that know this value will be able to see the transaction (so the contract) and others will not.

### UFW

Once everything is done, we can reactive UFW and also open port for Geth.

```bash
$ sudo ufw allow 30303 comment 'allow Geth'
$ sudo ufw enable
```

**Note**: Since everything is not fully working I stop my node.
