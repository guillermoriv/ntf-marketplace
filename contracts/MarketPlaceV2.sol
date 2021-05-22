//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/** 
  @title A NFTMarketPlace what can be upgradeable by implementations.
  @author @Guillermo Rivas.
  @notice You can use this contract for the basic implementations.
**/

contract MarketPlaceV2 is Initializable {

  /** 
    @dev Storage variables, not modified in V2.
  **/
  address private admin;
  address private recipient;
  uint256 private fee;
  mapping(uint => Sell) public sales;
  uint256 public salesId;
  using SafeMath for uint256; 

  /** 
    @notice All of the Price Feeds for the Aggregator are down here.
    @dev PriceFeeds below.
  **/
  address private constant DAIUSD = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
  address private constant LINKUSD = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;
  address private constant ETHUSD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

  /** 
    @dev Address of the ERC20 tokens what people can pay with.
  **/
  address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
  address private constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
  address private constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

  /** 
    @notice All of the Price Feeds for the Aggregator are down here.
    @dev PriceFeeds below added for the version two of the marketplace.
  **/
  address private constant UNIUSD = 0x553303d460EE0afB37EdFf9bE42922D8FF63220e;
  address private constant AAVEUSD = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;


  /// @notice This is the Sell struct, the basic structs contain the owner of the selling tokens.
  struct Sell {
    address seller;
    address token;
    uint256 tokenId;
    uint256 amountOfToken;
    uint256 deadline;
    uint256 price;
    bool isSold;
  }

  /// @notice This is the emitted event, when a offer for a certain amount of tokens.
  event SellEvent (
    address _seller,
    address _token,
    uint256 _offerId,
    uint256 _tokenId,
    uint256 _amount
  );

  /// @notice This is the emitted event, when a sell is canceled.
  event CanceledSell (
    address _seller,
    address _token,
    uint256 _tokenId,
    uint256 _amountOfToken
  );

  /// @notice This is the emitted event, when a buy is made.
  event BuyEvent (
    address _buyer,
    address _token,
    uint256 _tokenId,
    uint256 _amountOfToken,
    uint256 _price
  );

  /** 
    @notice This are the enums for the price feeds that what we are working.
    @dev It's going to be passed as a parameter.
  **/
  enum PriceFeed {
    DAI,
    LINK,
    ETH,
    UNI,
    AAVE
  }

  /// @param _recipient This is the recipient for the fees that are charged;
  /// @notice this function is going to initialize the admin, the fee and the recipient.
  /// @dev the fee is going to be initialize as 10, so when is divided by 1000, gives 0.01.
  function initialize(address _recipient) public initializer {
    require(_recipient != address(0));
    admin = msg.sender;
    recipient = _recipient;
    fee = 1; 
  }

  /** 
    @notice Modifier for admin, what does is onlyAdmin can execute a funcionality 
    of the functions, if it has this modifier.
  **/
  modifier onlyAdmin() {
    require(msg.sender == admin, "MarketPlaceV1: You need to be the admin of this contract.");
    _;
  }

  /** 
    @param _recipient This is the updated recipient of the fees.
    @param _fee This is the updated fee for the recipient to receive.
  **/
  function updateFeeAndRecipient(address _recipient, uint256 _fee) external onlyAdmin() {
    recipient = _recipient;
    fee = _fee;
  }

  /** 
    @notice Internal function to check the prices in the oracle.
    @dev You need to pass the enum as the parameter.
    @param _priceFeed Is the price feed that we are going to check in the oracle.
    @dev I am dividing by 1e8, because I want to have the price in USD with decimals.
  **/
  function _getPriceFeed(PriceFeed _priceFeed) internal view returns (uint256 resultPrice){
    /*
      We are going to check for the differents price feeds
      in out contract and get the price of that feed.
    */
    if (_priceFeed == PriceFeed.DAI) {
      (,int price,,,) = AggregatorV3Interface(DAIUSD).latestRoundData();
      resultPrice = uint256(price).div(1e8);
    }

    if (_priceFeed == PriceFeed.LINK) {
      (,int price,,,) = AggregatorV3Interface(LINKUSD).latestRoundData();
      resultPrice = uint256(price).div(1e8);
    }

    if (_priceFeed == PriceFeed.ETH) {
      (,int price,,,) = AggregatorV3Interface(ETHUSD).latestRoundData();
      resultPrice = uint256(price).div(1e8);
    }

    if (_priceFeed == PriceFeed.AAVE) {
      (,int price,,,) = AggregatorV3Interface(AAVEUSD).latestRoundData();
      resultPrice = uint256(price).div(1e8);
    }

    if (_priceFeed == PriceFeed.UNI) {
      (,int price,,,) = AggregatorV3Interface(UNIUSD).latestRoundData();
      resultPrice = uint256(price).div(1e8);
    }
  }

  /** 
    @param _token This is the address of the ERC1155 token.
    @param _id This is the ID of the token that's inside of the ERC1155 token.
    @param _amountOfToken This is the amount of tokens that are going to be selled in the offer.
    @param _deadline This is the final date in (seconds) so the offer ends.
    @param _price This is the full price for the amountOfToken that user passed as the param.
    @dev We are making some require for the parameters that needs to be required.
    @return Return true if the sell is created successfully.
  **/

  function createSell(
      address _token, 
      uint256 _id, 
      uint256 _amountOfToken, 
      uint256 _deadline, 
      uint256 _price
    ) 
      external
      returns (bool)
    {
    
    require(_amountOfToken > 0, "The amount of tokens to sell, needs to be greater than 0");
    require(_price > 0, "The full price for the tokens need to be greater than 0");
    require(_deadline > 3600, "The deadline needs to be greater than 1 hour");

    sales[salesId] = Sell(
      msg.sender,
      _token,
      _id,
      _amountOfToken,
      block.timestamp + _deadline,
      _price,
      false
    );

    salesId++;

    emit SellEvent(
      msg.sender,
      _token,
      salesId,
      _id,
      _amountOfToken
    );

    return true;
  }

  /** 
    @notice This is the function for buy the token's from the market.
    @param _paymentMethod Is the payment method that the user wants to use for pay the tokens.
    @param _sellId Is the sell (tokens) that the user wants to buy.
    @param _amountTokensIn Is the amount of tokens that the user is passing (if is paying with tokens).
  **/
  function buyToken(PriceFeed _paymentMethod, uint256 _sellId, uint256 _amountTokensIn) external payable {
    require(msg.sender != address(0), "buyToken: Needs to be a address.");
    require(sales[_sellId].isSold != true, "buyToken: The tokends were bought.");

    /*
      We only call this require, if we know the user is passing , 
      ethereum and not a token to pay for the tokens.
    */
    if (_paymentMethod == PriceFeed.DAI || _paymentMethod == PriceFeed.LINK) {
      require(_amountTokensIn.div(1e18).mul(_getPriceFeed(_paymentMethod)) >= sales[_sellId].price.div(100), "buyToken: The amount of token sended need to be grater or equal to the price.");

      /*  
        We need to aprove this Market to spend ours DAI, LINK tokens.
      */

      if (_paymentMethod == PriceFeed.DAI) {
        /*
          We make the transfer from the msg.sender to the seller of
          the current sell that we ask about in the parameter.
        */

        IERC20(DAI).transferFrom(msg.sender, sales[_sellId].seller, sales[_sellId].price.div(100).div(_getPriceFeed(_paymentMethod)).mul(1e18));
     
        /*
          After we pass the tokens to the seller, now we pass
          the tokens to the fees to the recipient.
        */

        IERC20(DAI).transferFrom(msg.sender, recipient, sales[_sellId].price.div(100).mul(fee.div(100)).div(_getPriceFeed(_paymentMethod)).mul(1e18));

        /*
          After we send the tokens DAI to the seller, we send
          the tokens that the user buy to the user.
        */

        IERC1155(sales[_sellId].token).safeTransferFrom(
          sales[_sellId].seller, 
          msg.sender, 
          sales[_sellId].tokenId, 
          sales[_sellId].amountOfToken, 
          "0x0"
        );

        /* 
          After all we set the isSold to true for this sale.
        */

        sales[_sellId].isSold = true;
      }

      if (_paymentMethod == PriceFeed.LINK) {
        /*
          We make the transfer from the msg.sender to the seller of
          the current sell that we ask about in the parameter.
        */

        IERC20(LINK).transferFrom(msg.sender, sales[_sellId].seller, sales[_sellId].price.div(100).div(_getPriceFeed(_paymentMethod)).mul(1e18));
     
        /*
          After we pass the tokens to the seller, now we pass
          the tokens to the fees to the recipient.
        */

        IERC20(DAI).transferFrom(msg.sender, recipient, sales[_sellId].price.div(100).mul(fee.div(100)).div(_getPriceFeed(_paymentMethod)).mul(1e18));
        
        /*
          After we send the tokens LINK to the seller, we send
          the tokens that the user buy to the user.
        */

        IERC1155(sales[_sellId].token).safeTransferFrom(
          sales[_sellId].seller, 
          msg.sender, 
          sales[_sellId].tokenId, 
          sales[_sellId].amountOfToken, 
          "0x0"
        );

        /* 
          After all we set the isSold to true for this sale.
        */

        sales[_sellId].isSold = true;
      }
    }

    if (_amountTokensIn == 0 && _paymentMethod == PriceFeed.ETH) {
      require(msg.value >= sales[_sellId].price.div(100).div(_getPriceFeed(_paymentMethod)), "buyToken: Needs to be greater or equal to the price.");
      /*
        We send the ETH sended in the function, for the price
        in USD of the sell.
      */
      payable(address(sales[_sellId].seller)).transfer(sales[_sellId].price.div(100).div(_getPriceFeed(_paymentMethod)));
      
      /*
        We send the fee to the recepient and
        make the transfer.
      */

      payable(address(recipient)).transfer(sales[_sellId].price.div(100).mul(fee.div(100)).div(_getPriceFeed(_paymentMethod)));
      
      /* After that, we send back the left ETH in msg.value. */

      payable(address(msg.sender)).transfer(msg.value - sales[_sellId].price.div(100).div(_getPriceFeed(_paymentMethod)));
      
      /* 
        After we send the ETH to the user, we send
        the amountOfToken to the msg.sender.
      */
      IERC1155(sales[_sellId].token).safeTransferFrom(
        sales[_sellId].seller, 
        msg.sender, 
        sales[_sellId].tokenId, 
        sales[_sellId].amountOfToken, 
        "0x0"
      );

      /* 
        After all we set the isSold to true for this sale.
      */

      sales[_sellId].isSold = true;
    }

    /* 
      Emit the buy event when the is closed.
    */

    emit BuyEvent (
      msg.sender,
      sales[_sellId].token, 
      sales[_sellId].tokenId,
      sales[_sellId].amountOfToken,
      sales[_sellId].price
    );
  }


  /** 
    @param _idSell The ID of the sell that you want to cancel.
  **/
  function cancelSell(uint256 _idSell) external returns(bool){
    /*
      We need to check if the msg.sender is really the owner
      of this sell, and if is not sold yet.
    */
    require(sales[_idSell].seller == msg.sender, "Cancel: to cancel you need to be the owner of the sell.");
    require(sales[_idSell].isSold != true, "Cancel: sorry this is already sold.");

    /*
      After that checking we can safely delete the sell
      in our marketplace.
    */
    delete sales[_idSell];

    /*
      Emit the event when a sell is cancel.
    */
    emit CanceledSell(
      sales[_idSell].seller, 
      sales[_idSell].token, 
      sales[_idSell].tokenId,
      sales[_idSell].amountOfToken
    );

    return true;
  }
}