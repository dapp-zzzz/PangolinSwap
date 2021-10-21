// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./lib/SafeMath.sol";
import "./lib/IERC20.sol";
import "./lib/Address.sol";
import "./lib/SafeERC20.sol";
import "./lib/IRewardDistributionRecipient.sol";
import "./lib/LPTokenWrapper.sol";

contract DoubleCoinPool is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public basisShare;
    address public team;
    uint256 public DURATION = 10 days;

    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        address basisShare_,
        address lptoken_,
        address lptoken2_,

        address team_
    ) public {
        basisShare = IERC20(basisShare_);
        lpt = IERC20(lptoken_);//
        lpt2 = IERC20(lptoken2_);//bzzt
  
        team = team_;
    }

    modifier checkStart() {
        require(
            block.timestamp >= starttime && starttime != 0,
            "DAIBASLPTokenSharePool: not start"
        );
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return SafeMath.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "DAIBASLPTokenSharePool: Cannot stake 0");
        super.stake2(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "DAIBASLPTokenSharePool: Cannot withdraw 0");
        super.withdraw2(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint256 teamIncome = reward.mul(75).div(1000);
            basisShare.safeTransfer(team, teamIncome);
            basisShare.safeTransfer(msg.sender, reward.sub(teamIncome));
            emit RewardPaid(msg.sender, reward);
        }
    }

    function setStartTime(uint256 _startTime)
        external
        override
        onlyRewardDistribution
    {
        starttime = _startTime;
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
                //
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(reward);
        }
    }
}
