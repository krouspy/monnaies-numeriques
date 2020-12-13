## Practical Work 8

Instructions:

- Create a truffle project and configure it on Infura
- Create a mintable ERC721 smart contract
- Create a minter contract that is allowed to mint ERC721 tokens
- Integrate function signerIsWhitelisted() from bouncerProxy in your contract with all associated variables
- Get whitelisted on contract 0x53bb77F35df71f463D1051061B105Aafb9A87ea1 on Rinkeby

  const parametersEncoded = web3.eth.abi.encodeParameters(['bytes32'], [_hashToSign])
  const signature = await web3.eth.sign(parametersEncoded,accounts[1])

- Claim a token on contract 0x3e2E325Ffd39BBFABdC227D31093b438584b7FC3 through contract 0x53bb77F35df71f463D1051061B105Aafb9A87ea1

  Example:

  Token 0: authorized mint by address 0xB7ef740b7A112a161658321c58F722a26552E1De, and mint tx sent by address 0x91C0a472BD61eD9F4164305f3Ae0B459DDbd072D

  https://rinkeby.etherscan.io/tx/0x3ab14a5132dbe58a7e4ecddb89f510100b01d139868ac906088b0d860473764b

- Create on your contract a function claimToken() that receives a signed hash from the contract deployer and a token number to mint a token
- Deploy bouncerProxy() contract and an ERC20 contract(). Whitelist an address A on the bouncer and credit 10 tokens to this address in the ERC20
- Claim a token from your ERC721, through the bouncerProxy() by sending an authorization signed by A, in a TX sent by address B
- Same as question 8, but address A must tip address B in ETH
- Same as previous question 8, but address A must tip address B with ERC20 token deployed in question 7

### Setup Project

```bash
$ yarn init -y
$ yarn add truffle solc@0.6.6 @openzeppelin/contracts @truffle/hdwallet-provider dotenv
$ ./node_modules/.bin/truffle init
```

Configure truffle

```javascript
// truffle-config.js
require('dotenv').config();

const HDWalletProvider = require('@truffle/hdwallet-provider');

const private_key = process.env.PRIVATE_KEY;
const infura_endpoint = process.env.INFURA_ENDPOINT;

module.exports = {
  networks: {
    rinkeby: {
      provider: () => new HDWalletProvider(private_key, infura_endpoint),
      network_id: 4,
      gas: 5500000,
    },
    compilers: {
      solc: {
        version: '0.6.6',
      },
    },
  },
};
```

Update `package.json`

```json
{
  "name": "td8",
  "version": "1.0.0",
  "main": "index.js",
  "license": "MIT",
  "scripts": {
    "compile": "truffle compile",
    "develop": "truffle develop",
    "console:rinkeby": "truffle console --network rinkeby",
    "deploy:rinkeby": "truffle migrate --network rinkeby --reset"
  },
  "dependencies": {
    "@openzeppelin/contracts": "^3.3.0",
    "@truffle/hdwallet-provider": "^1.2.0",
    "dotenv": "^8.2.0",
    "truffle": "^5.1.57"
  }
}
```

### ERC721

> Instruction: Create a mintable ERC721 smart contract

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Steak is ERC721, Ownable {
    event MinterAdded(address indexed account);

    mapping (address => bool) public minters;
    uint256 private tokenId;

    constructor() public ERC721("Steak", "STK") {
        minters[msg.sender] = true;
    }

    function addMinter(address account) public onlyOwner returns (bool) {
        require(!minters[account], "Steak: address is already whitelisted");

        minters[account] = true;
        emit MinterAdded(account);

        return true;
    }

    function mint(address account) public returns (bool) {
        require(minters[msg.sender], "Steak: caller must be whitelisted");

        _safeMint(account, tokenId);
        tokenId++;
        return true;
    }
}
```

> Instruction: Create a minter contract that is allowed to mint ERC721 tokens

Steak creator must whitelist this contract to allow it to mint

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Steak.sol";

contract SteakFactory is Ownable {
    Steak private steak;

    constructor(Steak _steak) public {
        steak = _steak;
    }

    function mintSteak(address account) public {
        steak.mint(account);
    }
}
```

> Instruction: Integrate function signerIsWhitelisted() from bouncerProxy in your contract with all associated variables

```javascript
// contracts/SteakFactory.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Steak.sol";

contract SteakFactory is Ownable {
    Steak private steak;
    mapping(address => bool) public whitelist;

    constructor(Steak _steak) public {
        steak = _steak;
        whitelist[msg.sender] = true;
    }

    function mintSteak(address account) public {
        steak.mint(account);
    }

    function signerIsWhitelisted(bytes32 _hash, bytes memory _signature) internal view returns (bool){
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Check the signature length
        if (_signature.length != 65) {
            return false;
        }
        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return false;
        } else {
            // solium-disable-next-line arg-overflow
            return whitelist[ecrecover(keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            ), v, r, s)];
        }
    }
}
```

