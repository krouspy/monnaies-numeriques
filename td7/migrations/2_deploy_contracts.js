// const Kamas = artifacts.require("Kamas");
const Ogrine = artifacts.require("Ogrine");

const kamasAddress = "0xDdc118cDd0a4E27E0Ad37544740C74706d6b7A0f";

module.exports = (deployer) => {
  // deployer.deploy(Kamas);
  deployer.deploy(Ogrine, kamasAddress);
};
