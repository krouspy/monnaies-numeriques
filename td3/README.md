### Pratical Work 3

The objectives of this PW is to run [Geth](https://geth.ethereum.org/) and interact with it.

#### Download GETH

We will disable our firewall while we download dependencies.

```bash
$ sudo ufw disable
```

Follow the instructions [here](https://geth.ethereum.org/docs/install-and-build/installing-geth) to install `Geth`.

```bash
$ sudo add-apt-repository -y ppa:ethereum/ethereum
$ sudo apt-get update
$ sudo apt-get install ethereum
```

#### Synchronize

First, let's create a new user to store data inside.

```bash
$ sudo adduser ethereum
$ sudo usermod -aG sudo ethereum
$ sudo su - ethereum
```

Geth is built in Golang so we can create a symlink pointing to the `GOPATH` and `~/.bashrc` of user `administrateur1`. This way, we don't need to install twice `Go` and Geth data will still be stored under `ethereum` user.

```bash
$ sudo ln -s /home/administrateur1/go /home/ethereum/go
# we previously set the `PATH` variable in `/home/administrateur1/.bashrc`
$ sudo ln -s /home/administrateur1/.bashrc /home/ethereum/.bashrc
```

Now we can run our node on different network like [Rinkeby](https://www.rinkeby.io/). To avoid being interrupted we can use [tmux](https://doc.ubuntu-fr.org/tmux), it allows us to run processes in background.

```bash
$ sudo apt install tmux
# create session
$ tmux
$ geth --rinkeby --syncmode "fast" --http --http.addr "127.0.0.1" --http.port 8545 --rpcapi db,eth,net,web3,personal
```

```
detach session: CTRL+b d
attach session: tmux attach -t sessionId
```

Syncing the blockchain might take a while to complete.

#### Service

In case something happens on our machine/VM like rebooting, we should turn `GETH` into a service so that it will launch on startup. We can use `systemd` for that.

```bash
# /etc/systemd/system/geth.service

[Unit]
Description=Geth Service

[Service]
Type=simple
User=ethereum
Restart=always
ExecStart=/usr/bin/geth --rinkeby --syncmode "fast" --http --http.addr "127.0.0.1" --http.port 8545 --rpcapi db,eth,net,web3,personal

[Install]
WantedBy=default.target
```

Then enable the service.

```bash
$ sudo systemctl enable geth.service
$ sudo systemctl start geth.service
```

#### Interact

Connect to Geth.

```bash
$ geth --rinkeby attach
```

Get last block number.

```bash
$ eth.getBlock('latest').number
> 7227843
```

#### Update firewall

Geth listens peers on port `30303` and we set the RPC api on port `8545`.

```bash
$ sudo ufw allow 30303 comment 'allow geth'
$ sudo ufw enable
```

#### Deploy smart contract

We will write a simple smart contract on our local machine and deploy it with [truffle](https://www.trufflesuite.com/) directly through our node hosted on Azure via `ssh`.

First let's create a rinkeby account with [Metamask](https://chrome.google.com/webstore/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn?hl=en-US) and get some testnet ether on a [faucet](https://testnet.help/en/ethfaucet/rinkeby#log). Save your seed phrase we will need it later and backup it if you play something serious.

Here is the [account](https://rinkeby.etherscan.io/address/0xe684FA782fBbE65959aaEe42Ca37E11CeD6ECebD) and the transaction I made on the faucet both viewable on [etherscan](https://rinkeby.etherscan.io/tx/0xce7ad5cf6315d21d48fcf066f674cb0e13e62a0eb4842e3ced3739ee19441ce3).

> 0xce7ad5cf6315d21d48fcf066f674cb0e13e62a0eb4842e3ced3739ee19441ce3

Then you should see something like this on metamask.

![alt metamask](./assets/metamask.png 'metamask')

Create truffle project on your local machine.

```bash
$ mkdir smart-contracts
$ cd smart-contracts
$ yarn init -y
$ yarn add truffle
$ truffle init
```

Write smart contract.

```javascript
// contracts/Storage.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Storage {
    uint private value;

    function getValue() view public returns (uint) {
        return value;
    }

    function setValue(uint val) public {
        value = val;
    }
}
```

Create deployment file.

```javascript
// migrations/2_deploy_contracts.js

const Storage = artifacts.require('Storage');

module.exports = deployer => {
  deployer.deploy(Storage);
};
```

We also need to tell `truffle` how to deploy our smart contract.

We previously created an account on Rinkeby with Metamask and funded it with some ether so we will use it. To do so, install `@truffle/hdwallet-provider` that will manage our account.

```bash
$ yarn add @truffle/hdwallet-provider
```

```javascript
// truffle-config.js

const HDWalletProvider = require('@truffle/hdwallet-provider');

const mnemonic = '...';

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
    },
    rinkeby: {
      provider: function () {
        return new HDWalletProvider(mnemonic, 'http://localhost:8080');
      },
      network_id: 4,
      gas: 4500000,
      gasPrice: 10000000000,
    },
  },
};
```

Note the `http://localhost:8080` that corresponds to our local machine. But our node is hosted on Azure and the rpc api listens on `port 8545`, so to talk to it we can open port `8545` on the remote machine so that http requests to <vm_ipaddress>:8545 will work.

But I find it more secure to use `ssh tunneling`.

```bash
$ ssh -L 8080:localhost:8545 <user>@<dns>
```

This command binds the port `8080` on our local machine to the port `8545` on the remote machine.

Once you open the connection talking to `localhost:8080` on your local machine is like talking to `localhost:8545` on the remote machine.

Then we can now deploy our smart contract.

```bash
$ truffle migrate --network=rinkeby
```

Here is the [contract](https://rinkeby.etherscan.io/tx/0xb131deb4836ff391ba4d00a4804a168277318abe30c0fafd0609142169daf132).

To interact with our contract, we can use `truffle`.

```bash
$ truffle --network=rinkeby console
```

Then in the console.

```bash
$ Storage.deployed().then(instance => storage = instance)
$ storage.getValue()
> <BN: 0>
$ storage.setValue(10)
> { tx:
   '0x58c57fe836b7d254a77faacee6fc969ae005e56be52e89bd434a7bb22a4579eb',
  receipt:
   { blockHash:
      '0x62afcdfe552d47c99a3c79d503bf3c4e1e86bc8a7796a56e50d8bdedd2b6fc80',
     blockNumber: 7229310,
     contractAddress: null,
     cumulativeGasUsed: 41446,
     from: '0xe684fa782fbbe65959aaee42ca37e11ced6ecebd',
     gasUsed: 41446,
     logs: [],
     logsBloom:
      '0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
     status: true,
     to: '0xc68c78538d514627fc20e6f2d58c56879c112bf9',
     transactionHash:
      '0x58c57fe836b7d254a77faacee6fc969ae005e56be52e89bd434a7bb22a4579eb',
     transactionIndex: 0,
     rawLogs: [] },
  logs: [] }

$ storage.getValue(v => value = v)
$ value.toNumber()
> 10
```

We can also use the `Geth` console to retrieve data from the `setValue()` transaction.

Connect to the VM via `ssh`.

```bash
$ sudo su - ethereum
$ geth --rinkeby attach
$ eth.getTransaction("0x58c57fe836b7d254a77faacee6fc969ae005e56be52e89bd434a7bb22a4579eb")
> {
  blockHash: "0x62afcdfe552d47c99a3c79d503bf3c4e1e86bc8a7796a56e50d8bdedd2b6fc80",
  blockNumber: 7229310,
  from: "0xe684fa782fbbe65959aaee42ca37e11ced6ecebd",
  gas: 4500000,
  gasPrice: 10000000000,
  hash: "0x58c57fe836b7d254a77faacee6fc969ae005e56be52e89bd434a7bb22a4579eb",
  input: "0x55241077000000000000000000000000000000000000000000000000000000000000000a",
  nonce: 4,
  r: "0x6b55f008653e3e3c206e6738989b03001fbeb1e1515210a689c8f8386a05c4b7",
  s: "0xeb1ef291afe2c7701b825d037cec8e2ba5647b523a448c51ccd8eeb3ce5378a",
  to: "0xc68c78538d514627fc20e6f2d58c56879c112bf9",
  transactionIndex: 0,
  v: "0x1c",
  value: 0
}
```

