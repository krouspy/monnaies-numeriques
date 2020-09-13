## Practical Work 2

This PW follows this [tutorial](https://docs.btcpayserver.org/ManualDeployment/).

The objectives of this PW is to plug in [BTCPay server](https://github.com/btcpayserver/btcpayserver) on top of our bitcoin node we set up previously in the [PW1](https://github.com/krouspy/monnaies-numeriques/tree/master/td1). By using this tool, we will be able to receive and secure payments on-chain and off-chain without any third-party. We will also install [NBXplorer](https://github.com/dgarage/NBXplorer), an UTXO tracker and finally, we will create a very simple interface in React.

### Environment

Ubuntu 20.4 LTS

Azure VM running Ubuntu 18.04 LTS

### Installation

All steps assume you are logged as `bitcoin` user.

```bash
$ sudo su - bitcoin
```

BTCPayServer and NBXplorer are built in C# so we first need to install [.NET Core](https://dotnet.microsoft.com/download). Since we will build them directly from source code, we need to download .NET Core SDK. Choose the installation process corresponding to your own environment. In my case, I'm on Ubuntu 18.04 LTS so I'll follow [this](https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#1804-).

_**Note**: Don't forget to disable UFW while we install dependencies_.

```bash
# Add Microsoft package signing key + package repository
$ wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
$ sudo dpkg -i packages-microsoft-prod.deb

# Install .NET Core SDK
$ sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-3.1

# Check installation
$ dotnet --version
> 3.1.402
```

#### [NBXplorer](https://docs.btcpayserver.org/ManualDeployment/#3-install-nbxplorer)

Check [here](https://github.com/dgarage/NBXplorer) for more details.

```bash
$ git clone https://github.com/dgarage/NBXplorer
$ cd NBXplorer
$ ./build.sh
$ ./run.sh --help
```

NBXplorer is now installed but when launching, it will not connect by default to our node so we need to configure it by specifying the network. Also, our node rpc is protected with a user and password that you can get in your bitcoin.conf

```bash
$ cat /home/bitcoin/.bitcoin/bitcoin.conf | grep rpc
> rpcuser=bitcoin
  rpcpassword=420
  rpcallowip=127.0.0.1
```

To specify parameters, you can use flags but it might be more efficient to modify the config file.

```bash
# using flags
# ~/NBXplorer
$ ./run.sh --testnet --btcrpcuser=bitcoin --btcrpcpassword=420
...
> info: Events:         BTC: Node state changed: NBXplorerSynching => Ready
```

Or

```bash
# using config file
# ~/.nbxplore/Testnet/settings.config
...
btc.rpc.user=bitcoin
btc.rpc.password=420
...
```

Then you can run without entering rpc credentials.

```bash
$ ./run.sh --testnet
...
> info: Events:         BTC: Node state changed: NBXplorerSynching => Ready

```

_**Note**: By default the btc testnet node rpc listen on port `18333` so in case you changed it, make sure to runs NBXplorer on the same port._

Also, update your bitcoin.conf to whitelist `127.0.0.1`.

```bash
# ~/.bitcoin/bitcoin.conf
...
whitelist=127.0.0.1
...
```

Then restart bitcoind service.

```bash
$ sudo systemctl restart bitcoind.service
```

We can check if everything is going fine between our node and NBXplorer by sending a HTTP request.

```bash
$ curl http://localhost:24445/health
> {
  "status": "Healthy",
  "results": {
    "NodesHealthCheck": {
      "status": "Healthy",
      "description": null,
      "data": {
        "BTC": "Ready"
      }
    }
  }
}
```

Now that it works fine, we may want to turn it into a service so that it doesn't lock a ssh connection. If you are using something like [tmux](https://doc.ubuntu-fr.org/tmux), you don't have this issue but at least, you will not have to launch it manually.

##### NBXplorer Service

Ubuntu manages services through systemd so to turn NBXplorer into a service, we create a service file in `/etc/systemd/system`.

```bash
# /etc/systemd/system/nbxplorer.service
# config example found here
# https://gist.github.com/mariodian/de873b969e70eca4d0a7673efd697d0a

[Unit]
Description=NBXplorer daemon
Requires=bitcoind.service
After=bitcoind.service

[Service]
ExecStart=/usr/bin/dotnet "/home/bitcoin/NBXplorer/NBXplorer/bin/Release/netcoreapp3.1/NBXplorer.dll" -c /home/bitcoin/.nbxplorer/TestNet/settings.config --testnet
User=bitcoin
Group=bitcoin
Type=simple
PIDFile=/run/nbxplorer/nbxplorer.pid
Restart=on-failure

PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
PrivateDevices=true

[Install]
WantedBy=multi-user.target
```

Then we can enable the service.

```bash
$ sudo systemctl enable nbxplorer.service
$ sudo reboot
```

Wait a little then log back in and check if the service started properly.

```bash
$ sudo service nbxplorer status
> ● nbxplorer.service - NBXplorer daemon
   Loaded: loaded (/etc/systemd/system/nbxplorer.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2020-09-12 09:39:41 UTC; 41s ago
 Main PID: 2728 (dotnet)
    Tasks: 23 (limit: 19141)
   CGroup: /system.slice/nbxplorer.service
           └─2728 /usr/bin/dotnet /home/bitcoin/NBXplorer/NBXplorer/bin/Release/netcoreapp3.1/NBXplorer.dll -c /home/bitcoin/.nbxplorer/TestNet/settings.config --testnet
```

### [BTCPay Server](https://docs.btcpayserver.org/ManualDeployment/#4-install-btcpayserver)

Get source code on their [github](https://github.com/btcpayserver/btcpayserver).

```bash
$ git clone https://github.com/btcpayserver/btcpayserver
$ cd btcpayserver
$ ./build.sh
$ ./run.sh -h
```

Update config file to always connect on testnet

```bash
# ~/.btcpayserver/TestNet/settings.config

network=testnet
```

Now, we might want to turn it into a service for same reasons as NBXplorer, bitcoind and lnd.

```bash
# /etc/systemd/system/btcpayservice.service
# config example found here
# https://gist.githubusercontent.com/mariodian/07bb13da314e2a321784b380f543651a/raw/6cef554d9e8311e683a017d5e63a07822dee7642/btcpayserver.service

[Unit]
Description=BTCPayServer Daemon
Requires=nbxplorer.service
After=nbxplorer.service

[Service]
ExecStart=/usr/bin/dotnet run --no-launch-profile --no-build -c Release -p "/home/bitcoin/btcpayserver/BTCPayServer/BTCPayServer.csproj" --conf=/home/bitcoin/.btcpayserver/TestNet/settings.config -- $@
User=bitcoin
Group=bitcoin
Type=simple
PIDFile=/run/btcpayserver/btcpayserver.pid
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Turn on the service and log back in to check if it works fine.

```bash
$ sudo systemctl enable btcpayserver.service
$ sudo reboot
$ ssh <user>@<ip_address>
$ systemctl status btcpayserver.service
> ● btcpayserver.service - BTCPayServer Daemon
   Loaded: loaded (/etc/systemd/system/btcpayserver.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2020-09-13 00:19:00 UTC; 6min ago
 Main PID: 36061 (dotnet)
    Tasks: 37 (limit: 19141)
   CGroup: /system.slice/btcpayserver.service
           ├─36061 /usr/bin/dotnet run --no-launch-profile --no-build -c Release -p /home/bitcoin/btcpayserver/BTCPayServer/BTCPayServer.csproj --conf=/home/bitcoin/.btcpayserver/TestNet/settings.config --
           └─36112 /home/bitcoin/btcpayserver/BTCPayServer/bin/Release/netcoreapp3.1/BTCPayServer --conf=/home/bitcoin/.btcpayserver/TestNet/settings.config

Sep 13 00:19:03 mesimf595420-0018 dotnet[36061]: info: Configuration:  BTC: Cookie file is /home/bitcoin/.nbxplorer/TestNet/.cookie
Sep 13 00:19:03 mesimf595420-0018 dotnet[36061]: info: PayServer:      Starting listening NBXplorer (BTC)
Sep 13 00:19:03 mesimf595420-0018 dotnet[36061]: info: PayServer:      Start watching invoices
Sep 13 00:19:03 mesimf595420-0018 dotnet[36061]: info: PayServer:      Starting payment request expiration watcher
Sep 13 00:19:03 mesimf595420-0018 dotnet[36061]: info: Events:         NBXplorer BTC: NotConnected => Ready
Sep 13 00:19:03 mesimf595420-0018 dotnet[36061]: info: PayServer:      BTC: Checking if any pending invoice got paid while offline...
Sep 13 00:19:03 mesimf595420-0018 dotnet[36061]: info: PayServer:      BTC: 0 payments happened while offline
Sep 13 00:19:03 mesimf595420-0018 dotnet[36061]: info: PayServer:      Connected to WebSocket of NBXplorer (BTC)
Sep 13 00:19:03 mesimf595420-0018 dotnet[36061]: info: PayServer:      0 pending payment requests being checked since last run
Sep 13 00:19:03 mesimf595420-0018 dotnet[36061]: info: Configuration:  Listening on http://127.0.0.1:23001
```

### Update UFW

Now that we installed NBXplorer and BTCPayServer, we should update our firewall to allow connections to the port they are serving.

Here are the ports that need to be open:

- ssh - port 22 - from anywhere
- bitcoin node - port 18333 (protocol listens on port 18333)
- lnd - port 9735 - from anywhere (lnd talks to other remote peers)
- NBXplorer - port 24445 - from localhost (BTCPayServer reads data from NBXplorer)
- BTCPayServer - port 23001 - from anywhere (remote people will interact with it)

```bash
$ sudo ufw enable
$ sudo ufw default allow outgoing
$ sudo ufw allow 18333 comment 'allow bitcoin node'
$ sudo ufw allow 9735 comment 'allow lnd from anywhere'
$ sudo ufw allow from 127.0.0.1 to any port 24445 comment 'allow NBXplorer node from localhost'
$ sudo ufw allow 23001 comment 'allow BTCPayServer from anywhere'
$ sudo reboot
```

At the end, UFW should look like this:

```bash
$ sudo ufw status
> Status: active

To                         Action      From
--                         ------      ----
22                         ALLOW       Anywhere                   # allow SSH
9735                       ALLOW       Anywhere                   # allow lnd
18333                      ALLOW       Anywhere                   # allow bitcoin node
24445                      ALLOW       127.0.0.1                  # allow NBXplorer from localhost
23001                      ALLOW       Anywhere                   # allow BTCPayServer
22 (v6)                    ALLOW       Anywhere (v6)              # allow SSH
9735 (v6)                  ALLOW       Anywhere (v6)              # allow lnd
18333 (v6)                 ALLOW       Anywhere (v6)              # allow bitcoin node
23001 (v6)                 ALLOW       Anywhere (v6)              # allow BTCPayServer
```

### SSH Tunneling

Like the documentation [says](https://docs.btcpayserver.org/RegisterAccount/), we need to setup BTCPayServer by browsing `http://localhost:23001`. If you are running everything on your own computer then you can open this url in your browser. In my case, I'm running a remote VM so here the url refers to the VM and to be able to view the web page, I need to use `SSH tunneling`.

```bash
$ ssh -L 8080:localhost:23001 <user>@<dns_address>
```

This command opens a SSH connection between what is served on `localhost:23001` by the remote machine and `localhost:8080` served by our local machine.

By browsing `localhost:8080` on our local computer, we can see the web page.

![alt BTCPayServer](./assets/btcpay.png 'BTCPayServer')

#### [Receive Payments](https://docs.btcpayserver.org/Apps/#point-of-sale-app)

Now we will allow users to pay invoices. First we need to [create a store](https://docs.btcpayserver.org/CreateStore/). Go to `Stores > Create a new store`. Then fill the textfield.

To receive payments, we also need a wallet so let's [create one](https://docs.btcpayserver.org/WalletSetup/).

We have multiple choice for our wallet, you can either import an external wallet (hot and cold) or create a new one managed by BTCPayServer.

In my case, I choose to create a new one from BTCPayServer.

Go to `Store > General Settings > Derivation Scheme > Import from a new/existing seed > Generate`.

![alt Derivation](./assets/derivation.png 'Derivation')

A seed phrase will be printed out, save it if you plan to play with real funds and disable the hot wallet option so that it will not be saved on your server.

##### [Pay Button](https://docs.btcpayserver.org/Apps/#payment-button)

To enable users to send payments, we can use the `Pay Button` feature.

Go to your `Store settings > Pay Button`. Enter the parameters you want and at the bottom of the page, you will find the `Generated Code` area like this one:

```html
<form
  method="POST"
  action="http://localhost:8080/api/v1/invoices"
  class="btcpay-form btcpay-form--block"
>
  <input
    type="hidden"
    name="storeId"
    value="ArHTqAhGinUKeoGBPJfaX2EGqhNeFnfaGoRk6qJKFBS5"
  />
  <input type="hidden" name="price" value="10" />
  <input type="hidden" name="currency" value="USD" />
  <input
    type="image"
    class="submit"
    name="submit"
    src="http://localhost:8080/img/paybutton/pay.svg"
    style="width:209px"
    alt="Pay with BtcPay, Self-Hosted Bitcoin Payment Processor"
  />
</form>
```

This block corresponds to the Pay Button with parameters you just entered. Clicking on this button tells BTCPayServer that an invoice with these parameters has to be created.

Before testing, we will create a very simple interface in React containing 2 buttons:

- One to receive payment on-chain
- One to receive payment off-chain (lnd)

### [React](https://reactjs.org/)

You can use [create-react-app](https://github.com/facebook/create-react-app) if you want to bootstrap your project but it might be a bit too bloated for our project. Instead, I prefer using [parcel-bundler](https://github.com/parcel-bundler/parcel) which is way more lightweight.

```bash
$ mkdir interface
$ cd interface

# packages
$ yarn init -y
$ yarn add -D parcel-bundler
$ yarn add react react-dom

# create project structure
$ mkdir public
$ touch public/index.html
$ mkdir src
$ touch src/index.jsx
$ touch src/App.jsx
```

Edit files.

```html
<!-- public/index.html -->

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Payments</title>
  </head>
  <body>
    <div id="root"></div>
    <script src="../src/index.jsx"></script>
  </body>
</html>
```

```js
// src/index.jsx

import React from 'react';
import { render } from 'react-dom';
import App from './App';

render(<App />, document.getElementById('root'));
```

```js
// src/App.js

import React from 'react';

const style = {
  display: 'flex',
  flexDirection: 'column',
  justifyContent: 'center',
  alignItems: 'center',
};

export default () => {
  return (
    <div style={style}>
      <h2>You can pay me on-chain</h2>
      <form method="POST" action="http://localhost:8080/api/v1/invoices">
        <input
          type="hidden"
          name="storeId"
          value="ArHTqAhGinUKeoGBPJfaX2EGqhNeFnfaGoRk6qJKFBS5"
        />
        <input type="hidden" name="price" value="2" />
        <input type="hidden" name="currency" value="USD" />
        <input
          type="image"
          src="http://localhost:8080/img/paybutton/pay.svg"
        ></input>
      </form>
      <h2>Or with Lightning for faster transactions</h2>
    </div>
  );
};
```

Update your package.json by adding scripts to launch your app.

```json
{
  "name": "interface",
  "version": "1.0.0",
  "main": "src/index.jsx",
  "license": "MIT",
  "scripts": {
    "start": "parcel ./public/index.html",
    "build": "parcel build ./public/index.html"
  },
  "devDependencies": {
    "parcel-bundler": "^1.12.4",
    "prettier": "^2.1.1"
  },
  "dependencies": {
    "react": "^16.13.1",
    "react-dom": "^16.13.1"
  }
}
```

Now you can run `yarn start` and we can check the interface at `localhost:1234`.

![alt front](./assets/front.png 'Front')

The green button corresponds to the Pay Button for on-chain payments and clicking on it will create an invoice.

_**Note**: The lightning button is not still here, we will check it later._

Previously, in the PW1, we deposited some tBTC on our bitcoin node so we can use it to pay the invoice.

```bash
$ bitcoin-cli -testnet sendtoaddress tb1qn48tfmww05l5h9234tpeefq7kesyc5vu7ve4q6 0.00019423
```

![alt invoice](./assets/invoice.png 'Invoice')

Here's the transaction hash viewable on [testnet explorer](https://blockstream.info/testnet/tx/4d53c89d1e367d538a73410c5072c7653718813a778c4221fcec36adc71fac6c).

> 4d53c89d1e367d538a73410c5072c7653718813a778c4221fcec36adc71fac6c

### Lightning Payments

I didn't manage to make this part work but here's what I did.

When interacting with `lnd`, `BTCPayServer` uses the `lnd` REST api so we need to update our firewall.

```bash
$ sudo ufw allow 8080 comment 'allow lnd rest'
# just in case lol
$ sudo ufw allow 10009 comment 'allow lnd rpc'
```

Also update lnd configuration file to let REST/RPC api listen for any ip address.

```bash
# ~/.lnd/lnd.conf

[Application Options]
alias=Zeus
debuglevel=info
maxpendingchannels=5
listen=0.0.0.0:9735
restlisten=0.0.0.0:8080
rpclisten=0.0.0.0:10009
tlsextraip=0.0.0.0

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

Now go to your `Store settings > Lightning nodes > Modify > Connection string`

Get the `certthumbprint`

```bash
$ openssl x509 -noout -fingerprint -sha256 -in .lnd/tls.cert | sed -e 's/.*=//;s/://g'
```

Then enter this for the connection string

`type=lnd-rest;server=https://127.0.0.1:8080/;macaroonfilepath=/home/bitcoin/.lnd/data/chain/bitcoin/testnet/admin.macaroon;certthumbprint=<cert fingerprint>`

Test Connection > Error while connecting to the API (The HTTP status code of the response was not expected (404).)

Don't know how to fix this :( Maybe a dumb mistake. Make a PR if you know :)
