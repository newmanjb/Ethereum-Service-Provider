var Service1 = artifacts.require("FilmRentalService");
var ServiceProvider = artifacts.require("ServiceProvider");

module.exports = async function(deployer) {
  await deployer.deploy(Service1);
  deployer.deploy(ServiceProvider,[Service1.address]);
};
