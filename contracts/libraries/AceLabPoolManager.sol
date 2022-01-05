// SPDX-License-Identifier: MIT

import "../abstract/Ownable.sol";
import "../interfaces/IAceLab.sol";
import "../interfaces/IUniswapRouterETH.sol";
import "../interfaces/IBooMirrorWorld.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

pragma solidity 0.8.9;

library AceLabPoolManager {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public constant wftm =
        address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    function withdraw(
        uint8[] storage pools,
        uint256 amount,
        uint256 booBalance,
        uint256 totalPoolBalance,
        mapping(uint8 => uint256) storage poolxBooBalance,
        address aceLab,
        address xBoo,
        address boo
    ) external returns (uint256 newTotalPoolBalance) {
        for (uint256 index = 0; index < pools.length; index++) {
            uint8 poolId = pools[index];
            uint256 currentPoolxBooBalance = poolxBooBalance[poolId];
            if (currentPoolxBooBalance > 0) {
                uint256 remainingBooAmount = amount - booBalance;
                uint256 remainingxBooAmount = IBooMirrorWorld(xBoo).BOOForxBOO(
                    remainingBooAmount
                );
                uint256 withdrawAmount;
                if (remainingxBooAmount > currentPoolxBooBalance) {
                    withdrawAmount = currentPoolxBooBalance;
                } else {
                    withdrawAmount = remainingxBooAmount;
                }
                IAceLab(aceLab).withdraw(poolId, withdrawAmount);
                totalPoolBalance = totalPoolBalance.sub(withdrawAmount);
                poolxBooBalance[poolId] = poolxBooBalance[poolId].sub(
                    withdrawAmount
                );
                uint256 xBooBalance = IERC20(xBoo).balanceOf(address(this));
                IBooMirrorWorld(xBoo).leave(xBooBalance);
                booBalance = IERC20(boo).balanceOf(address(this));
                if (booBalance >= amount) {
                    break;
                }
            }
        }
        return totalPoolBalance;
    }

    function addUsedPool(
        uint8[] storage pools,
        uint8 poolId,
        address[] memory _poolRewardToWftmPath,
        mapping(uint8 => address[]) storage poolRewardToWftmPaths,
        address aceLab,
        address uniRouter
    ) external {
        pools.push(poolId);
        poolRewardToWftmPaths[poolId] = _poolRewardToWftmPath;
        address poolRewardToken;
        if (_poolRewardToWftmPath.length > 0) {
            poolRewardToken = _poolRewardToWftmPath[0];
        } else {
            poolRewardToken = address(
                IAceLab(aceLab).poolInfo(poolId).RewardToken
            );
        }
        if (poolRewardToken != wftm) {
            IERC20(poolRewardToken).safeApprove(uniRouter, type(uint256).max);
        }
    }

    function removeUsedPool(
        uint8[] storage pools,
        uint8 poolIndex,
        uint256 totalPoolBalance,
        address aceLab,
        address uniRouter,
        mapping(uint8 => uint256) storage poolxBooBalance
    ) external returns (uint256 newTotalPoolBalance) {
        uint8 poolId = pools[poolIndex];
        IAceLab(aceLab).poolInfo(poolId).RewardToken.safeApprove(uniRouter, 0);
        uint256 balance = poolxBooBalance[poolId];
        IAceLab(aceLab).withdraw(poolId, balance);
        totalPoolBalance = totalPoolBalance.sub(balance);
        poolxBooBalance[poolId] = 0;
        uint256 lastPoolIndex = pools.length - 1;
        uint8 lastPoolId = pools[lastPoolIndex];
        pools[poolIndex] = lastPoolId;
        pools.pop();
        return totalPoolBalance;
    }

    /**
     * @dev Removes all allowance to all pool rewards for the {uniRouter}.
     */
    function removePoolAllowances(
        uint8[] storage pools,
        address aceLab,
        address uniRouter
    ) external {
        for (uint256 index = 0; index < pools.length; index++) {
            uint8 poolId = pools[index];
            IAceLab(aceLab).poolInfo(poolId).RewardToken.safeApprove(
                uniRouter,
                0
            );
        }
    }

    /**
     * @dev Gives max allowance to all pool rewards for the {uniRouter}.
     */
    function givePoolAllowances(
        uint8[] storage pools,
        address aceLab,
        address uniRouter
    ) external {
        for (uint256 index = 0; index < pools.length; index++) {
            IERC20 rewardToken = IAceLab(aceLab)
                .poolInfo(pools[index])
                .RewardToken;
            rewardToken.safeApprove(uniRouter, 0);
            rewardToken.safeApprove(uniRouter, type(uint256).max);
        }
    }

    /**
     * @dev Emergency withdraws from all pools
     */
    function emergencyWithdraw(uint8[] storage pools, address aceLab) external {
        for (uint256 index = 0; index < pools.length; index++) {
            uint8 poolId = pools[index];
            IAceLab(aceLab).emergencyWithdraw(poolId);
        }
    }

    /**
     * @dev Withdraws and collect rewards from all pools, swaps to wftm
     */
    function withdrawAll(
        uint8[] storage pools,
        mapping(uint8 => uint256) storage poolxBooBalance,
        address aceLab,
        address uniRouter
    ) external {
        for (uint256 index = 0; index < pools.length; index++) {
            uint8 poolId = pools[index];
            uint256 balance = poolxBooBalance[poolId];
            IAceLab(aceLab).withdraw(poolId, balance);
            _swapRewardToWftm(poolId, aceLab, uniRouter);
        }
    }

    /**
     * @dev Collects reward tokens from all used pools, swaps it into wftm and estimates
     * the yield for each pool.
     */
    function collectRewardsAndEstimateYield(
        uint8[] storage pools,
        mapping(uint8 => uint256) storage poolxBooBalance,
        mapping(uint8 => bool) storage hasAllocatedToPool,
        mapping(uint8 => uint256) storage poolYield,
        address aceLab,
        address uniRouter
    ) external {
        for (uint256 index = 0; index < pools.length; index++) {
            uint8 poolId = pools[index];
            uint256 currentPoolxBooBalance = poolxBooBalance[poolId];
            IAceLab(aceLab).withdraw(poolId, currentPoolxBooBalance);
            poolxBooBalance[poolId] = 0;
            _swapRewardToWftm(poolId, aceLab, uniRouter);
            _setEstimatedYield(poolId, aceLab, uniRouter, poolYield);
            hasAllocatedToPool[poolId] = false;
        }
    }

    /**
     * @dev Swaps any pool reward token to wftm
     */
    function _swapRewardToWftm(
        uint8 _poolId,
        address aceLab,
        address uniRouter
    ) internal {
        IERC20 rewardToken = IAceLab(aceLab).poolInfo(_poolId).RewardToken;
        uint256 poolRewardTokenBal = rewardToken.balanceOf(address(this));
        if (poolRewardTokenBal > 0 && address(rewardToken) != wftm) {
            address[] memory path = new address[](2);
            path[0] = address(rewardToken);
            path[1] = wftm;
            IUniswapRouterETH(uniRouter)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    poolRewardTokenBal,
                    0,
                    path,
                    address(this),
                    block.timestamp.add(600)
                );
        }
    }

    /**
     * @dev Estimates the current yield in wftm 1 day forward for each pool
     */
    function _setEstimatedYield(
        uint8 _poolId,
        address aceLab,
        address uniRouter,
        mapping(uint8 => uint256) storage poolYield
    ) internal {
        IAceLab.PoolInfo memory poolInfo = IAceLab(aceLab).poolInfo(_poolId);
        uint256 _from = block.timestamp;
        uint256 _to = block.timestamp + 1 days;
        uint256 multiplier;
        _from = _from > poolInfo.startTime ? _from : poolInfo.startTime;
        if (_from > poolInfo.endTime || _to < poolInfo.startTime) {
            multiplier = 0;
        }
        if (_to > poolInfo.endTime) {
            multiplier = poolInfo.endTime - _from;
        }
        multiplier = _to - _from;
        uint256 totalTokens = multiplier * poolInfo.RewardPerSecond;
        if (address(poolInfo.RewardToken) == wftm) {
            uint256 wftmYield = (1 ether * totalTokens) /
                poolInfo.xBooStakedAmount;
            poolYield[_poolId] = wftmYield;
        } else {
            if (totalTokens == 0) {
                poolYield[_poolId] = 0;
            } else {
                address[] memory path = new address[](2);
                path[0] = address(poolInfo.RewardToken);
                path[1] = wftm;
                uint256 wftmTotalPoolYield = IUniswapRouterETH(uniRouter)
                    .getAmountsOut(totalTokens, path)[1];
                uint256 wftmYield = (1 ether * wftmTotalPoolYield) /
                    poolInfo.xBooStakedAmount;
                poolYield[_poolId] = wftmYield;
            }
        }
    }
}