## Get Whitelisted

> Instruction: Get whitelisted on contract 0x53bb77F35df71f463D1051061B105Aafb9A87ea1 on Rinkeby

We can take a look to the contract we have to interact with that is viewable [here](https://rinkeby.etherscan.io/address/0x53bb77f35df71f463d1051061b105aafb9a87ea1#code)

We can see that to get whitelisted we need to call `getWhiteListed(bytes memory signature)`. The signature is obtained by signing the message `You need to sign this string` with the account we want to whitelist.

```javascript
// scripts/whitelist.js
require('dotenv').config();

const Web3 = require('web3');

const privateKey = process.env.PRIVATE_KEY;
const infuraEndpoint = process.env.INFURA_ENDPOINT;

const web3 = new Web3(new Web3.providers.HttpProvider(infuraEndpoint));

const messageToSign = 'You need to sign this string';

function main() {
  const hashToSign = web3.utils.fromAscii(messageToSign);
  const parametersEncoded = web3.eth.abi.encodeParameters(
    ['bytes32'],
    [hashToSign]
  );

  const signature = web3.eth.accounts.sign(parametersEncoded, privateKey);
  console.log(signature);
}

main();
```

Output:

```json
{
  "message": "0x596f75206e65656420746f207369676e207468697320737472696e6700000000",
  "messageHash": "0x7804c4b60317a8370c2ec85f9601ee2793896d3b638ba3a8023e0281affc8afb",
  "v": "0x1b",
  "r": "0x4c2679c1d7ca942643c38d50aa8d27775cf33cf16f1bc8cf75926324026b3488",
  "s": "0x52d6327a75005e35efebf2fa4f7e726dc0c8b2b17c0b9ca04a1c818ef0a8907b",
  "signature": "0x4c2679c1d7ca942643c38d50aa8d27775cf33cf16f1bc8cf75926324026b348852d6327a75005e35efebf2fa4f7e726dc0c8b2b17c0b9ca04a1c818ef0a8907b1b"
}
```

The field we want is `signature` so `0x4c2679c1d7ca942643c38d50aa8d27775cf33cf16f1bc8cf75926324026b348852d6327a75005e35efebf2fa4f7e726dc0c8b2b17c0b9ca04a1c818ef0a8907b1b`.

Then we can get whitelisted by first getting a `MetaTxExercice` instance. For that we need his abi and his address.

- address: 0x53bb77F35df71f463D1051061B105Aafb9A87ea1
- abi: go on [etherscan](https://rinkeby.etherscan.io/address/0x53bb77f35df71f463d1051061b105aafb9a87ea1#code) and at the bottom there is the abi

Now we can get the instance and call the `getWhiteListed(...)`

```javascript
$ yarn console:rinkeby
> const me = '0xE23742d08a46d11e4e1dDf0637221a0b9C6e9cd8'
> const abi = [...]
> const address = '0x53bb77F35df71f463D1051061B105Aafb9A87ea1'
> const metaTx = new web3.eth.Contract(abi, address)
> const signature = '0x4c2679c1d7ca942643c38d50aa8d27775cf33cf16f1bc8cf75926324026b348852d6327a75005e35efebf2fa4f7e726dc0c8b2b17c0b9ca04a1c818ef0a8907b1b'
> metaTx.methods.getWhiteListed(signature).send({ from: me })
> metaTx.methods.whitelist(me).call()
true
```

Here's the transaction hash [0xdbaac99b1e321ac221e4b65a48c8efe27da6995a2671b2ce67d78d305332ccb2](https://rinkeby.etherscan.io/tx/0xdbaac99b1e321ac221e4b65a48c8efe27da6995a2671b2ce67d78d305332ccb2)

### Claim Token

> Instruction: Claim a token on contract 0x3e2E325Ffd39BBFABdC227D31093b438584b7FC3 through contract 0x53bb77F35df71f463D1051061B105Aafb9A87ea1

For this section there are 2 points to handle:

- Who signs the message
- Which message to sign

The function we have to call is the following:

```javascript
function claimAToken(bytes memory _signature) public returns (bool) {
    ERC721TD myERC721 = ERC721TD(ERC721address);
    // Finding next token id
    uint nextTokenToMint = myERC721.nextTokenId();
    // Creating a hash of the concatenation of the ERC721 address and the next token to mint
    bytes32 _hash = keccak256(abi.encode(ERC721address, nextTokenToMint));
    // Checking that the signer of the mint order is authorized
    require(signerIsWhitelisted(_hash, _signature), "Claim: signer not whitelisted or signature invalid");

    // Checking that the authorized minter is not the claimer
    address tokenMintedBy = extractAddress(_hash, _signature);
    require(tokenMintedBy != msg.sender, "Minter and sender must be different");

    myERC721.mint(msg.sender);
}
```

#### Who signs the message?

The point is to allow others to interact with the blockchain without them having any funds. So it is an address different from the one we whitelisted previously. To do that we first need to get a new address and whitelist it.

Go on metamask and create a new rinkeby account then whitelist it.

```javascript
> const me = "0xE23742d08a46d11e4e1dDf0637221a0b9C6e9cd8"
> const someone = "0x868d0BE055cC843948Bd004A485f888a77E42fdd"
> metaTx.methods.updateWhitelist(someone, true).send({ from: me })
'0x2690c075d6391515aaa236b197445e5ebe682730a49ae07b2c7638b09e6ee151',
> metaTx.methods.whitelist(someone).call()
true
```

#### Signature

The message to sign is this one `keccak256(abi.encode(ERC721address, nextTokenToMint))`. We encode the `ERC721 address` and the `nextTokenToMint` then sign it.

```javascript
// scripts/claimToken.js

require('dotenv').config();

const Web3 = require('web3');
const { ERC721_ADDRESS, ERC721_ABI } = require('./config');

const someone = '...';
const infuraEndpoint = process.env.INFURA_ENDPOINT;

const web3 = new Web3(new Web3.providers.HttpProvider(infuraEndpoint));

function getNextTokenId() {
  const erc721 = new web3.eth.Contract(ERC721_ABI, ERC721_ADDRESS);
  return erc721.methods.nextTokenId().call();
}

async function getSignature() {
  const tokenId = await getNextTokenId();
  const encoded = web3.eth.abi.encodeParameters(
    ['address', 'uint256'],
    [ERC721_ADDRESS, tokenId]
  );
  const hash = web3.utils.sha3(encoded);

  const signature = web3.eth.accounts.sign(hash, someone);
  console.log(signature);
}

getSignature();
```

Output

```json
{
  "message": "0x34dc8d03bcbca2666317151067d80a06f372ebc086dace48df737bbc2d936cee",
  "messageHash": "0xd733b22f7cec1273925289d9a2a2d45802cf012ef93564db138b91953e5fa360",
  "v": "0x1b",
  "r": "0xd78be4ccb2ab5dab56093a6cb5f8619cb06c10019b1b58aae2ba74f7a511a9a3",
  "s": "0x1b1a09f60f85a385424abf72d4faac59cb0020a4f3932e11eae8183f3fb3c4ef",
  "signature": "0x4be56573c0f2f7dc7529aa9d42b3195cba8169f464ff298c2fe97e4456bee153446561b18f346145a9a293751e4d8be0a6c252b84b2749e3708c3c7ca05afa501b"
}
```

The field we want is `signature` so `0x4be565...fa501b`.

Then we can claim a Token.

```javascript
> metaTx.methods.claimAToken("0x4be56573c0f2f7dc7529aa9d42b3195cba8169f464ff298c2fe97e4456bee153446561b18f346145a9a293751e4d8be0a6c252b84b2749e3708c3c7ca05afa501b").send({ from: me })
```

Here is the transaction hash [0xc7e6e9a41f298afea5846bd9adb5f5b2eb2a2ce65e3c18287d4cea7de6fc7bd4](https://rinkeby.etherscan.io/tx/0xc7e6e9a41f298afea5846bd9adb5f5b2eb2a2ce65e3c18287d4cea7de6fc7bd4) viewable on etherscan.

> Instruction: Create on your contract a function claimToken() that receives a signed hash from the contract deployer and a token number to mint a token

With the following, someone can claim tokens by first call `getWhitelisted()` then call `claimToken(signature, tokenId)`. The `tokenId` must be unique and the signature is obtainable the same way we obtained the signature above by just replacing the `address` field by `bytes32`.

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Steak.sol";

contract SteakFactory is Ownable {
    Steak private steak;

    mapping(address => bool) public whitelist;

    bytes32 public constant hashToSignToClaimAToken = "Miam Miam les steaks";

    constructor(Steak _steak) public {
        steak = _steak;
        whitelist[msg.sender] = true;
    }

    function claimToken(bytes memory _signature, uint256 tokenId) public {
        bytes32 _hash = keccak256(abi.encode(hashToSignToClaimAToken, tokenId));

        require(signerIsWhitelisted(_hash, _signature), "claimToken: signer is not whitelisted or signature invalid");

        address signerAddress = extractAddress(_hash, _signature);
        require(signerAddress != msg.sender, "claimToken: Minter and Signer must be different");

        steak.mint(signerAddress);
    }

    function getWhitelisted() public returns (bool) {
        require(!whitelist[msg.sender], "getWhitelisted: caller already whitelisted");

        whitelist[msg.sender] = true;

        return true;
    }

    function signerIsWhitelisted(bytes32 _hash, bytes memory _signature) internal view returns (bool){
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Check the signature length
        if (_signature.length != 65) {
            return false;
        }
        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return false;
        } else {
            // solium-disable-next-line arg-overflow
            return whitelist[ecrecover(keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            ), v, r, s)];
        }
    }

    function extractAddress(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Check the signature length
        if (_signature.length != 65) {
            return address(0);
        }
        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
                ), v, r, s);
        }
    }
}
```

Also we modify our Steak contract to allow passing a tokenId that we can get by calling `steak.nextTokenId()`.

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Steak is ERC721, Ownable {
    event MinterAdded(address indexed account);

    mapping (address => bool) public minters;
    uint256 private nextTokenId;

    constructor() public ERC721("Steak", "STK") {
        minters[msg.sender] = true;
    }

    function addMinter(address account) public onlyOwner returns (bool) {
        require(!minters[account], "Steak: address is already whitelisted");

        minters[account] = true;
        emit MinterAdded(account);

        return true;
    }

    function mint(address _account, uint256 _tokenId) public returns (bool) {
        require(minters[msg.sender], "Steak: caller must be whitelisted");

        _safeMint(_account, _tokenId);
        nextTokenId++;

        return true;
    }
}
```

