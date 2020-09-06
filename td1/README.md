# Practical Work 1

This PW follows [RaspiBolt](https://github.com/Stadicus/RaspiBolt/).

Instead of using a Raspberry Pi, we use a virtual machine hosted on Azure on which we will setup a Bitcoin and Lightning node, Tor and a Block Explorer.

## Environment

Ubuntu 20.4 LTS

Azure VM running Ubuntu 18.04.5 LTS

## [SSH Authentication](https://stadicus.github.io/RaspiBolt/raspibolt_21_security.html#login-with-ssh-keys)

First step is to connect to Azure remotely.

In order to do so, we need a way to tell Azure that when he sees me, he has to let me in and all other people are not allowed except for those I agreed for. This way, it prevents malicious people to be able to access easily to my node.

To realize that, we use [SSH](https://fr.wikipedia.org/wiki/Secure_Shell). This protocol allows one to authenticate himself by using a private/public key pair.

The public key is used to say: "There's a guy called _<public_key>_ that is authorized to enter"

And The private key to say: "I'm this guy"

Check existing private/public keys

```bash
$ ls -la ~/.ssh/*.pub
```

If there's no result, we can generate them both using the following command.

```bash
$ ssh-keygen -t rsa -b 4096
```

Now that we have the private/public key pair, we can give the public key to our Azure VM but **be careful to not** divulgate the private key.

```bash
$ ssh-copy-id <username>@<ip_address>
or
$ ssh-copy-id <username>@<dns>
```

We can simply connect with this command:

```bash
$ ssh <username>@<dns>
```

If you want to allow other people to connect via SSH, you can log into the VM as admin and save their private key inside ~/.ssh/authorized_keys.

### [Password Login](https://stadicus.github.io/RaspiBolt/raspibolt_21_security.html#disable-password-login)

To reduce the possibilities to connect to our VM, we will also disable the password login so only the person owning the private key will be able to connect.

```bash
$ sudo nvim /etc/ssh/sshd_config
```

```bash
# /etc/ssh/ssh_config
...
ChallengeResponseAuthentication no
PasswordAuthentication no
...
```

```bash
$ sudo systemctl restart sshd
```

## [Uncomplicated Firewall](https://stadicus.github.io/RaspiBolt/raspibolt_21_security.html#enabling-the-uncomplicated-firewall)

We also enable the firewall to limit permitted incoming traffics.

```bash
$ sudo apt install ufw
$ sudo su
$ ufw default deny incoming
$ ufw default allow outgoing
$ ufw allow 22    comment 'allow SSH'
$ ufw allow 50002 comment 'allow Electrum SSL'
$ ufw enable
$ systemctl enable ufw
$ ufw status
> Status: active
```

Incoming traffics are only enabled through port 22 for SSH connections and 50002 for Bitcoin client whilst outgoing traffics are still open.

## [Fail2Ban](https://stadicus.github.io/RaspiBolt/raspibolt_21_security.html#fail2ban)

This software detects repeated authentication failures and bans the associated IP address. So that brute forcing will not be able.

This package is listed on the [universe deposit](https://packages.ubuntu.com/bionic/fail2ban) so if you did not update the package sources, you might not find it.

```bash
$ sudo apt install fail2ban
...
> Unable to locate package fail2ban
```

We previously set up the UFW, so we need to disable it otherwise, since traffics are restricted, updating package sources might not work.

\_Note: we will disable UFW some time in order to download/install other softwares

```bash
$ sudo ufw disable
> Firewall stopped and disabled on system startup
$ sudo apt update
...
$ sudo apt upgrade
...
$ sudo apt install fail2ban
...
$ systemctl status fail2ban
...
> Active
```

## [Bitcoin Core](https://stadicus.github.io/RaspiBolt/raspibolt_30_bitcoin.html#bitcoin-core)

Now that we have secured the connection between us and the remote VM, we can install our Bitcoin node.

We will run a full node and these type of node are quite expensive in disk space so we need to check how much is available.

```bash
$ df -h
...
> /dev/sdb1 -> 495G Free disk space
...
```

Currently the Bitcoin testnet weights around 30G so we are free to continue.

At the time of writing this, the latest version of Bitcoin core is v0.20.1 that we can get [here](https://bitcoincore.org/en/download/). Since we are using SSH, it's preferable to use something like [wget](https://doc.ubuntu-fr.org/wget) to download our Bitcoin client and the associated signature.

Binaries are available [here](https://bitcoincore.org/bin/bitcoin-core-0.20.1/).

Select the one corresponding to the OS you are running.

In my case, I'm running Ubuntu 18.04.5 LTS (GNU/Linux 5.4.0-1023-azure x86_64)

```bash
$ cd /tmp

# Downloading binaries + signature
$ wget https://bitcoincore.org/bin/bitcoin-core-0.20.1/bitcoin-0.20.1-x86_64-linux-gnu.tar.gz
$ wget https://bitcoincore.org/bin/bitcoin-core-0.20.1/SHA256SUMS.asc
$ wget https://bitcoin.org/laanwj-releases.asc

$ sha256sum --check SHA256SUMS.asc --ignore-missing
> bitcoin-0.20.1-x86_64-linux-gnu.tar.gz: OK

$ gpg --import ./laanwj-releases.asc
$ gpg --keyserver hkp://keyserver.ubuntu.com --refresh-keys
> gpg: key 90C8019E36C2E964: "Wladimir J. van der Laan (Bitcoin Core binary release signing key) <laanwj@gmail.com>" not changed
$ gpg --verify SHA256SUMS.asc
> Good signature from "Wladimir J. van der laan ..."
> Primary key fingerprint: 01EA 5486 DE18 A882 D4C2  6845 90C8 019E 36C2 E964

# Extracing binaries
$ tar -xvf bitcoin-0.20.1-x86_64-linux-gnu.tar.gz
$ sudo install -m 0755 -o root -g root -t /usr/local/bin/ bitcoin-0.20.1/bin/*
$ bitcoind --version
> Bitcoin Core version v0.20.1
```

When launching, by default the bitcoin daemon will store all data inside \$HOME/.bitcoin

If you are using a Raspberry Pi like the [tutorial](https://stadicus.github.io/RaspiBolt/raspibolt_30_bitcoin.html#prepare-data-directory), you should create a symlink pointing to an external drive. A Raspberry Pi uses an external storage so instead of storing data inside the Raspberry Pi, you should store it inside the external hard drive.

In my case, I'm running Ubuntu Server with 495G of hard disk storage hosted on Azure. So I don't need to install data outside.

#### [Configuration](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list)

At this point, Bitcoin Core v0.20.1 has been installed but not yet synced and before launching it, for security reasons, we will create a user and group called 'bitcoin' and add users to the group. We will then store blockchain data inside the bitcoin repository.

```bash
$ sudo adduser bitcoin
$ sudo adduser administrateur1 bitcoin
# login as user bitcoin
$ sudo su - bitcoin
```

The bitcoin daemon will load this config file on startup.

```bash
$ nvim ~/.bitcoin/bitcoin.conf
# same as nvim /home/bitcoin/.bitcoin/bitcoin.conf
```

```bash
# ~/.bitcoin/bitcoin.conf <=> /home/bitcoin/.bitcoin/bitcoin.conf

daemon=1
# Run on testnet
testnet=1
# Listen to JSON-RPC commands
server=1
# Maintain full tx indexing
txindex=1

# Network
listen=1
listenonion=1

# Connections
rpcuser=<user>
rpcpassword=<password>
zmqpubrawblock=tcp://127.0.0.1:28332
zmqpubrawtx=tcp://127.0.0.1:28332
```

```bash
$ bitcoind
> [syncing...]
```

Syncing may take some time even on testnet but once it is done, we will have our own full testnet node to which we will be able to interact directly.

## [Bitcoin daemon as a service](https://stadicus.github.io/RaspiBolt/raspibolt_30_bitcoin.html#autostart-on-boot)

A configuration template can be found [here](https://github.com/bitcoin/bitcoin/blob/master/contrib/init/bitcoind.service) in the bitcoin github repo.

The user 'bitcoin' contains Bitcoin testnet data. But instead of having to login as 'bitcoin' user, we can turn the bitcoin daemon into a service that will start automatically at each startup and read data from bitcoin user.

```bash
# Going back to admin user
$ exit # CTRL-D
```

```bash
# /etc/systemd/system/bitcoind.service

# config found here
# https://medium.com/@stadicus/perfect-low-cost-%EF%B8%8Flightning%EF%B8%8F-node-4c2f42a4ff7b

[Unit]
Description=Bitcoin daemon
After=network.target

[Service]
User=bitcoin
Group=bitcoin
Type=forking
PIDFile=/home/bitcoin/.bitcoin/bitcoind.pid
ExecStart=/usr/local/bin/bitcoind -pid=/home/bitcoin/.bitcoin/bitcoind.pid
KillMode=process
Restart=always
TimeoutSec=120
RestartSec=30

[Install]
WantedBy=multi-user.target
```

Enabling bitcoind service and rebooting the VM.

```bash
$ sudo systemctl enable bitcoind.service
$ sudo reboot
```

Checking if the service is working

```bash
$ systemctl status bitcoind.service
> Active
$ sudo tail -f /home/bitcoin/.bitcoin/testnet3/debug.log
> [logs...]
```

As bitcoin user, we can interact with our node

```bash
$ sudo su - bitcoin
$ bitcoin-cli getblockchaininfo
> ...
```

## Wallet

JSON-RPC documentation can be found [here](https://en.bitcoin.it/wiki/Original_Bitcoin_client/API_calls_list).

```bash
# login as bitcoin user
$ sudo su - bitcoin
```

We will create a wallet and send tBTC to this wallet.

First, generate an address (public key).

```bash
$ bitcoin-cli getnewaddress
> tb1qhfm42mlm5nxr2tpu93m25qfad04yp3a676h4pp
```

We can request tBTC from a faucet like this [one](https://testnet-faucet.mempool.co/).

Here's the transaction hash viewable on a Bitcoin testnet explorer like [blockcypher](https://live.blockcypher.com/btc-testnet/address/tb1qhfm42mlm5nxr2tpu93m25qfad04yp3a676h4pp/).

> 779ac9ae0dcfd66f5d46e880354facfec00bc41e56067fc170c7260a0a9ec7bd

```bash
$ bitcoin-cli getbalance
> 0.00100000
```

## [Lightning Node](https://stadicus.github.io/RaspiBolt/raspibolt_40_lnd.html)

To install LND, we will simply follow the [documentation](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md).

As stated in the [documentation](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md), LND is written in Golang so to build it, we need to first check if Go is installed and install it if not.

```bash
$ wget https://dl.google.com/go/go1.13.linux-amd64.tar.gz
$ sha256sum go1.13.linux-amd64.tar.gz | awk -F " " '{ print $1 }'
> 68a2297eb099d1a76097905a2ce334e3155004ec08cdea85f24527be3c48e856
# matches the one mentioned in the doc

$ tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz
```

```bash
# ~/.bashrc or ~/.zshrc if you are using zsh
...
export GOPATH=/home/administrateur1/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
...
```

```bash
# load changes
$ source .bashrc
```

#### [Installing LND](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md#installing-lnd)

```bash
$ git clone https://github.com/lightningnetwork/lnd
$ cd lnd
$ make install
$ lnd --version
> lnd version 0.11.0-beta commit=v0.11.0-beta-81-g16d564e2b82c2e324bce7ce642d5eefb5b014f5e
```

LND is now working for user administrateur1 but like we did with the bitcoin daemon, we should run it as user bitcoin. If you didn't install Go for bitcoin user, you might run into this issue.

```bash
$ sudo su - bitcoin
$ lnd --version
> lnd not found
```

This is because LND is installed in your GOPATH and since we didn't change the PATH for user bitcoin, it doesn't find it.

```bash
# As administrateur1
$ echo $GOPATH/bin
> /home/administrateur1/go/bin
$ ls $GOPATH/bin/
> lncli lnd
```

To resolve this issue, we can edit the .bashrc (or .zshrc) of both users but it can be quite repetitive and prone to errors.

Instead, using symlink might be more efficient.

```bash
$ sudo su - bitcoin
$ rm .bashrc
$ sudo ln -s /home/administrateur1/.bashrc /home/bitcoin/.bashrc
$ source .bashrc
```

This way, LND is also working for user bitcoin.

#### [LND Configuration](https://stadicus.github.io/RaspiBolt/raspibolt_40_lnd.html#configuration)

```bash
# /home/bitcoin/.lnd/lnd.conf

[Application Options]
alias=Zeus
debuglevel=info
maxpendingchannels=5
listen=localhost

[Bitcoin]
bitcoin.active=1
bitcoin.testnet=1
bitcoin.node=bitcoind

[Bitcoind]
bitcoind.rpcuser=bitcoin
bitcoind.rpcpass=420
bitcoind.zmqpubrawblock=tcp://127.0.0.1:28332
bitcoind.zmqpubrawtx=tcp://127.0.0.1:28333

[autopilot]
autopilot.active=1
autopilot.maxchannels=5
autopilot.allocation=0.6
```

### [LND as a service](https://stadicus.github.io/RaspiBolt/raspibolt_40_lnd.html#autostart-on-boot)

Like the bitcoin daemon, we will turn LND into a service by following this [documentation](https://gist.github.com/bretton/0b22a0503a9eba09df86a23f3d625c13#setup-supervisor-to-run-lnd-automatically).

We use [supervisor](http://supervisord.org/introduction.html) that will manage the lnd service.

```bash
# As administrateur1
$ sudo apt-get install supervisor
$ sudo nvim /etc/supervisor/conf.d/lnd.conf
```

```bash
# /etc/supervisor/conf.d/lnd.conf

[program:lnd]
user=bitcoin
command=/home/bitcoin/go/bin/lnd --configfile=/home/bitcoin/.lnd/lnd.conf
startretries=999999999999999999999999999
autostart=true
autorestart=true
```

```bash
$ sudo supervisorctl reload
```

### [LND Wallet](https://stadicus.github.io/RaspiBolt/raspibolt_40_lnd.html#configuration)

We now have a Lightning node running in the background and connected to our Bitcoin node running on testnet.

```bash
$ systemctl status supervisor.service
> Active: active (running)
...
CGroup: /system.slice/supervisor.service
           ├─7299 /usr/bin/python /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
           └─7420 /home/bitcoin/go/bin/lnd --configfile=/home/bitcoin/.lnd/lnd.conf

# Check logs
$ tail -f ~/.lnd/logs/bitcoin/testnet/lnd.log
> [INF] LTND: Waiting for wallet encryption password. Use `lncli create` to create a wallet, `lncli unlock` to unlock an existing wallet, or `lncli changepassword` to change the password of an existing wallet and unlock it
```

In another terminal, we can create a wallet and unlocking it. Look at the logs in the first terminal to check if everything is going fine.

```bash
# Terminal 2
$ ssh <username>@<dns>
$ sudo su - bitcoin
# Create wallet and save mnemonic
$ lncli create
$ lncli unlock
```

In case you have issue (with permissions for example), try to create a symlink pointing to \$GOPATH.

### [Opening Lightning channel](https://stadicus.github.io/RaspiBolt/raspibolt_40_lnd.html#opening-channels)

Opening a channel has a cost. So we need to first fund our wallet by going on a [bitcoin faucet](https://testnet-faucet.mempool.co/). Paste the address you generated when unlocking your node or create a new one.

```bash
# Terminal 2
$ lncli --network=testnet newaddress np2wkh
> {
    "address": "..."
  }
```

Once the transaction is confirmed, we can fund our lightning node by going on a [lightning faucet](https://faucet.lightning.community/) and paste the following public key. A channel will be open between our node and the faucet.

```bash
# Terminal 2
$ lncli --network=testnet getinfo
> {
    ...
    "identity_pubkey": "02d0e67ad94d503cd8bb5bbdaf7f3abeb16519b3108e02cb80be43ff4a59d284d8",
    ...
  }
```

Wait for transaction to be included.

```bash
# Terminal 2
$ lncli --network=testnet walletbalance
> {
    "total_balance": "100000",
    "confirmed_balance": "100000",
    "unconfirmed_balance": "0"
  }
```

Now we have enough fund, we can open therefore open a channel.

Let's take this [node](https://1ml.com/testnet/node/03b572c05791de9bd14c41cb6eec722375170d0f276fb71fbb918cd7990d5d5d6f).

```bash
# Terminal 2
$ lncli --network=testnet connect 03b572c05791de9bd14c41cb6eec722375170d0f276fb71fbb918cd7990d5d5d6f@81.207.149.246:9535
> {

  }

$ lncli --network=testnet openchannel 03b572c05791de9bd14c41cb6eec722375170d0f276fb71fbb918cd7990d5d5d6f 20000 0
> {
    "funding_txid": "0f4b124447653d918c954a9989722cb1663dce3bd96ef10d22802534b89825c5"
  }
```

## [Tor](https://stadicus.github.io/RaspiBolt/raspibolt_22_privacy.html)

- Installing Tor for more privacy.

  ```bash
  # As administrateur1
  $ sudo nvim /etc/apt/sources.list
  ```

  Add these two lines.

  ```bash
  # /etc/apt/sources.list

  ...
  deb https://deb.torproject.org/torproject.org buster main
  deb-src https://deb.torproject.org/torproject.org buster main
  ...
  ```

- Verify integrity

  ```bash
  $ sudo apt install dirmngr apt-transport-https
  $ curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
  $ gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -
  > OK
  ```

- Install Tor

  ```bash
  $ sudo apt update
  $ sudo apt install tor
  $ tor --version
  > Tor version 0.4.3.6

  $ systemctl status tor
  ● tor.service - Anonymizing overlay network for TCP (multi-instance-master)
     Loaded: loaded (/lib/systemd/system/tor.service; enabled; vendor preset: enabled)
     Active: active (exited) since Sun 2020-09-06 16:27:20 UTC; 2min 12s ago
   Main PID: 6636 (code=exited, status=0/SUCCESS)
      Tasks: 0 (limit: 19141)
     CGroup: /system.slice/tor.service
  ```

  - Add bitcoin user to Tor group

  ```bash
  $ cat /usr/share/tor/tor-service-defaults-torrc
  > User debian-tor

  $ sudo adduser bitcoin debian-tor
  $ cat /etc/group | grep debian-tor
  > debian-tor:x:116:bitcoin
  ```

- Modify Tor config

  ```bash
  # /etc/tor/torrc

  # uncomment:
  ControlPort 9051
  CookieAuthentication 1

  # add:
  CookieAuthFileGroupReadable 1
  ```

- Restart Tor

  ```bash
  $ sudo systemctl restart tor
  ```

Now all network traffic is routed over Tor.

## [Block Explorer](https://stadicus.github.io/RaspiBolt/raspibolt_55_explorer.html)

This part is not over yet. I'm constantly running into network issues between the firewall, tor, bitcoind and the block explorer.

Here's what I'm trying to do.

The block explorer will read data from our bitcoin node but indexing data may be quite heavy for our bitcoin node. So placing a server on top of our node should be necessary, like the one mentioned in the [tutorial](https://stadicus.github.io/RaspiBolt/raspibolt_50_electrs.html#electrs).

_Note: if you didn't set txindex=1 in your bitcoin.conf file, you have to set it and resync_

[Electrs](https://github.com/romanz/electrs) is written in Rust, so we should install Rust.

```bash
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
$ sudo apt install -y clang cmake
```

If Rust is not in your PATH, do the following.

```bash
$ nvim /home/administrateur1/.bashrc
```

```bash
# /home/administrateur1/.bashrc
...
export GOPATH=/home/administrateur1/go
export RUSTPATH=/home/administrateur1/.cargo/bin
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin:$RUSTPATH
...
```

Then we can build the source code

```bash
$ mkdir rust
$ cd rust
$ git clone --branch v0.8.5 https://github.com/romanz/electrs.git
$ cd electrs
$ cargo build --release
$ sudo cp ./target/release/electrs /usr/local/bin/
```

Electrs is now installed and the missing part here is the configuration. It should connect to our bitcoin node and also let the block explorer interact with it.

To install the block explorer + configuration (not finished too :()

- NodeJS

  Install NodeJS by following [this](https://stadicus.github.io/RaspiBolt/raspibolt_55_explorer.html#install-nodejs)

- Firewall

  ```bash
  $ sudo ufw allow from 127.0.0.1 to any port 3002 comment 'allow BTC RPC Explorer from local network'
  $ sudo ufw status
  ```

- [Explorer](https://stadicus.github.io/RaspiBolt/raspibolt_55_explorer.html#btc-rpc-explorer)

  ```bash
  $ sudo adduser btcexplorer
  $ sudo su - btcexplorer
  $ git clone --branch v2.0.1 https://github.com/janoside/btc-rpc-explorer.git
  $ cd btc-rpc-explorer
  $ npm install
  ```

  ```bash
  # /home/btcexplorer/btc-rpc-explorer/.env

    DEBUG=btcexp:app,btcexp:error  # Default

    BTCEXP_HOST=127.0.0.1
    BTCEXP_PORT=3002

    #BTCEXP_BITCOIND_URI=bitcoin://rpcusername:rpcpassword@127.0.0.1:8332?timeout=10000
    BTCEXP_BITCOIND_HOST=127.0.0.1
    BTCEXP_BITCOIND_PORT=18333
    BTCEXP_BITCOIND_USER=bitcoin
    BTCEXP_BITCOIND_PASS=420
    #BTCEXP_BITCOIND_COOKIE=/path/to/bitcoind/.cookie

    # BTCEXP_ADDRESS_API=electrumx

    # BTCEXP_ELECTRUMX_SERVERS=tcp://127.0.0.1:50001

    BTCEXP_PRIVACY_MODE=true

    BTCEXP_RPC_ALLOWALL=false

    BTCEXP_UI_SHOW_TOOLS_SUBHEADER=true
  ```
