require("dotenv").config();

/**
 * Note: This file serves to express the idea to get the signature to call the forward function from BouncerProxy
 * because I'm in rush
 */

const Web3 = require("web3");
// assume to have it
const { BOUNCER_PROXY_ADDRESS, BOUNCER_PROXY_ABI } = require("./config");

// someone private key
const someone = "...";
const infuraEndpoint = process.env.INFURA_ENDPOINT;

const web3 = new Web3(new Web3.providers.HttpProvider(infuraEndpoint));

async function getSignature() {
  const encoded = web3.eth.abi.encodeParameters(
    ["address", "uint256"],
    [ERC721_ADDRESS, tokenId]
  );
  const hash = web3.utils.sha3(encoded);

  const signature = web3.eth.accounts.sign(hash, someone);
  console.log(signature);
}

getSignature();
