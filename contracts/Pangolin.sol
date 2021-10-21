// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import './lib/Operator.sol';
import './lib/ERC20.sol';
import './lib/IERC20.sol';

contract Pangolin is ERC20, Operator {
    
    uint256 public _transfered;
    uint256 public _maxTransfer = 2100000 * 1e18;


    constructor() public ERC20('Pangolin', 'Pangolin') {
        _mint(msg.sender, 1 * 10**18);
        _mint(address(this), 21 * 1e5 * 1e18);
    }

    function transferOut(address to,uint256 amount) external onlyOperator {
        uint256 transfered = _transfered.add(amount);
        (bool flag,uint256 exceed) = transfered.trySub(_maxTransfer);
        if(flag){
            transfered = _maxTransfer;
            amount = amount.sub(exceed);
        }
        IERC20(address(this)).transfer(to, amount);
        _transfered = transfered;
    }

}