### BouncerProxy & ERC20

> Instruction: Deploy bouncerProxy() contract and an ERC20 contract(). Whitelist an address A on the bouncer and credit 10 tokens to this address in the ERC20

I took the `BouncerProxy` from [here](https://github.com/austintgriffith/bouncer-proxy/blob/master/BouncerProxy/BouncerProxy.sol) but got an issue. I changed the solidity version from 0.4.24 to 0.6.6 because I don't want and really don't have time to check how to manage multiple versions. Maybe the error comes from that but otherwise I don't know.

![alt BouncerProxy](./assets/bouncer-proxy-error.png 'error')

So sorry but for the following I will just "guess". (I'm in rush)

Only whitelisted addresses can mint tokens. In our case, we must whitelist the BouncerProxy contract.

```javascript
// contracts/MyERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyERC20 is ERC20, Ownable {
    mapping (address => bool) public whitelist;

    constructor() public ERC20("MyERC20", "ERC") { }

    function manageWhitelist(address account, bool isWhitelisted) public onlyOwner {
        whitelist[account] = isWhitelisted;
    }

    // must whitelist BoucerProxy
    function mint(address _account, uint256 _amount) public {
        require(whitelist[msg.sender], "Mint: Caller must be whitelisted");

        _mint(_account, _amount);
    }
}

```

Migrations

```javascript
// migrations/2_deploy_contracts.js
const BouncerProxy = artifacts.require('BouncerProxy');
const MyERC20 = artifacts.require('MyERC20');

module.exports = async deployer => {
  await deployer.deploy(BouncerProxy);
  await deployer.deploy(MyERC20);
};
```

To whitelist an address on the BouncerProxy we need the contract `abi` and `address` to get an instance of the contract (like above) then call `updateWhitelist(account, true)`. **The caller must be the contract deployer**.

To credit tokens through BouncerProxy we should call the `forward(...)` function with the following parameters:

- sig: signature of `keccak256(abi.encodePacked(address(this), signer, destination, value, data, rewardToken, rewardAmount, nonce[signer]))`
- signer: signer address
- destination: ERC20 address
- value: ether we want to send
- data: hash of the ERC20 mint function + parameters (honestly don't know how to get that maybe the same way as we obtain the signature)
- rewardToken: ERC20 address
- rewardAmount: tokens to mint to the Bouncer (the one sending on behalf of signer)

If the parameters are correct, the BouncerProxy contract will call the ERC20 mint() function

> Instruction: Claim a token from your ERC721, through the bouncerProxy() by sending an authorization signed by A, in a TX sent by address B

Should be similar to above. Address A crafts the transaction then Address B sends it to the `forward(...)` function. The `data` field contains the ERC721 function we want to call with corresponding parameters.

> Instruction: Same as question 8, but address A must tip address B in ETH

Similar as above but with the `value` field set to the amount of ether we want to tip the Bouncer.

> Instruction: Same as previous question 8, but address A must tip address B with ERC20 token deployed in question 7

Similar as above but with `rewardToken` and `rewardAmount` set to an ERC like our own ERC20.
