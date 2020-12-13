require('dotenv').config();

const Web3 = require('web3');

const privateKey = process.env.PRIVATE_KEY;
const infuraEndpoint = process.env.INFURA_ENDPOINT;

const web3 = new Web3(new Web3.providers.HttpProvider(infuraEndpoint));

const messageToSign = 'You need to sign this string';

function getWhitelisted() {
  const hashToSign = web3.utils.fromAscii(messageToSign);
  const parametersEncoded = web3.eth.abi.encodeParameters(
    ['bytes32'],
    [hashToSign]
  );
  // signature
  return web3.eth.accounts.sign(parametersEncoded, privateKey);
}

getWhitelisted();
