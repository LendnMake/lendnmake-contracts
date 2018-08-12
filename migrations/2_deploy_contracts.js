var FINET = artifacts.require("EIP20.sol");

module.exports = function(deployer) {
  deployer.deploy(FINET, web3.eth.accounts[0], { gas: 3000000 });
};
