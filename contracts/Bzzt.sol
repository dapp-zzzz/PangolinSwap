// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./lib/ERC20Burnable.sol";
import "./lib/SafeERC20.sol";
import "./lib/Operator.sol";
import "./lib/IDistributor.sol";
import "./lib/IPangolin.sol";

contract Bzzt is ERC20Burnable, Operator {
    using SafeERC20 for IERC20;

    bool public once = true;

    IERC20 Pangolin;

    uint256 public BzztPrice = 5 * 1e18;

    uint256 public pre = 0;

    uint256 private cAmount = 100000 * 1e18;

    address public distribute;

    /**
     * @notice Constructs the Basis Cash ERC-20 contract.
     */
    constructor(IERC20 Pangolin_) public ERC20("Bzzt", "Bzzt") {
        Pangolin = Pangolin_;
        _mint(msg.sender, 1e18);
        _mint(address(this), cAmount);
    }

    function setBzztPrice(uint256 _BzztPrice) external onlyOperator {
        BzztPrice = _BzztPrice;
    }

    function swap(uint256 amount) external {
        uint256 value = amount.mul(1e18).div(BzztPrice);
        uint256 balanceBefore = balanceOf(address(this));
        if (value > balanceBefore) {
            amount = amount.sub(
                value.sub(balanceBefore).mul(BzztPrice).div(1e18)
            );
            value = balanceBefore;
        }
        // 0x000000000000000000000000000000000000dEaD
        Pangolin.safeTransferFrom(
            msg.sender,
            0x86436a7E22B685959429C5D80ea3D823B33F58a9,
            amount
        );
        IERC20(address(this)).safeTransfer(msg.sender, value);
        uint256 balanceAfter = balanceOf(address(this));
        require(balanceAfter < balanceBefore, "swap failed");
    }

    function setDistributor(address distribute_) external onlyOperator {
        distribute = distribute_;
    }

    /**
     * @notice Operator mints basis cash to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of basis cash to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_)
        public
        onlyOperator
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
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
