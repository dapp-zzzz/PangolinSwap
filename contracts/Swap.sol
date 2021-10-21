// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './lib/IERC20.sol';
import './lib/SafeMath.sol';
import './lib/SafeERC20.sol';

contract Swap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public _token1 = IERC20(0x55d398326f99059fF775485246999027B3197955); //USDT
    IERC20 public _token2 = IERC20(0x47fA20ba81333BA507d687913bAF7c89432182A1); //BZZONE
    IERC20 public _rewardToken = IERC20(0x29FB05f65eeFb9553070614b3B42bC8b288fbC2f); //WNFT
    address public _team = 0x309E1cBaeAE3269BeBC8774852676b2E7B90086B;
    uint256 public sold;
    
    constructor() public {}
    
    function swap(uint256 amount) public {
        _token1.safeTransferFrom(msg.sender, _team, amount.mul(1000*1e18));
        _token2.safeTransferFrom(msg.sender, _team, amount.mul(20*1e18));
        amount = amount.mul(3*1e18).div(2);
        _rewardToken.safeTransfer(msg.sender, amount);
        sold = sold.add(amount);
    }
}