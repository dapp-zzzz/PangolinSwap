// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './lib/Operator.sol';
import './lib/ERC20Burnable.sol';

contract Bzzone is ERC20Burnable, Operator {  
    constructor() public ERC20('Bzzone', 'Bzzone') {
        _mint(msg.sender, 1 * 10**18);
        _mint(address(this), 1127 * 1e3 * 1e18);
    }

    uint256 public _transfered;
    uint256 public _maxTransfer = 1127000 * 1e18;


   
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

    function burn(uint256 amount) public override onlyOperator {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOperator
    {
        super.burnFrom(account, amount);
    }
}
