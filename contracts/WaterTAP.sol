// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

import './lib/IERC20.sol';
import './lib/SafeERC20.sol';

import './lib/Safe112.sol';
import './lib/Operator.sol';
import './lib/ContractGuard.sol';
import './lib/IBasisAsset.sol';

contract ShareWrapper {

    uint256 _totalSupply;
    mapping(address => uint256) _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
}

contract WaterTap is ShareWrapper, ContractGuard, Operator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Safe112 for uint112;

    
    /* ========== DATA STRUCTURES ========== */

    struct Boardseat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
    }

    struct BoardSnapshot {
        uint256 time;
        uint256 rewardReceived; 
        uint256 rewardPerShare;
    }

    /* ========== STATE VARIABLES ========== */
    bool public _canStake = false;

    IERC20 private bzzt;

    IERC20 private bzz1;

    IERC20 private TAP;

    IERC20 private XCH;

    address public treasury;

    mapping(address => uint256) public stakeInfo;

    mapping(address => Boardseat) private directors;
    BoardSnapshot[] private boardHistory;

    /* ========== CONSTRUCTOR ========== */

    constructor(IERC20 _bzzt, IERC20 _bzz1,IERC20 _TAP,IERC20 _XCH) public {
        bzzt = _bzzt;
        bzz1 = _bzz1;
        TAP = _TAP;
        XCH = _XCH;

        BoardSnapshot memory genesisSnapshot = BoardSnapshot({
            time: block.number,
            rewardReceived: 0,
            rewardPerShare: 0
        });
        boardHistory.push(genesisSnapshot);
    }

    /* ========== Modifiers =============== */
    modifier directorExists {
        require(
            balanceOf(msg.sender) > 0,
            'Boardroom: The director does not exist'
        );
        _;
    }

    modifier updateReward(address director) {
        if (director != address(0)) {
            Boardseat memory seat = directors[director];
            seat.rewardEarned = earned(director);
            seat.lastSnapshotIndex = latestSnapshotIndex();
            directors[director] = seat;
        }
        _;
    }

   

    function latestSnapshotIndex() public view returns (uint256) {
        return boardHistory.length.sub(1);
    }

    function getLatestSnapshot() internal view returns (BoardSnapshot memory) {
        return boardHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address director)
        public
        view
        returns (uint256)
    {
        return directors[director].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address director)
        internal
        view
        returns (BoardSnapshot memory)
    {
        return boardHistory[getLastSnapshotIndexOf(director)];
    }

    // =========== Director getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address director) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(director).rewardPerShare;

        return
            balanceOf(director).mul(latestRPS.sub(storedRPS)).div(1e18).add(
                directors[director].rewardEarned
            );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setTreasury(address treasury_) external onlyOperator {
        treasury = treasury_;
    }

    function stake(uint256 amount)
        public
        onlyOneBlock
        updateReward(msg.sender)
    {   
        
        require(_canStake , 'Can\'t stake');
        require(amount > 0, 'Boardroom: Cannot stake 0');
        TAP.safeTransferFrom(msg.sender, address(this), amount);
        stakeInfo[msg.sender] = stakeInfo[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        onlyOneBlock
        directorExists
        updateReward(msg.sender)
    {
        require(amount > 0, 'Boardroom: Cannot withdraw 0');
        TAP.safeTransfer(msg.sender, amount);
        XCH.safeTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, amount.mul(5).div(100));  
        XCH.safeTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, amount.mul(5).div(100));        
        uint256 directorShare = _balances[msg.sender];
        require(
            directorShare >= amount,
            'Boardroom: withdraw request greater than staked amount'
        );
        stakeInfo[msg.sender]= stakeInfo[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = directorShare.sub(amount);
        emit Withdrawn(msg.sender, amount);
    }



    function allocateSeigniorage(uint256 amount)
        external
        onlyOneBlock
        onlyOperator
    {
        require(amount > 0, 'Boardroom: Cannot allocate 0');
        require(
            totalSupply() > 0,
            'Boardroom: Cannot allocate when totalSupply is 0'
        );

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = prevRPS.add(amount.mul(1e18).div(totalSupply()));

        BoardSnapshot memory newSnapshot = BoardSnapshot({
            time: block.number,
            rewardReceived: amount,
            rewardPerShare: nextRPS
        });
        boardHistory.push(newSnapshot);

        XCH.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

   function setCanSwap(bool canStake) external onlyOperator {
        _canStake = canStake;
    }


    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);
}
