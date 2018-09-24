var Service1 = artifacts.require("FilmRentalService");
var Service2 = artifacts.require("EBookDownloadService");

module.exports = async function(deployer) {
  await deployer.deploy(Service1);
  await deployer.deploy(Service2);
};
