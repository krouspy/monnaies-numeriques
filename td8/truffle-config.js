require("dotenv").config();

const HDWalletProvider = require("@truffle/hdwallet-provider");

const private_key = process.env.PRIVATE_KEY;
const infura_endpoint = process.env.INFURA_ENDPOINT;

module.exports = {
  networks: {
    rinkeby: {
      provider: () => new HDWalletProvider(private_key, infura_endpoint),
      network_id: 4,
      gas: 5500000,
    },
  },
  compilers: {
    solc: {
      version: "0.6.6",
    },
  },
};
