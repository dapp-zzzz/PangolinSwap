// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './lib/IERC20.sol';
import './lib/Ownable.sol';
import './lib/SafeMath.sol';
import './lib/SafeERC20.sol';
contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public _lpt = IERC20(0x4320e6e082C7bfE69Cc2b33f182E554f8a83A268); //WIKI/USDT LP;
    address public _team = 0xc3ee23a0EA975908d91891a48795906A44A423bb;
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
        _lpt.safeTransferFrom(msg.sender, address(this), amount);
    }
    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _lpt.safeTransfer(msg.sender, amount);
    }
}

contract LPPool is LPTokenWrapper, Ownable {

    IERC20 public _rewardToken = IERC20(0x47fA20ba81333BA507d687913bAF7c89432182A1); //BZZONE;
    uint256 public _reward = 541.67 * 1e18;
    uint256 public constant DURATION = 1 days;

    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor() public {}

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        uint nowTime = block.timestamp;
        uint rewardRate = _reward.div(DURATION);
        return
        rewardPerTokenStored.add(
            nowTime
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
    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, 'Cannot stake 0');
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, 'Cannot withdraw 0');
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _rewardToken.safeTransfer(_team, reward.mul(75).div(1000));
            _rewardToken.safeTransfer(msg.sender, reward.mul(925).div(1000));
            emit RewardPaid(msg.sender, reward);
        }
    }

    function changeReward(uint reward) external onlyOwner updateReward(address(0)) {
        _reward = reward;
        emit RewardAdded(reward);
    }
}
