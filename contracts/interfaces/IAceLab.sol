// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.9;

interface IAceLab {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 catDebt; // Cat debt. See explanation below.
        uint256 mp; // Total staked magicat power, sum of all magicat rarities staked by this user in this pool [uint64 enough]
    }

    struct PoolInfo {
        //full slot = 32B
        IERC20 RewardToken; //20B Address of reward token contract.
        uint32 userLimitEndTime; //4B
        uint8 TokenPrecision; //1B The precision factor used for calculations, equals the tokens decimals
        //7B [free space available here]

        uint256 xBooStakedAmount; //32B # of xboo allocated to this pool
        uint256 mpStakedAmount; //32B # of mp allocated to this pool
        uint256 RewardPerSecond; //32B reward token per second for this pool in wei
        uint256 accRewardPerShare; //32B Accumulated reward per share, times the pools token precision. See below.
        uint256 accRewardPerShareMagicat; //32B Accumulated reward per share, times the pools token precision. See below.
        address protocolOwnerAddress; //20B this address is the owner of the protocol corresponding to the reward token, used for emergency withdraw to them only
        uint32 lastRewardTime; //4B Last block time that reward distribution occurs.
        uint32 endTime; //4B end time of pool
        uint32 startTime; //4B start time of pool
    }

    function poolInfo(uint256 _poolId) external view returns (PoolInfo memory);

    function userInfo(uint256 _poolId, address _userAddress)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 catDebt,
            uint256 mp
        );

    function poolLength() external view returns (uint256);

    // View function to see pending BOOs on frontend.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256, uint256);

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external;

    // Deposit tokens.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        uint256[] memory tokenIDs
    ) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(
        uint256 _pid,
        uint256 _amount,
        uint256[] memory tokenIDs
    ) external;

    function rarityOf(uint256) external returns (uint256);

    function getStakedMagicats(uint256, address) external returns (uint256[] memory);

    // Withdraw tokens.
    function withdraw(uint256 _pid, uint256 _amount) external;

    function balanceOf(address) external returns (uint256);

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;

    function userCurrentStakeableMP(uint256 _pid, address _user) external returns (int256);
}
