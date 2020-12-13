require("dotenv").config();

const Web3 = require("web3");
const { ERC721_ADDRESS, ERC721_ABI } = require("./config");

const someone =
  "231f08f76e34f65ca5ffea4dcb21cef3c46783fd44f0f324149088005f8633bc";
const infuraEndpoint = process.env.INFURA_ENDPOINT;

const web3 = new Web3(new Web3.providers.HttpProvider(infuraEndpoint));

function getNextTokenId() {
  const erc721 = new web3.eth.Contract(ERC721_ABI, ERC721_ADDRESS);
  return erc721.methods.nextTokenId().call();
}

async function getSignature() {
  const tokenId = await getNextTokenId();
  const encoded = web3.eth.abi.encodeParameters(
    ["address", "uint256"],
    [ERC721_ADDRESS, tokenId]
  );
  const hash = web3.utils.sha3(encoded);

  const signature = web3.eth.accounts.sign(hash, someone);
  console.log(signature);
}

getSignature();
