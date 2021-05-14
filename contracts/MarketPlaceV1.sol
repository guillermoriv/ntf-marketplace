//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/** 
  @title A NFTMarketPlace what can be upgradeable by implementations.
  @author @Guillermo Rivas.
  @notice You can use this contract for the basic implementations.
**/

contract MarketPlaceV1 is Initializable {

  /** 
    @notice All of the Price Feeds for the Aggregator are down here.
  **/
  address private constant DAIUSD = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
  address private constant LINKUSD = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;
  address private constant ETHUSD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
  address private admin;
  address private recipient;
  uint private fee;
  mapping(uint => Sell) public sales;
  uint public salesId;

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

  /** 
    @notice This are the enums for the price feeds that what we are working.
    @dev It's going to be passed as a parameter.
  **/
  enum PriceFeed {
    DAI,
    LINK,
    ETH
  }

  /// @param _recipient This is the recipient for the fees that are charged;
  /// @notice this function is going to initialize the admin, the fee and the recipient.
  /// @dev the fee is going to be initialize as 10, so when is divided by 1000, gives 0.01.
  function initialize(address _recipient) public initializer {
    require(_recipient != address(0));
    admin = msg.sender;
    recipient = _recipient;
    fee = 10; 
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
  function updateFeeAndRecipient(address _recipient, uint _fee) external onlyAdmin() {
    recipient = _recipient;
    fee = _fee;
  }

  /** 
    @notice Internal function to check the prices in the oracle.
    @dev You need to pass the enum as the parameter.
    @param _priceFeed Is the price feed that we are going to check in the oracle.
  **/
  function _getPriceFeed(PriceFeed _priceFeed) internal view returns (int resultPrice){
    /*
      We are going to check for the differents price feeds
      in out contract and get the price of that feed.
    */
    if (_priceFeed == PriceFeed.DAI) {
      (,int price,,,) = AggregatorV3Interface(DAIUSD).latestRoundData();
      resultPrice = price;
    }

    if (_priceFeed == PriceFeed.LINK) {
      (,int price,,,) = AggregatorV3Interface(LINKUSD).latestRoundData();
      resultPrice = price;
    }

    if (_priceFeed == PriceFeed.ETH) {
      (,int price,,,) = AggregatorV3Interface(ETHUSD).latestRoundData();
      resultPrice = price;
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

  
  function buyToken() external view returns (int) {
    return _getPriceFeed(PriceFeed.LINK);
  }


  /** 
    @param _idSell The ID of the sell that you want to cancel.
  **/
  function cancelSell(uint _idSell) external {
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
  }
}