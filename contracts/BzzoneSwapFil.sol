// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import './lib/Operator.sol';
import "./lib/IERC20.sol";
import "./lib/SafeMath.sol";


contract BzzoneSwapFil is  Operator {
      using SafeMath for uint;
      uint256 public Price = 3 * 1e18;
   

       IERC20 public Bzzone ;
       IERC20 public FIL;
      //
      constructor () public{
          Bzzone = IERC20(0x47fA20ba81333BA507d687913bAF7c89432182A1);
         FIL = IERC20(0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153);
        
      }
    
    function setPrice(uint256 _Price) external onlyOperator {
        Price=_Price ;
    }


     function swap(uint256 amount) external {      //1
        //10**8 *2 
         uint256 value = amount.mul(Price).div(10 * 1e18);     //0.3
         uint256 balanceBefore = FIL.balanceOf(address(this));//0
         if(value > balanceBefore) {
             amount = amount.sub(value.sub(balanceBefore).mul(Price));//1-(0.3-0*3)
             value = balanceBefore;
         }
         //0xdC1853d780e4908c49fEc929B41cEF5E5aa537Bc
         Bzzone.transferFrom(msg.sender,0xaad18ae63DCC078747A78b787AE4dcCa55D370fc , amount);
         FIL.transfer(msg.sender, value);
         uint256 balanceAfter =FIL.balanceOf(address(this));
         require(balanceAfter < balanceBefore, "Swap failed");     
     }
     

}

