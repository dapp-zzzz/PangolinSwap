// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './lib/IERC20.sol';
import './lib/SafeMath.sol';
import './lib/SafeERC20.sol';
import './lib/Ownable.sol';

contract SwapV2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    //BSC
    IERC20 public _token = IERC20(0x55d398326f99059fF775485246999027B3197955); //USDT
    IERC20 public _rewardToken = IERC20(0x29FB05f65eeFb9553070614b3B42bC8b288fbC2f); //WNFT
    IERC20 public _rewardToken2 = IERC20(0x656A148B0fE9A8041850491ECc16a0F54061C761); //WNFT
    
    address public _team = 0xd60A8B180bE02af91AcD2f4525951552E89eEB79;
    mapping(address => bool) public node;
    uint256 public sold;
    
    constructor() public {}
    
    function setNode(address[] memory accounts, bool flag) public onlyOwner{
        for(uint256 i=0;i<accounts.length;i++){
            node[accounts[i]] = flag;
        }
    }

    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        IERC20 token = IERC20(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner(), amount);
    }
    
    function swap(uint256 amount) public {
        if(!node[msg.sender]){
            _token.safeTransferFrom(msg.sender, _team, amount.mul(1500*1e18));
        }else{
            _token.safeTransferFrom(msg.sender, _team, amount.mul(1350*1e18));
            _token.safeTransferFrom(msg.sender, msg.sender, amount.mul(150*1e18));
        }
        amount = amount.mul(1e18);
        _rewardToken.safeTransfer(msg.sender, amount);
        _rewardToken2.safeTransfer(msg.sender, amount);
        sold = sold.add(amount);
    }
}