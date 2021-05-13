//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/** 
  @title A NFTMarketPlace what can be upgradeable by implementations.
  @author @Guillermo Rivas.
  @notice You can use this contract for the basic implementations.
**/

contract MarketPlaceV1 is Initializable {

  /// @notice This is the Sell struct, the basic structs contain the owner of the selling tokens.
  struct Sell {
    address seller;
    address token;
    string tokenId;
    uint256 amountOfToken;
    uint256 deadline;
    uint256 price;
    bool isSold;
  }

  address private admin;
  address private recipient;
  uint private fee;
  Sell[] public sellers;

  /// @param _recipient This is the recipient for the fees that are charged;
  /// @notice this function is going to initialize the admin and the fee.
  /// @notice the fee is going to be initialize as 10, so when is divided by 1000, gives 0.01.
  function initialize(address _recipient) public initializer {
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
}