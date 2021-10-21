// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './lib/SafeMath.sol';
import './lib/IERC20.sol';
import './lib/SafeERC20.sol';
import './lib/IOracle.sol';
import './lib/IBoardroom.sol';
import './lib/IBasisAsset.sol';
import './lib/ISimpleERCFund.sol';
import './lib/Babylonian.sol';
import './lib/FixedPoint.sol';
import './lib/Safe112.sol';
import './lib/Operator.sol';
import './lib/Epoch.sol';
import './lib/ContractGuard.sol';

/**
 * @title Basis Cash Treasury contract
 * @notice Monetary policy logic to adjust supplies of basis cash assets
 * @author Summer Smith & Rick Sanchez
 */
contract Treasury is ContractGuard, Epoch {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Safe112 for uint112;

    /* ========== STATE VARIABLES ========== */

    // ========== FLAGS
    bool public migrated = false;
    bool public initialized = false;

    // ========== CORE
    address public fund;
    address public bzzt;
    address public bzzb;
    address public bzz1;
    address public pangolin;
    address public boardroom;

    address public bondOracle;
    address public seigniorageOracle;

    // ========== PARAMS
    uint256 public cashPriceOne;
    uint256 public cashPriceCeiling;
    uint256 public cashPriceBurn;
    uint256 public bondDepletionFloor;
    uint256 private accumulatedSeigniorage = 0;
    uint256 public fundAllocationRate = 2; // %

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _cash,
        address _bond,
        address _share,
        address _ants,
        address _bondOracle,
        address _seigniorageOracle,
        address _boardroom,
        address _fund,
        uint256 _startTime //1 days 1 minutes
    ) public Epoch(1 days, _startTime, 0) {
        bzzt = _cash;
        bzzb = _bond;
        bzz1 = _share;
        pangolin = _ants;
        bondOracle = _bondOracle;
        seigniorageOracle = _seigniorageOracle;

        boardroom = _boardroom;
        fund = _fund;

        cashPriceOne = 10**18;
        cashPriceCeiling = uint256(105).mul(cashPriceOne).div(10**2);
        cashPriceBurn = uint256(95).mul(cashPriceOne).div(10**2);

        bondDepletionFloor = uint256(1000).mul(cashPriceOne);
    }

    /* =================== Modifier =================== */

    modifier checkMigration {
        require(!migrated, 'Treasury: migrated');

        _;
    }

    modifier checkOperator {
        require(
            IBasisAsset(bzzt).operator() == address(this) &&
                IBasisAsset(bzzb).operator() == address(this) &&
                IBasisAsset(bzz1).operator() == address(this) &&
                Operator(boardroom).operator() == address(this),
            'Treasury: need more permission'
        );

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // budget
    function getReserve() public view returns (uint256) {
        return accumulatedSeigniorage;
    }

    // oracle
    function getBondOraclePrice() public view returns (uint256) {
        return _getCashPrice(bondOracle);
    }

    function getSeigniorageOraclePrice() public view returns (uint256) {
        return _getCashPrice(seigniorageOracle);
    }

    function _getCashPrice(address oracle) internal view returns (uint256) {
        try IOracle(oracle).consult(bzzt, 1e18) returns (uint256 price) {
            return price;
        } catch {
            revert('Treasury: failed to consult cash price from the oracle');
        }
    }

    /* ========== GOVERNANCE ========== */

    function initialize() public checkOperator {
        require(!initialized, 'Treasury: initialized');

        // burn all of it's balance
        IBasisAsset(bzzt).burn(IERC20(bzzt).balanceOf(address(this)));

        // set accumulatedSeigniorage to it's balance
        accumulatedSeigniorage = IERC20(bzzt).balanceOf(address(this));

        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function migrate(address target) public onlyOperator checkOperator {
        require(!migrated, 'Treasury: migrated');

        // cash
        Operator(bzzt).transferOperator(target);
        Operator(bzzt).transferOwnership(target);
        IERC20(bzzt).transfer(target, IERC20(bzzt).balanceOf(address(this)));

        // bond
        Operator(bzzb).transferOperator(target);
        Operator(bzzb).transferOwnership(target);
        IERC20(bzzb).transfer(target, IERC20(bzzb).balanceOf(address(this)));

        // share
        Operator(bzz1).transferOperator(target);
        Operator(bzz1).transferOwnership(target);
        IERC20(bzz1).transfer(target, IERC20(bzz1).balanceOf(address(this)));

        migrated = true;
        emit Migration(target);
    }

    function setFund(address newFund) public onlyOperator {
        fund = newFund;
        emit ContributionPoolChanged(msg.sender, newFund);
    }

    function setFundAllocationRate(uint256 rate) public onlyOperator {
        fundAllocationRate = rate;
        emit ContributionPoolRateChanged(msg.sender, rate);
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateCashPrice() internal {
        try IOracle(bondOracle).update()  {} catch {}
        try IOracle(seigniorageOracle).update()  {} catch {}
    }

    function buyBonds(uint256 amount, uint256 targetPrice)
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkOperator
    {
        require(amount > 0, 'Treasury: cannot purchase bonds with zero amount');
        uint256 cashPrice = _getCashPrice(bondOracle);
        require(cashPrice == targetPrice, 'Treasury: cash price moved');
        require(
            cashPrice < cashPriceBurn, // price < $0.9
            'Treasury: cashPrice not eligible for bond purchase'
        );

        uint256 bondPrice = cashPrice;

        IBasisAsset(bzzt).burnFrom(msg.sender, amount);
        IBasisAsset(bzzb).mint(msg.sender, amount.mul(1e18).div(bondPrice));
        _updateCashPrice();

        emit BoughtBonds(msg.sender, amount);
    }

    function redeemBonds(uint256 amount, uint256 targetPrice)
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkOperator
    {
        require(amount > 0, 'Treasury: cannot redeem bonds with zero amount');
        uint256 cashPrice = _getCashPrice(bondOracle);
        require(cashPrice == targetPrice, 'Treasury: cash price moved');
        require(
            cashPrice > cashPriceCeiling, // price > $1.
            'Treasury: cashPrice not eligible for bond purchase'
        );
        require(
            IERC20(bzzt).balanceOf(address(this)) >= amount,
            'Treasury: treasury has no more budget'
        );

        accumulatedSeigniorage = accumulatedSeigniorage.sub(
            SafeMath.min(accumulatedSeigniorage, amount)
        );

        IBasisAsset(bzzb).burnFrom(msg.sender, amount);
        IERC20(bzzt).safeTransfer(msg.sender, amount);
        _updateCashPrice();

        emit RedeemedBonds(msg.sender, amount);
    }

    function allocateSeigniorage()
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkEpoch
        checkOperator
    {
        _updateCashPrice();
        uint256 cashPrice = _getCashPrice(seigniorageOracle);
        if (cashPrice <= cashPriceCeiling) {
            return; // just advance epoch instead revert
        }

        // circulating supply
        uint256 cashSupply = IERC20(bzzt).totalSupply().sub(
            accumulatedSeigniorage
        );
        uint256 percentage = cashPrice.sub(cashPriceOne);//ADC价格-1u
        uint256 seigniorage = cashSupply.mul(percentage).div(1e18).mul(3).div(10);
        IBasisAsset(bzzt).mint(address(this), seigniorage);

        // ======================== BIP-3
        // uint256 fundReserve = seigniorage.mul(fundAllocationRate).div(100);
        // if (fundReserve > 0) {
        //     IERC20(cash).safeApprove(fund, fundReserve);
        //     ISimpleERCFund(fund).deposit(
        //         cash,
        //         fundReserve,
        //         'Treasury: Seigniorage Allocation'
        //     );
        //     emit ContributionPoolFunded(now, fundReserve);
        // }

        // seigniorage = seigniorage.sub(fundReserve);

        // ======================== BIP-4
        uint256 treasuryReserve = SafeMath.min(
            seigniorage,
            IERC20(bzzb).totalSupply().sub(accumulatedSeigniorage)
        );
        if (treasuryReserve > 0) {
            accumulatedSeigniorage = accumulatedSeigniorage.add(
                treasuryReserve
            );
            emit TreasuryFunded(now, treasuryReserve);
        }

        // boardroom
        uint256 boardroomReserve = seigniorage.sub(treasuryReserve);
        if (boardroomReserve > 0) {
            IERC20(bzzt).safeApprove(boardroom, boardroomReserve);
            IBoardroom(boardroom).allocateSeigniorage(boardroomReserve);
            emit BoardroomFunded(now, boardroomReserve);
        }
    }

    // GOV
    event Initialized(address indexed executor, uint256 at);
    event Migration(address indexed target);
    event ContributionPoolChanged(address indexed operator, address newFund);
    event ContributionPoolRateChanged(
        address indexed operator,
        uint256 newRate
    );

    // CORE
    event RedeemedBonds(address indexed from, uint256 amount);
    event BoughtBonds(address indexed from, uint256 amount);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event ContributionPoolFunded(uint256 timestamp, uint256 seigniorage);
}
