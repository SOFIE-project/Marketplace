const fs = require("fs");
const ini = require("ini");

const Migrations = artifacts.require("Migrations");
const FlowerMarketPlace = artifacts.require("FlowerMarketPlace");

module.exports = function(deployer, network, accounts) {
  deployer.then(async () => {
    // deploy migrations
    await deployer.deploy(Migrations);
    
    // deploy flowermarketplace
    const flowerMarketPlace = await deployer.deploy(FlowerMarketPlace);

    // update configuration file
    const config = ini.parse(fs.readFileSync('../local-config.cfg', 'utf-8'));
    const net_config = config["marketplace"];

    // update network fields
    net_config.minter = accounts[0];
    net_config.contract = flowerMarketPlace.address;

    const iniText = ini.stringify(config);
    fs.writeFileSync('../local-config.cfg', iniText);
  });
};
