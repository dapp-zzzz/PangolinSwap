// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
//import "./IANTS.sol"; //邀请关系

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    //ANTS  Pangolin  
    IERC20 public lpt;
    //ADC  bzzt  
    IERC20 public lpt2;
     //bzz1   
    IERC20 public lpt3;


    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lpt.safeTransferFrom(msg.sender, address(this), amount);
    }

     function stake2(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
         lpt.safeTransferFrom(msg.sender, address(this), amount);
         lpt2.safeTransferFrom(msg.sender, address(this), amount);
     }

       function stake3(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
         lpt.safeTransferFrom(msg.sender, address(this), amount);
         lpt2.safeTransferFrom(msg.sender, address(this), amount.mul(10));
          lpt3.safeTransferFrom(msg.sender, address(this),  amount.mul(10));
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lpt.safeTransfer(msg.sender, amount);
    }
    function withdraw2(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lpt.safeTransfer(msg.sender, amount);
         lpt2.safeTransfer(msg.sender, amount);
    }

     function withdraw3(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lpt.safeTransfer(msg.sender, amount);
         lpt2.safeTransfer(msg.sender,  amount.mul(10));
           lpt3.safeTransfer(msg.sender,  amount.mul(10));
    }
}
