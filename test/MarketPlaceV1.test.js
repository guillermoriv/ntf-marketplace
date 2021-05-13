const { ethers, upgrades } = require('hardhat');
const assert = require('assert');

let marketPlaceV1;

before(async () => {
  const MarketPlaceV1 = await ethers.getContractFactory('MarketPlaceV1');
  marketPlaceV1 = await upgrades.deployProxy(
    MarketPlaceV1,
    ['0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'],
    { initializer: 'initialize' }
  );
  await marketPlaceV1.deployed();
});

describe('Testing the NFT MarketPlaceV1', () => {
  it('deployed correctly without error', async () => {});

  it('print the address of the marketPlace', async () => {
    assert.ok(marketPlaceV1.address);
  });
});
