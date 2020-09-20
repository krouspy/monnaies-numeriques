const HDWalletProvider = require("@truffle/hdwallet-provider");

const mnemonic =
  "slight code awkward general slow east happy pride retreat cotton bulk axis";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    rinkeby: {
      provider: function () {
        return new HDWalletProvider(mnemonic, "http://localhost:8080");
      },
      network_id: 4,
      gas: 4500000,
      gasPrice: 10000000000,
    },
  },
};
