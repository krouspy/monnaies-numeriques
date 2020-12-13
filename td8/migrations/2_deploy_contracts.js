const BouncerProxy = artifacts.require("BouncerProxy");
const MyERC20 = artifacts.require("MyERC20");

module.exports = async (deployer) => {
  await deployer.deploy(BouncerProxy);
  await deployer.deploy(MyERC20);
};
