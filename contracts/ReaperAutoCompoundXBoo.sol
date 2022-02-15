// SPDX-License-Identifier: MIT

import "./abstract/ReaperBaseStrategy.sol";
import "./interfaces/IAceLab.sol";
import "./interfaces/IBooMirrorWorld.sol";
import "./interfaces/IUniswapRouterETH.sol";
import "./interfaces/IPaymentRouter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.9;

/**
 * @dev This is a strategy to stake stakingToken into xToken, and then stake xToken in different pools to collect more rewards
 * The strategy will compound the pool rewards into stakingToken which will be deposited into the strategy for more yield.
 */
contract ReaperAutoCompoundXBoo is ReaperBaseStrategy {
    using SafeERC20 for IERC20;
    using SafeERC20 for IBooMirrorWorld;
    using SafeMath for uint256;
    using SafeMath for int256;

    /**
     * @dev Tokens Used:
     * {wftm} - Required for liquidity routing when doing swaps. Also used to charge fees on yield.
     * {xToken} - Token generated by staking our funds. Also used to stake in secondary pools.
     * {stakingToken} - Token that the strategy maximizes.
     */
    address public constant wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    IBooMirrorWorld public constant xToken =
        IBooMirrorWorld(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598); // xBoo
    IERC20 public constant stakingToken =
        IERC20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE); // Boo

    /**
     * @dev Third Party Contracts:
     * {uniRouter} - the uniRouter for target DEX
     * {aceLab} - Address to AceLab, the SpookySwap contract to stake xToken
     */
    address public constant uniRouter =
        0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address public constant aceLab = 0x2352b745561e7e6FCD03c093cE7220e3e126ace0;

    /**
     * @dev Routes we take to swap tokens
     * {wftmToStakingTokenPaths} - Route we take to get from {wftm} into {stakingToken}.
     * {poolRewardToWftmPaths} - Routes for each pool to get from {pool reward token} into {wftm}.
     */
    address[] public wftmToStakingTokenPaths = [wftm, address(stakingToken)];
    mapping(uint256 => address[]) public poolRewardToWftmPaths;

    /**
     * @dev Variables for pool selection
     * {currentPoolId} - Pool id for the the current pool the strategy deposits xToken into
     * {currentlyUsedPools} - A list of all pool ids currently being used by the strategy
     * {poolYield} - The estimated yield in wftm for each pool over the next 1 day
     * {hasAllocatedToPool} - If a given pool id has been deposited into already for a harvest cycle
     * {maxPoolDilutionFactor} - The factor that determines what % of a pools total TVL can be deposited (to avoid dilution)
     * {maxNrOfPools} - The maximum amount of pools the strategy can use
     */
    uint256 public currentPoolId = 0;
    uint256[] public currentlyUsedPools;
    mapping(uint256 => uint256) public poolYield;
    mapping(uint256 => bool) public hasAllocatedToPool;
    uint256 public maxPoolDilutionFactor = 5;
    uint256 public maxNrOfPools = 15;

    /**
     * @dev Variables for pool selection
     * {totalPoolBalance} - The total amount of xToken currently deposited into pools
     * {poolxTokenBalance} - The amount of xToken deposited into each pool
     */
    uint256 public totalPoolBalance = 0;
    mapping(uint256 => uint256) public poolxTokenBalance;

    /**
     * {UpdatedStrategist} Event that is fired each time the strategist role is updated.
     */
    event UpdatedStrategist(address newStrategist);

    /**
     * @dev Initializes the strategy. Sets parameters, saves routes, and gives allowances.
     * @notice see documentation for each variable above its respective declaration.
     */
    constructor(
        address _vault,
        address[] memory _feeRemitters,
        address[] memory _strategists
    ) ReaperBaseStrategy(_vault, _feeRemitters, _strategists) {
        _giveAllowances();
    }

    /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone deposits in the strategy's vault contract.
     * It deposits {stakingToken} into xToken (BooMirrorWorld) to farm {xToken} and finally,
     * xToken is deposited into other pools to earn additional rewards
     */
    function deposit() public whenNotPaused {
        uint256 stakingTokenBalance = stakingToken.balanceOf(address(this));

        if (stakingTokenBalance != 0) {
            xToken.enter(stakingTokenBalance);
            uint256 xTokenBalance = xToken.balanceOf(address(this));
            if (currentPoolId == 0) {
                // Default to the first pool before the first harvest
                currentPoolId = currentlyUsedPools[0];
            }
            _aceLabDeposit(currentPoolId, xTokenBalance);
        }
    }

    /**
     * @dev Function to deposit into AceLab while keeping internal accounting
     *      updated.
     */
    function _aceLabDeposit(uint256 _poolId, uint256 _xTokenAmount) internal {
        totalPoolBalance = totalPoolBalance.add(_xTokenAmount);
        poolxTokenBalance[_poolId] = poolxTokenBalance[_poolId].add(
            _xTokenAmount
        );
        IAceLab(aceLab).deposit(_poolId, _xTokenAmount);
    }

    /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {stakingToken} from the AceLab pools.
     * The available {stakingToken} minus fees is returned to the vault.
     */
    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 stakingTokenBalance = stakingToken.balanceOf(address(this));

        if (stakingTokenBalance < _amount) {
            for (
                uint256 index = currentlyUsedPools.length;
                index > 0 && stakingTokenBalance < _amount;
                index--
            ) {
                uint256 poolId = currentlyUsedPools[index - 1];
                uint256 currentPoolxTokenBalance = poolxTokenBalance[poolId];
                if (currentPoolxTokenBalance != 0) {
                    uint256 remainingBooAmount = _amount - stakingTokenBalance;
                    uint256 remainingxTokenAmount = xToken.BOOForxBOO(
                        remainingBooAmount
                    );
                    uint256 withdrawAmount;
                    if (remainingxTokenAmount > currentPoolxTokenBalance) {
                        withdrawAmount = currentPoolxTokenBalance;
                    } else {
                        withdrawAmount = remainingxTokenAmount;
                    }
                    _aceLabWithdraw(poolId, withdrawAmount);
                    uint256 xTokenBalance = xToken.balanceOf(address(this));
                    xToken.leave(xTokenBalance);
                    stakingTokenBalance = stakingToken.balanceOf(address(this));
                }
            }
        }

        if (stakingTokenBalance > _amount) {
            stakingTokenBalance = _amount;
        }

        uint256 withdrawFee = stakingTokenBalance.mul(securityFee).div(
            PERCENT_DIVISOR
        );

        stakingToken.safeTransfer(vault, stakingTokenBalance.sub(withdrawFee));
    }

    /**
     * @dev Function to withdraw from AceLab while keeping internal accounting
     *      updated.
     */
    function _aceLabWithdraw(uint256 _poolId, uint256 _xTokenAmount) internal {
        totalPoolBalance = totalPoolBalance.sub(_xTokenAmount);
        poolxTokenBalance[_poolId] = poolxTokenBalance[_poolId].sub(
            _xTokenAmount
        );
        IAceLab(aceLab).withdraw(_poolId, _xTokenAmount);
    }

    /**
     * @dev Check if the internal pool accounting matches with AceLab
     */
    function isInternalAccountingAccurate() external view returns (bool) {
        uint256 total = 0;
        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            uint256 _poolId = currentlyUsedPools[index];
            (uint256 amount, ) = IAceLab(aceLab).userInfo(
                _poolId,
                address(this)
            );
            uint256 internalBalance = poolxTokenBalance[_poolId];
            total = total.add(amount);
            if (amount != internalBalance) {
                return false;
            }
        }
        if (total != totalPoolBalance) {
            return false;
        }
        return true;
    }

    /**
     * @dev If internal accounting is off this function can synchronize
     *      the internal pool accounting with AceLab
     */
    function updateInternalAccounting() external returns (bool) {
        _onlyStrategistOrOwner();
        uint256 total = 0;
        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            uint256 _poolId = currentlyUsedPools[index];
            (uint256 amount, ) = IAceLab(aceLab).userInfo(
                _poolId,
                address(this)
            );
            poolxTokenBalance[_poolId] = amount;
            total = total.add(amount);
        }
        totalPoolBalance = total;
        return true;
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     * 1. It claims rewards from the AceLab pools and estimated the current yield for each pool.
     * 2. It charges the system fees to simplify the split.
     * 3. It swaps the {wftm} token for {stakingToken} which is deposited into {xToken}
     * 4. It distributes the xToken using a yield optimization algorithm into various pools.
     */
    function _harvestCore() internal override {
        _collectRewardsAndEstimateYield();
        _chargeFees();
        _swapWftmToStakingToken();
        _enterXBoo();
        _rebalance();
    }

    /**
     * @dev Returns the approx amount of profit from harvesting.
     *      Profit is denominated in wftm, and takes fees into account.
     */
    function estimateHarvest()
        external
        view
        override
        returns (uint256 profit, uint256 callFeeToUser)
    {
        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            uint256 poolId = currentlyUsedPools[index];
            uint256 pendingReward = IAceLab(aceLab).pendingReward(
                poolId,
                address(this)
            );

            uint256 freeRewards = IERC20(poolRewardToWftmPaths[poolId][0])
                .balanceOf(address(this));
            uint256 totalRewards = pendingReward + freeRewards;

            if (totalRewards == 0) {
                continue;
            }

            if (poolRewardToWftmPaths[poolId][0] == wftm) {
                profit += totalRewards;
            } else {
                uint256[] memory amountOutMins = IUniswapRouterETH(uniRouter)
                    .getAmountsOut(totalRewards, poolRewardToWftmPaths[poolId]);
                profit += amountOutMins[1];
            }
        }

        // // take out fees from profit
        uint256 wftmFee = (profit * totalFee) / PERCENT_DIVISOR;
        callFeeToUser = (wftmFee * callFee) / PERCENT_DIVISOR;
        profit -= wftmFee;
    }

    /**
     * @dev Collects reward tokens from all used pools, swaps it into wftm and estimates
     * the yield for each pool.
     */
    function _collectRewardsAndEstimateYield() internal {
        uint256 nrOfUsedPools = currentlyUsedPools.length;
        for (uint256 index = 0; index < nrOfUsedPools; index++) {
            uint256 poolId = currentlyUsedPools[index];
            uint256 currentPoolxTokenBalance = poolxTokenBalance[poolId];
            hasAllocatedToPool[poolId] = false;
            _aceLabWithdraw(poolId, currentPoolxTokenBalance);
            _swapRewardToWftm(poolId);
            _setEstimatedYield(poolId);
        }
    }

    /**
     * @dev Swaps any pool reward token to wftm
     */
    function _swapRewardToWftm(uint256 _poolId) internal {
        address[] memory rewardToWftmPaths = poolRewardToWftmPaths[_poolId];
        address rewardToken = rewardToWftmPaths[0];
        uint256 poolRewardTokenBal = IERC20(rewardToken).balanceOf(
            address(this)
        );
        if (poolRewardTokenBal != 0 && rewardToken != wftm) {
            IUniswapRouterETH(uniRouter)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    poolRewardTokenBal,
                    0,
                    rewardToWftmPaths,
                    address(this),
                    block.timestamp.add(600)
                );
        }
    }

    /**
     * @dev Estimates yield in wftm per pool over a given time period
     *      This is done by taking the total amount of tokens emitted
     *      and dividing it by the total amount of xBoo staked in the
     *      pool, and then converted to wftm to give a common unit.
     */
    function _setEstimatedYield(uint256 _poolId) internal {
        IAceLab.PoolInfo memory poolInfo = IAceLab(aceLab).poolInfo(_poolId);
        uint256 _from = block.timestamp;
        // Look forward in time by the same time it took between the previous and current harvest
        uint256 _to = block.timestamp.add(block.timestamp).sub(
            lastHarvestTimestamp
        );
        // Total seconds the pool will receive rewards up to the next harvest (when strategy rebalances)
        uint256 multiplier = _getMultiplier(_from, _to, poolInfo);
        uint256 totalTokens = multiplier * poolInfo.RewardPerSecond;
        if (totalTokens == 0) {
            poolYield[_poolId] = 0;
            return;
        }

        if (address(poolInfo.RewardToken) == wftm) {
            uint256 wftmYield = (1 ether * totalTokens) /
                poolInfo.xBooStakedAmount;
            poolYield[_poolId] = wftmYield;
        } else {
            uint256 wftmTotalPoolYield = IUniswapRouterETH(uniRouter)
                .getAmountsOut(totalTokens, poolRewardToWftmPaths[_poolId])[1];
            uint256 wftmYield = (1 ether * wftmTotalPoolYield) /
                poolInfo.xBooStakedAmount;
            poolYield[_poolId] = wftmYield;
        }
    }

    /**
     * @dev This was copied from the AceLab contract, it was an internal
     *      function so could not be called. It calculates the amount of
     *      seconds in the given timespan that the pool will receive
     *      rewards. This prevents the strategy from allocating to pools
     *      that are ending. So it helps projects the yield in the future.
     */
    function _getMultiplier(
        uint256 _from,
        uint256 _to,
        IAceLab.PoolInfo memory pool
    ) private pure returns (uint256) {
        _from = _from > pool.startTime ? _from : pool.startTime;
        if (_from > pool.endTime || _to < pool.startTime) {
            return 0;
        }
        if (_to > pool.endTime) {
            return pool.endTime - _from;
        }
        return _to - _from;
    }

    /**
     * @dev Takes out fees from the rewards. Set by constructor
     * callFeeToUser is set as a percentage of the fee,
     * as is treasuryFeeToVault
     */
    function _chargeFees() internal {
        uint256 wftmFee = IERC20(wftm)
            .balanceOf(address(this))
            .mul(totalFee)
            .div(PERCENT_DIVISOR);

        if (wftmFee != 0) {
            uint256 callFeeToUser = wftmFee.mul(callFee).div(PERCENT_DIVISOR);
            uint256 treasuryFeeToVault = wftmFee.mul(treasuryFee).div(
                PERCENT_DIVISOR
            );
            uint256 feeToStrategist = treasuryFeeToVault.mul(strategistFee).div(
                PERCENT_DIVISOR
            );
            treasuryFeeToVault = treasuryFeeToVault.sub(feeToStrategist);

            IERC20(wftm).safeTransfer(msg.sender, callFeeToUser);
            IERC20(wftm).safeTransfer(treasury, treasuryFeeToVault);
            IERC20(wftm).safeApprove(strategistRemitter, 0);
            IERC20(wftm).safeApprove(strategistRemitter, feeToStrategist);
            IPaymentRouter(strategistRemitter).routePayment(
                wftm,
                feeToStrategist
            );
        }
    }

    /**
     * @dev Swaps all {wftm} into {stakingToken}
     */
    function _swapWftmToStakingToken() internal {
        uint256 wftmBalance = IERC20(wftm).balanceOf(address(this));
        if (wftmBalance != 0) {
            IUniswapRouterETH(uniRouter)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    wftmBalance,
                    0,
                    wftmToStakingTokenPaths,
                    address(this),
                    block.timestamp.add(600)
                );
        }
    }

    function _enterXBoo() internal {
        uint256 stakingTokenBalance = stakingToken.balanceOf(address(this));
        xToken.enter(stakingTokenBalance);
    }

    /**
     * @dev Deposits into the highest yielding pool, up to a cap set by {maxPoolDilutionFactor}
     * If xToken remains to be deposited picks the 2nd highest yielding pool and so on.
     */
    function _rebalance() internal {
        uint256 xTokenBalance = xToken.balanceOf(address(this));
        uint256 nrOfDeposits = 0;
        while (xTokenBalance != 0) {
            uint256 bestYield = 0;
            uint256 bestYieldPoolId = currentlyUsedPools[0];
            uint256 bestYieldIndex = 0;
            for (
                uint256 index = 0;
                index < currentlyUsedPools.length;
                index++
            ) {
                uint256 poolId = currentlyUsedPools[index];
                if (hasAllocatedToPool[poolId]) continue;

                uint256 currentPoolYield = poolYield[poolId];
                if (currentPoolYield > bestYield) {
                    bestYield = currentPoolYield;
                    bestYieldPoolId = poolId;
                    bestYieldIndex = index;
                }
            }
            uint256 poolDepositAmount = xTokenBalance;
            IAceLab.PoolInfo memory poolInfo = IAceLab(aceLab).poolInfo(
                bestYieldPoolId
            );
            bool isLastPool = currentlyUsedPools.length.sub(nrOfDeposits) == 1;
            if (
                !isLastPool &&
                poolDepositAmount >
                (poolInfo.xBooStakedAmount.div(maxPoolDilutionFactor))
            ) {
                poolDepositAmount = (
                    poolInfo.xBooStakedAmount.div(maxPoolDilutionFactor)
                );
            }
            hasAllocatedToPool[bestYieldPoolId] = true;
            nrOfDeposits = nrOfDeposits.add(1);
            _aceLabDeposit(bestYieldPoolId, poolDepositAmount);
            xTokenBalance = xToken.balanceOf(address(this));
            currentPoolId = bestYieldPoolId;
        }
    }

    /**
     * @dev Function to calculate the total underlaying {stakingToken} held by the strat.
     * It takes into account both the funds in hand, as the funds allocated in xToken and the AceLab pools.
     */
    function balanceOf() public view override returns (uint256) {
        uint256 balance = balanceOfStakingToken().add(
            balanceOfxToken().add(balanceOfPool())
        );
        return balance;
    }

    /**
     * @dev It calculates how much {stakingToken} the contract holds.
     */
    function balanceOfStakingToken() public view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    /**
     * @dev It calculates how much {stakingToken} the contract has staked as xToken.
     */
    function balanceOfxToken() public view returns (uint256) {
        return xToken.BOOBalance(address(this));
    }

    /**
     * @dev It calculates how much {stakingToken} the strategy has allocated in the AceLab pools
     */
    function balanceOfPool() public view returns (uint256) {
        return xToken.xBOOForBOO(totalPoolBalance);
    }

    /**
     * @dev Function that has to be called as part of strat migration. It sends all the available funds back to the
     * vault, ready to be migrated to the new strat.
     */
    function retireStrat() external {
        require(msg.sender == vault, "!vault");
        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            uint256 poolId = currentlyUsedPools[index];
            uint256 balance = poolxTokenBalance[poolId];
            _aceLabWithdraw(poolId, balance);
            _swapRewardToWftm(poolId);
        }

        _swapWftmToStakingToken();

        uint256 xTokenBalance = IERC20(xToken).balanceOf(address(this));
        IBooMirrorWorld(xToken).leave(xTokenBalance);

        uint256 stakingTokenBalance = stakingToken.balanceOf(address(this));
        stakingToken.transfer(vault, stakingTokenBalance);
    }

    /**
     * @dev Pauses deposits. Withdraws all funds from the AceLab contract, leaving rewards behind.
     */
    function panic() public {
        _onlyStrategistOrOwner();
        pause();

        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            uint256 poolId = currentlyUsedPools[index];
            IAceLab(aceLab).emergencyWithdraw(poolId);
        }
        uint256 xTokenBalance = xToken.balanceOf(address(this));
        xToken.leave(xTokenBalance);

        uint256 stakingTokenBalance = stakingToken.balanceOf(address(this));
        stakingToken.transfer(vault, stakingTokenBalance);
    }

    /**
     * @dev Pauses the strat.
     */
    function pause() public {
        _onlyStrategistOrOwner();
        _pause();
        _removeAllowances();
    }

    /**
     * @dev Unpauses the strat.
     */
    function unpause() external {
        _onlyStrategistOrOwner();
        _unpause();

        _giveAllowances();

        deposit();
    }

    /**
     * @dev Gives max allowance of {stakingToken} for the {xToken} contract,
     * {xToken} allowance for the {aceLab} contract,
     * {wftm} allowance for the {uniRouter}
     * in addition to allowance to all pool rewards for the {uniRouter}.
     */
    function _giveAllowances() internal {
        // Give xToken permission to use stakingToken
        stakingToken.safeApprove(address(xToken), 0);
        stakingToken.safeApprove(address(xToken), type(uint256).max);
        // Give xToken contract permission to stake xToken
        xToken.safeApprove(aceLab, 0);
        xToken.safeApprove(aceLab, type(uint256).max);
        // Give uniRouter permission to swap wftm to stakingToken
        IERC20(wftm).safeApprove(uniRouter, 0);
        IERC20(wftm).safeApprove(uniRouter, type(uint256).max);
        _givePoolAllowances();
    }

    /**
     * @dev Removes all allowance of {stakingToken} for the {xToken} contract,
     * {xToken} allowance for the {aceLab} contract,
     * {wftm} allowance for the {uniRouter}
     * in addition to allowance to all pool rewards for the {uniRouter}.
     */
    function _removeAllowances() internal {
        // Remove xToken permission to use stakingToken
        stakingToken.safeApprove(address(xToken), 0);
        // Remove xToken contract permission to stake xToken
        xToken.safeApprove(aceLab, 0);
        // Remove uniRouter permission to swap wftm to stakingToken
        IERC20(wftm).safeApprove(uniRouter, 0);
        _removePoolAllowances();
    }

    /**
     * @dev Gives max allowance to all pool rewards for the {uniRouter}.
     */
    function _givePoolAllowances() internal {
        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            IERC20 rewardToken = IERC20(
                poolRewardToWftmPaths[currentlyUsedPools[index]][0]
            );
            rewardToken.safeApprove(uniRouter, 0);
            rewardToken.safeApprove(uniRouter, type(uint256).max);
        }
    }

    /**
     * @dev Removes all allowance to all pool rewards for the {uniRouter}.
     */
    function _removePoolAllowances() internal {
        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            IERC20 rewardToken = IERC20(
                poolRewardToWftmPaths[currentlyUsedPools[index]][0]
            );
            rewardToken.safeApprove(uniRouter, 0);
        }
    }

    /**
     * @dev updates the {maxPoolDilutionFactor}
     */
    function updateMaxPoolDilutionFactor(uint256 _maxPoolDilutionFactor)
        external
    {
        _onlyStrategistOrOwner();
        require(_maxPoolDilutionFactor != 0, "!=0");
        maxPoolDilutionFactor = _maxPoolDilutionFactor;
    }

    /**
     * @dev updates the {maxNrOfPools}
     */
    function updateMaxNrOfPools(uint256 _maxNrOfPools) external {
        require(maxNrOfPools != 0, "!=0");
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        maxNrOfPools = _maxNrOfPools;
    }

    /**
     * @dev Adds a pool from the {aceLab} contract to be actively used to yield.
     * _poolRewardToWftmPath can be empty if the paths are standard rewardToken -> wftm
     */
    function addUsedPool(
        uint256 _poolId,
        address[] memory _poolRewardToWftmPath
    ) external {
        _onlyStrategistOrOwner();
        require(currentlyUsedPools.length < maxNrOfPools, "Max pools reached");
        require(
            _poolRewardToWftmPath.length >= 2 ||
                (_poolRewardToWftmPath.length == 1 &&
                    _poolRewardToWftmPath[0] == wftm),
            "Must have reward paths"
        );
        currentlyUsedPools.push(_poolId);
        poolRewardToWftmPaths[_poolId] = _poolRewardToWftmPath;

        address poolRewardToken = _poolRewardToWftmPath[0];
        if (poolRewardToken != wftm) {
            IERC20(poolRewardToken).safeApprove(uniRouter, type(uint256).max);
        }
    }

    /**
     * @dev Removes a pool that will no longer be used.
     */
    function removeUsedPool(uint256 _poolIndex) external {
        _onlyStrategistOrOwner();
        uint256 poolId = currentlyUsedPools[_poolIndex];
        IERC20(poolRewardToWftmPaths[poolId][0]).safeApprove(uniRouter, 0);
        uint256 balance = poolxTokenBalance[poolId];
        _aceLabWithdraw(poolId, balance);
        uint256 lastPoolIndex = currentlyUsedPools.length - 1;
        uint256 lastPoolId = currentlyUsedPools[lastPoolIndex];
        currentlyUsedPools[_poolIndex] = lastPoolId;
        currentlyUsedPools.pop();

        if (currentPoolId == poolId) {
            currentPoolId = currentlyUsedPools[0];
        }
        _aceLabDeposit(currentPoolId, balance);
    }
}
