const { ethers, upgrades } = require('hardhat');
const assert = require('assert');

let marketPlaceV1;
let testERC1155;
let DAItoken;
let LINKtoken;

before(async () => {
  // Creating the marketPlace for global testing:
  const [owner, addr1] = await ethers.getSigners();

  const MarketPlaceV1 = await ethers.getContractFactory('MarketPlaceV1');
  marketPlaceV1 = await upgrades.deployProxy(
    MarketPlaceV1,
    [await owner.getAddress()],
    { initializer: 'initialize' }
  );
  await marketPlaceV1.deployed();

  // Creating the testERC1155 token:
  const TestERC1155 = await ethers.getContractFactory('TestERC1155');
  testERC1155 = await TestERC1155.connect(addr1).deploy();
  await testERC1155.deployed();

  // Approving first the MarketPlaceV1 in the ERC1155 manipulate the tokens.
  await testERC1155
    .connect(addr1)
    .setApprovalForAll(marketPlaceV1.address, true);

  // Aprove the market to spend out tokens.
  const DAI = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
  const LINK = '0x514910771AF9Ca656af840dff83E8264EcF986CA';

  // DAI TOKEN
  const DAIToken = await ethers.getContractAt('IERC20', DAI);
  DAItoken = await DAIToken.deployed();

  // LINK TOKEN
  const LINKToken = await ethers.getContractAt('IERC20', LINK);
  LINKtoken = await LINKToken.deployed();
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

  it('assert the marketPlaceV1 address', async () => {
    assert.ok(marketPlaceV1.address);
  });

  it('creating a sell in the ERC1155 contract for ETH', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const result = await marketPlaceV1
      .connect(addr1)
      .createSell(testERC1155.address, 1, 4500, 4000, 5 * 10 ** 2);

    assert(result);
  });

  it('showing the sell created in the Market with the index 0', async () => {
    const result = await marketPlaceV1.sales(0);
    console.log('Information of the sale 0:');
    for (const res of result) {
      console.log(res.toString());
    }
    assert.ok(result);
  });

  it('buys the token at the current price of the oracle in ETH', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();

    /*
      We make the buy with the addr1 and after that
      in the next test, we check the balance of the
      owner of the sell.
    */
    await marketPlaceV1.buyToken(2, 0, 0, {
      value: await ethers.utils.parseEther('1'),
    });
  });

  it('creating a sell in the ERC1155 contract for DAI token', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const result = await marketPlaceV1
      .connect(addr1)
      .createSell(testERC1155.address, 1, 4500, 4000, 5 * 10 ** 2);

    assert(result);
  });

  it('showing the sell created in the Market with the index 1', async () => {
    const result = await marketPlaceV1.sales(1);
    console.log('Information of the sale 1:');
    for (const res of result) {
      console.log(res.toString());
    }
    assert.ok(result);
  });

  it('token buyed in the ERC1155 need to dropdown the amount', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const balance = await testERC1155.balanceOf(addr1.address, 1);
    assert.strictEqual(balance.toString(), '999999999999999999999995500');
  });

  it('token buyed in the ERC1155 with DAI Tokens', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();

    await DAItoken.approve(
      marketPlaceV1.address,
      ethers.utils.parseUnits('30', 18)
    );
    /*
      We make the buy with the addr1 and after that
      in the next test, we check the balance of the
      owner of the sell.
    */
    await marketPlaceV1.buyToken(0, 1, ethers.utils.parseUnits('30', 18));
  });

  it('see the balance of the owner in the DAI Token', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();

    /*
      We make the buy with the addr1 and after that
      in the next test, we check the balance of the
      owner of the sell.
    */

    const result = await DAItoken.balanceOf(owner.address);
    console.log('BALANCE OF OWNER DAI: ', (result / 1e18).toString());
  });

  it('creating a sell in the ERC1155 contract for LINK token', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const result = await marketPlaceV1
      .connect(addr1)
      .createSell(testERC1155.address, 1, 4500, 4000, 60 * 10 ** 2);

    assert(result);
  });

  it('showing the sell created in the Market with the index 2', async () => {
    const result = await marketPlaceV1.sales(2);
    console.log('Information of the sale 2:');
    for (const res of result) {
      console.log(res.toString());
    }
    assert.ok(result);
  });

  it('token buyed in the ERC1155 with LINK Tokens', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();

    await LINKtoken.approve(
      marketPlaceV1.address,
      ethers.utils.parseUnits('20', 18)
    );
    /*
      We make the buy with the addr1 and after that
      in the next test, we check the balance of the
      owner of the sell.
    */
    await marketPlaceV1.buyToken(1, 2, ethers.utils.parseUnits('20', 18));
  });

  it('see the balance of the owner in the LINK Tokens', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();

    /*
      We make the buy with the addr1 and after that
      in the next test, we check the balance of the
      owner of the sell.
    */

    const result = await LINKtoken.balanceOf(owner.address);
    console.log('BALANCE OF OWNER LINK:', (result / 1e18).toString());
  });

  it('try to buy a token that has already been purchased', async () => {
    const [owner, addr1, addr2] = await ethers.getSigners();

    await DAItoken.approve(
      marketPlaceV1.address,
      ethers.utils.parseUnits('30', 18)
    );

    /* 
      This test should fail, because he can't buy a token that has been
      already purchased.
    */

    try {
      /*
        We make the buy with the addr1 and after that
        in the next test, we check the balance of the
        owner of the sell.
      */
      await marketPlaceV1.buyToken(0, 1, ethers.utils.parseUnits('30', 18));
      assert(false);
    } catch (error) {
      assert(error);
    }
  });
});
