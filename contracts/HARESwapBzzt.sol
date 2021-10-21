// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import './lib/Operator.sol';
import "./lib/IERC20.sol";
import "./lib/SafeMath.sol";

contract HARESwapBzzt is  Operator {
    using SafeMath for uint256;
    uint256 public Price = 15 * 10**15;

    IERC20 public Bzzt;

    IERC20 public HARE;

    //
    constructor() public {
        Bzzt = IERC20(0x1A29770F8Db6366cf2011Cb2c412d9bbCD86Cc4f);
        HARE = IERC20(0x4AFc8c2Be6a0783ea16E16066fde140d15979296);
      
    }

      function setPrice(uint256 _Price) external onlyOperator {
        Price=_Price ;
    }


    function swap(uint256 amount) external {
        //10**8 *2

        uint256 value = amount.div(Price);
        uint256 balanceBefore = Bzzt.balanceOf(address(this));
        if (value > balanceBefore) {
            amount = amount.sub(value.sub(balanceBefore).mul(Price));
            value = balanceBefore;
        }
        // 0x000000000000000000000000000000000000dEaD
        HARE.transferFrom(
            msg.sender,
            0x1faB053175f501c7C4c6EC66CD3B9dC64e4654E5,
            amount
        );

        Bzzt.transfer(msg.sender, value);
        uint256 balanceAfter = Bzzt.balanceOf(address(this));
        require(balanceAfter < balanceBefore, "swap failed");
    }
}
