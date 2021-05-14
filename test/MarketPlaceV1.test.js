const { ethers, upgrades } = require('hardhat');
const assert = require('assert');

let marketPlaceV1;
let testERC1155;

before(async () => {
  // Creating the marketPlace for global testing:
  const [owner] = await ethers.getSigners();

  const MarketPlaceV1 = await ethers.getContractFactory('MarketPlaceV1');
  marketPlaceV1 = await upgrades.deployProxy(
    MarketPlaceV1,
    [await owner.getAddress()],
    { initializer: 'initialize' }
  );
  await marketPlaceV1.deployed();

  // Creating the testERC1155 token:
  const TestERC1155 = await ethers.getContractFactory('TestERC1155');
  testERC1155 = await TestERC1155.deploy();
  await testERC1155.deployed();
});

describe('Testing the NFT MarketPlaceV1', () => {
  it('deploy a new contract correctly without error', async () => {
    // Creating a marketplace just for the porpuse of testing.
    const MarketPlaceTest = await ethers.getContractFactory('MarketPlaceV1');
    const marketPlaceTest = await upgrades.deployProxy(
      MarketPlaceTest,
      ['0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'],
      { initializer: 'initialize' }
    );
    await marketPlaceTest.deployed();

    assert(marketPlaceTest.address);
  });

  it('print the address of the marketPlace', async () => {
    assert.ok(marketPlaceV1.address);
  });

  it('created an ERC1155 contract and try to create a sell', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const result = await marketPlaceV1.createSell(
      testERC1155.address,
      1,
      4500,
      4000,
      4.5 * 10 ** 2
    );

    assert(result);
  });

  it('can be upgradeable to a second implementation', async () => {
    //@TODO need to make a implementation V2 of this contract.
  });

  it('showing the sell created by the ERC1155 token', async () => {
    const result = await marketPlaceV1.sales(0);

    console.log(result);
  });

  it('buys the token at the current price of the oracle in ETH', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();

    // Approving first the MarketPlaceV1 in the ERC1155 manipulate the tokens.
    await testERC1155.setApprovalForAll(marketPlaceV1.address, true);
    /* 
      After approving we can make the call to buy a token from the MarketPlace
      on this ERC1155 contract.
    */

    /*
      We make the buy with the addr1 and after that
      in the next test, we check the balance of the
      owner of the sell.
    */
    await marketPlaceV1.connect(addr1).buyToken(2, 0, 0, {
      value: await ethers.utils.parseEther('1'),
    });
  });

  it('token buyed in the ERC1155 need to dropdown the amount', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const balance = await testERC1155.balanceOf(owner.address, 1);
    assert.strictEqual(balance.toString(), '999999999999999999999995500');
  });
});
