// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './SafeMath.sol';
import './IERC20.sol';

import './Operator.sol';
import './IDistributor.sol';
import './IRewardDistributionRecipient.sol';

contract InitialShareDistributor is IDistributor, Operator {
    using SafeMath for uint256;

    event Distributed(address pool, uint256 cashAmount);

    bool public once = true;

    IERC20 public share;

    IRewardDistributionRecipient public aochtLPPool;
    uint256 public aochtInitialBalance;
    IRewardDistributionRecipient public aocusdtLPPool;
    uint256 public aocusdtInitialBalance;
    IRewardDistributionRecipient public aoshtLPPool;
    uint256 public aoshtInitialBalance;
    IRewardDistributionRecipient public aosusdtLPPool;
    uint256 public aosusdtInitialBalance;

    constructor(
        IERC20 _share,
        IRewardDistributionRecipient _aochtLPPool,
        uint256 _aochtInitialBalance,
        IRewardDistributionRecipient _aocusdtLPPool,
        uint256 _aocusdtInitialBalance,
        IRewardDistributionRecipient _aoshtLPPool,
        uint256 _aoshtInitialBalance,
        IRewardDistributionRecipient _aosusdtLPPool,
        uint256 _aosusdtInitialBalance
    ) public {
        share = _share;
        aochtLPPool = _aochtLPPool;
        aochtInitialBalance = _aochtInitialBalance;
        aocusdtLPPool = _aocusdtLPPool;
        aocusdtInitialBalance = _aocusdtInitialBalance;
        aoshtLPPool = _aoshtLPPool;
        aoshtInitialBalance = _aoshtInitialBalance;
        aosusdtLPPool = _aosusdtLPPool;
        aosusdtInitialBalance = _aosusdtInitialBalance;
    }

    function distribute() public override onlyOperator {
        require(
            once,
            
            'InitialShareDistributor: you cannot run this function twice'
        );

        uint256 startTime = block.timestamp.add(60);

        // 37.5w
        share.transfer(address(aochtLPPool), aochtInitialBalance);
        aochtLPPool.setStartTime(startTime);
        aochtLPPool.notifyRewardAmount(aochtInitialBalance);
        emit Distributed(address(aochtLPPool), aochtInitialBalance);

        // 37.5w
        share.transfer(address(aocusdtLPPool), aocusdtInitialBalance);
        aocusdtLPPool.setStartTime(startTime);
        aocusdtLPPool.notifyRewardAmount(aocusdtInitialBalance);
        emit Distributed(address(aocusdtLPPool), aocusdtInitialBalance);

        // 12.5w
        share.transfer(address(aoshtLPPool), aoshtInitialBalance);
        aoshtLPPool.setStartTime(startTime);
        aoshtLPPool.notifyRewardAmount(aoshtInitialBalance);
        emit Distributed(address(aoshtLPPool), aoshtInitialBalance);

        // 12.5w
        share.transfer(address(aosusdtLPPool), aosusdtInitialBalance);
        aosusdtLPPool.setStartTime(startTime);
        aosusdtLPPool.notifyRewardAmount(aosusdtInitialBalance);
        emit Distributed(address(aosusdtLPPool), aosusdtInitialBalance);

        once = false;
    }
}
