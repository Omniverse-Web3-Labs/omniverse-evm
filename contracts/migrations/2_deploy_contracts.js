const OmniverseProtocolHelper = artifacts.require("OmniverseProtocolHelper");
const SkywalkerFungible = artifacts.require("SkywalkerFungible");
const SkywalkerNonFungible = artifacts.require("SkywalkerNonFungible");
const fs = require("fs");

const CHAIN_IDS = {"CHAIN1":{"tokenInfo":[{"name":"SKYWALKER","symbol":"SKYWALKER"}],"omniverseChainId":1,"contractType":"ft"},"CHAIN2":{"tokenInfo":[{"name":"SKYWALKER","symbol":"SKYWALKER"}],"omniverseChainId":2,"contractType":"ft"}};

module.exports = async function (deployer, network) {
  const contractAddressFile = './config/default.json';
  let data = fs.readFileSync(contractAddressFile, 'utf8');
  let jsonData = JSON.parse(data);
  if (!jsonData[network]) {
    console.error('There is no config for: ', network, ', please add.');
    return;
  }

  await deployer.deploy(OmniverseProtocolHelper);
  let chain = CHAIN_IDS[network];
  if (chain.contractType == 'ft') {
    await deployer.link(OmniverseProtocolHelper, SkywalkerFungible);
    for (let tokenInfo of chain.tokenInfo) {
      await deployer.deploy(SkywalkerFungible, chain.omniverseChainId, tokenInfo.name, tokenInfo.symbol);
      let address = jsonData[network].skywalkerFungibleAddress;
      address = address ? address : {};
      address[tokenInfo.name] = SkywalkerFungible.address;
      jsonData[network].skywalkerFungibleAddress = address;
    }
  } else {
    await deployer.link(OmniverseProtocolHelper, SkywalkerNonFungible);;
    for (let tokenInfo of chain.tokenInfo) {
      await deployer.deploy(SkywalkerNonFungible, chain.omniverseChainId, tokenInfo.name, tokenInfo.symbol)
      let address = jsonData[network].skywalkerNonFungibleAddress;
      address = address ? address : {};
      address[tokenInfo.name] = SkywalkerNonFungible.address;
      jsonData[network].skywalkerNonFungibleAddress = address;
    }
  }
  fs.writeFileSync(contractAddressFile, JSON.stringify(jsonData, null, '\t'));
};
