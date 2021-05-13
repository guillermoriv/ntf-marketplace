const { ethers, upgrades } = require('hardhat');
const assert = require('assert');

let marketPlaceV1;
let testERC1155;

before(async () => {
  // Creating the marketPlace:
  const MarketPlaceV1 = await ethers.getContractFactory('MarketPlaceV1');
  marketPlaceV1 = await upgrades.deployProxy(
    MarketPlaceV1,
    ['0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'],
    { initializer: 'initialize' }
  );
  await marketPlaceV1.deployed();

  // Creating the testERC1155 token:
  const TestERC1155 = await ethers.getContractFactory('TestERC1155');
  testERC1155 = await TestERC1155.deploy();
  await testERC1155.deployed();
});

describe('Testing the NFT MarketPlaceV1', () => {
  it('deployed correctly without error', async () => {});

  it('print the address of the marketPlace', async () => {
    assert.ok(marketPlaceV1.address);
  });

  it('created an ERC1155 contract and try to create a sell', async () => {
    const result = await marketPlaceV1.createSell(
      testERC1155.address,
      1,
      150,
      4000,
      45
    );

    assert(result);
  });

  it('showing the sell created by the ERC1155 token', async () => {
    const result = await marketPlaceV1.sales(0);

    for (const res of result) {
      console.log(res.toString());
    }
  });
});
