//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SwapperV1 is Initializable {
  address private constant UniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private admin;
  using SafeMath for uint;
  
  function initialize(address _admin) public initializer {
    admin = _admin;
  }

  function swapEthForTokens(address[] memory _tokens, uint256[] memory _porcents) external payable {
    /*
      The value in wei, needs to be greater than 1.
    */
    require(msg.value >= 1, "Need to be greater then one");

    /*
      This is the calculation of the %, already knowing that
      the porcent needs to be between 1 and 1000, because we can't
      handle decimals, so we pass the value %95.5 as 955 then divide that
      for 1000 and get 0.955.
    */

    for (uint i = 0; i < _tokens.length; i++) {
      require(_porcents[i] >= 1 && _porcents[i] <= 1000, "Something between 1 and 1000");

      address[] memory _path = new address[](2);

      _path[0] = IUniswapV2Router02(UniswapRouter).WETH();
      _path[1] = address(_tokens[i]);

      IUniswapV2Router02(UniswapRouter).swapExactETHForTokens{value: msg.value.mul(_porcents[i]).div(1000)}
      (1, _path, msg.sender, block.timestamp + 3600);
    }
  }

  function printVersion() external pure returns(string memory) {
    return "Hello, this is the version upgradeable of SwapperV1";
  }
}
