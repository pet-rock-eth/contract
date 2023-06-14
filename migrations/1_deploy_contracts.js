var Mytoken = artifacts.require("./MyToken.sol");

module.exports = function(deployer) {
  deployer.deploy(Mytoken);
};