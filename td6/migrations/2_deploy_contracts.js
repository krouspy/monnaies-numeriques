const ERC20TD = artifacts.require("ERC20TD");
const DepositorContract = artifacts.require("DepositorContract");
const DepositorToken = artifacts.require("DepositorToken");

const initialSupply = 10000;
const teacherERC20Address = "0x58e9b79f804ebd4a3109068e1be414d0baac18ec";

module.exports = (deployer, network) => {
  if (network === "rinkeby") {
    deployer
      .deploy(DepositorToken)
      .then(async (depositorToken) => {
        const depositorContract = await deployer.deploy(
          DepositorContract,
          teacherERC20Address,
          depositorToken.address
        );
        return { depositorToken, depositorContract };
      })
      .then(async ({ depositorToken, depositorContract }) => {
        await depositorToken.setDepositorContractAddress(
          depositorContract.address
        );
      });
  } else {
    deployer
      .deploy(ERC20TD, initialSupply)
      .then(async (erc20) => {
        const depositorToken = await deployer.deploy(DepositorToken);
        return { erc20, depositorToken };
      })
      .then(async ({ erc20, depositorToken }) => {
        const depositorContract = await deployer.deploy(
          DepositorContract,
          erc20.address,
          depositorToken.address
        );

        await depositorToken.setDepositorContractAddress(
          depositorContract.address
        );
      });
  }
};
