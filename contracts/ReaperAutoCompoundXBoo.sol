// SPDX-License-Identifier: MIT

import "./abstract/Ownable.sol";
import "./abstract/Pausable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAceLab.sol";
import "./interfaces/IBooMirrorWorld.sol";
import "./interfaces/IUniswapRouterETH.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";

// import "hardhat/console.sol";

pragma solidity 0.8.9;

/**
 * @dev Implementation of a strategy to get yields from farming LP Pools in SpookySwap.
 * SpookySwap is an automated market maker (“AMM”) that allows two tokens to be exchanged on Fantom's Opera Network.
 *
 * This strategy deposits whatever funds it receives from the vault into the selected masterChef pool.
 * rewards from providing liquidity are farmed every few minutes, sold and split 50/50.
 * The corresponding pair of assets are bought and more liquidity is added to the masterChef pool.
 *
 * Expect the amount of LP tokens you have to grow over time while you have assets deposit
 */
contract ReaperAutoCompoundXBoo is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /**
     * @dev Tokens Used:
     * {wftm} - Required for liquidity routing when doing swaps.
     * {xBoo} - Token generated by staking our funds.
     * {boo} - LP Token that the strategy maximizes.
     */
    address public wftm = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    address public xBoo;
    address public boo;

    /**
     * @dev Third Party Contracts:
     * {uniRouter} - the uniRouter for target DEX
     * {aceLabAddress} - Address to AceLab
     * {aceLab} - The AceLab contract
     * {currentPoolId} - the currently selected AceLab pool id
     */
    address public uniRouter;
    address public aceLabAddress;
    IAceLab public aceLab;
    uint8 public currentPoolId;

    /**
     * @dev Reaper Contracts:
     * {treasury} - Address of the Reaper treasury
     * {vault} - Address of the vault that controls the strategy's funds.
     */
    address public treasury;
    address public vault;

    // /**
    //  * @dev Contract roles:
    //  * {strategist} - Address of the strategist responsible for updating strategy related variables
    //  */
    // address public strategist;

    /**
     * @dev Distribution of fees earned. This allocations relative to the % implemented on
     * Current implementation separates 5% for fees. Can be changed through the constructor
     * Inputs in constructor should be ratios between the Fee and Max Fee, divisble into percents by 10000
     *
     * {callFee} - Percent of the totalFee reserved for the harvester (1000 = 10% of total fee: 0.5% by default)
     * {treasuryFee} - Percent of the totalFee taken by maintainers of the software (9000 = 90% of total fee: 4.5% by default)
     * {securityFee} - Fee taxed when a user withdraws funds. Taken to prevent flash deposit/harvest attacks.
     * These funds are redistributed to stakers in the pool.
     *
     * {totalFee} - divided by 10,000 to determine the % fee. Set to 5% by default and
     * lowered as necessary to provide users with the most competitive APY.
     *
     * {MAX_FEE} - Maximum fee allowed by the strategy. Hard-capped at 5%.
     * {PERCENT_DIVISOR} - Constant used to safely calculate the correct percentages.
     */

    uint256 public callFee = 1000;
    uint256 public treasuryFee = 9000;
    uint256 public securityFee = 10;
    uint256 public totalFee = 450;
    uint256 public constant MAX_FEE = 500;
    uint256 public constant PERCENT_DIVISOR = 10000;

    /**
     * @dev Routes we take to swap tokens
     * {wftmToBooRoute} - Route we take to get from {wftm} into {boo}.
     * {poolTokenToWftmRoute} - Route we take to get from {pool reward token} into {wftm}.
     */
    address[] public wftmToBooRoute;

    uint8[] public currentlyUsedPools;
    mapping(uint8 => uint256) public poolYield;
    mapping(uint8 => bool) public hasAllocatedToPool;
    mapping(uint8 => address[]) public poolRewardToWftmPaths;
    mapping(uint8 => uint256) public poolxBooBalance;
    uint8 private constant WFTM_POOL_ID = 2;
    uint256 public totalPoolBalance = 0;
    uint8 public maxPoolDilutionFactor = 5;

    /**
     * {StratHarvest} Event that is fired each time someone harvests the strat.
     * {TotalFeeUpdated} Event that is fired each time the total fee is updated.
     * {CallFeeUpdated} Event that is fired each time the call fee is updated.
     */
    event StratHarvest(address indexed harvester);
    event TotalFeeUpdated(uint256 newFee);
    event CallFeeUpdated(uint256 newCallFee, uint256 newTreasuryFee);

    // event StrategistUpdated(address newStrategist);
    // event PoolAdded(uint8 poolId);
    // event PoolRemoved(uint8 poolId);

    /**
     * @dev Initializes the strategy. Sets parameters, saves routes, and gives allowances.
     * @notice see documentation for each variable above its respective declaration.
     */
    constructor(
        address _uniRouter,
        address _aceLabAddress,
        address _rewardToken,
        address _xBoo,
        address _vault,
        address _treasury
    ) public {
        uniRouter = _uniRouter;
        aceLabAddress = _aceLabAddress;
        aceLab = IAceLab(aceLabAddress);
        boo = _rewardToken;
        xBoo = _xBoo;
        vault = _vault;
        treasury = _treasury;
        wftmToBooRoute = [wftm, boo];
        currentPoolId = WFTM_POOL_ID;

        giveAllowances();
    }

    /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone deposits in the strategy's vault contract.
     * It deposits {boo} into xBoo (BooMirrorWorld) to farm {xBoo}
     */
    function deposit() public whenNotPaused {
        // console.log("deposit()");
        uint256 booBalance = IERC20(boo).balanceOf(address(this));

        if (booBalance > 0) {
            IBooMirrorWorld(xBoo).enter(booBalance);
            // console.log(".enter(booBalance): ", booBalance);
            uint256 xBooBalance = IERC20(xBoo).balanceOf(address(this));
            aceLab.deposit(currentPoolId, xBooBalance);
            // console.log("currentPoolId: ", currentPoolId);
            // console.log(
            //     ".deposit(currentPoolId, xBooBalance): ",
            //     xBooBalance
            // );
            totalPoolBalance = totalPoolBalance.add(xBooBalance);
            poolxBooBalance[currentPoolId] = poolxBooBalance[currentPoolId].add(
                xBooBalance
            );
        }
    }

    /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {boo} from the masterChef.
     * The available {boo} minus fees is returned to the vault.
     */
    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 booBalance = IERC20(boo).balanceOf(address(this));

        if (booBalance < _amount) {
            for (
                uint256 index = 0;
                index < currentlyUsedPools.length;
                index++
            ) {
                uint8 poolId = currentlyUsedPools[index];
                uint256 currentPoolxBooBalance = poolxBooBalance[poolId];
                if (currentPoolxBooBalance > 0) {
                    uint256 remainingBooAmount = _amount - booBalance;
                    uint256 remainingxBooAmount = IBooMirrorWorld(xBoo)
                        .BOOForxBOO(remainingBooAmount);
                    uint256 withdrawAmount;
                    if (remainingxBooAmount > currentPoolxBooBalance) {
                        withdrawAmount = currentPoolxBooBalance;
                    } else {
                        withdrawAmount = remainingxBooAmount;
                    }
                    aceLab.withdraw(poolId, withdrawAmount);
                    totalPoolBalance = totalPoolBalance.sub(withdrawAmount);
                    poolxBooBalance[poolId] = poolxBooBalance[poolId].sub(
                        withdrawAmount
                    );
                    uint256 xBooBalance = IERC20(xBoo).balanceOf(address(this));
                    IBooMirrorWorld(xBoo).leave(xBooBalance);
                    booBalance = IERC20(boo).balanceOf(address(this));
                    if (booBalance >= _amount) {
                        break;
                    }
                }
            }
        }

        if (booBalance > _amount) {
            booBalance = _amount;
        }
        uint256 withdrawFee = booBalance.mul(securityFee).div(PERCENT_DIVISOR);
        IERC20(boo).safeTransfer(vault, booBalance.sub(withdrawFee));
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     * 1. It claims rewards from the masterChef.
     * 2. It charges the system fees to simplify the split.
     * 3. It swaps the {boo} token for {lpToken0} & {lpToken1}
     * 4. Adds more liquidity to the pool.
     * 5. It deposits the new LP tokens.
     */
    function harvest() external whenNotPaused {
        // console.log("harvest()");
        require(!Address.isContract(msg.sender), "!contract");
        _collectRewardsAndEstimateYield();
        _chargeFees();
        _compoundRewards();
        _rebalance();
        emit StratHarvest(msg.sender);
    }

    function _collectRewardsAndEstimateYield() internal {
        // console.log("_collectRewardsAndEstimateYield()");
        uint256 nrOfUsedPools = currentlyUsedPools.length;
        for (uint256 index = 0; index < nrOfUsedPools; index++) {
            uint8 poolId = currentlyUsedPools[index];
            // console.log("poolId: ", poolId);
            // uint256 pendingReward = aceLab.pendingReward(poolId, address(this));
            uint256 currentPoolxBooBalance = poolxBooBalance[poolId];
            // console.log("pendingReward: ", pendingReward);
            // console.log("currentPoolxBooBalance: ", currentPoolxBooBalance);
            aceLab.withdraw(poolId, currentPoolxBooBalance);
            totalPoolBalance = totalPoolBalance.sub(currentPoolxBooBalance);
            poolxBooBalance[poolId] = 0;
            _swapRewardToWftm(poolId);
            _setEstimatedYield(poolId);
            hasAllocatedToPool[poolId] = false;
        }
    }

    function _swapRewardToWftm(uint8 _poolId) internal {
        // console.log("_swapRewardToWftm()");
        address[] memory rewardToWftmPaths = poolRewardToWftmPaths[_poolId];
        IAceLab.PoolInfo memory poolInfo = aceLab.poolInfo(_poolId);
        uint256 poolRewardTokenBal = poolInfo.RewardToken.balanceOf(
            address(this)
        );
        if (poolRewardTokenBal > 0 && address(poolInfo.RewardToken) != wftm) {
            // Default to support empty or incomplete path array
            if (rewardToWftmPaths.length < 2) {
                rewardToWftmPaths = new address[](2);
                rewardToWftmPaths[0] = address(poolInfo.RewardToken);
                rewardToWftmPaths[1] = wftm;
            }
            // console.log("Paths: ");
            // console.log(rewardToWftmPaths[0]);
            // console.log(rewardToWftmPaths[1]);
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

    function _setEstimatedYield(uint8 _poolId) internal {
        // console.log("_setEstimatedYield()");
        IAceLab.PoolInfo memory poolInfo = aceLab.poolInfo(_poolId);
        uint256 multiplier = _getMultiplier(
            block.timestamp,
            block.timestamp + 1 days,
            poolInfo
        );
        // console.log("---------------------------------");
        // console.log("RewardToken: ", address(pool.RewardToken));
        // console.log("RewardsPerSecond: ", pool.RewardPerSecond);
        // console.log("multiplier: ", multiplier);
        uint256 totalTokens = multiplier * poolInfo.RewardPerSecond;
        // console.log(IERC20Metadata(address(poolInfo.RewardToken)).symbol());
        // console.log("_poolId: ", _poolId);
        // console.log("multiplier: ", multiplier);
        // console.log("poolInfo.RewardPerSecond: ", poolInfo.RewardPerSecond);

        if (address(poolInfo.RewardToken) == wftm) {
            // console.log("is wftm");
            uint256 wftmYield = (1 ether * totalTokens) /
                poolInfo.xBooStakedAmount;
            // console.log("WFTM: ", wftmYield);
            poolYield[_poolId] = wftmYield;
        } else {
            if (totalTokens == 0) {
                poolYield[_poolId] = 0;
            } else {
                address[] memory path = new address[](2);
                path[0] = address(poolInfo.RewardToken);
                path[1] = wftm;
                // console.log("totalTokens: ", totalTokens);
                uint256 wftmTotalPoolYield = IUniswapRouterETH(uniRouter)
                    .getAmountsOut(totalTokens, path)[1];
                uint256 wftmYield = (1 ether * wftmTotalPoolYield) /
                    poolInfo.xBooStakedAmount;
                // console.log(
                //     IERC20Metadata(address(poolInfo.RewardToken)).symbol(),
                //     ": ",
                //     wftmYield
                // );
                poolYield[_poolId] = wftmYield;
            }
        }
    }

    /**
     * @dev Takes out fees from the rewards. Set by constructor
     * callFeeToUser is set as a percentage of the fee,
     * as is treasuryFeeToVault
     */
    function _chargeFees() internal {
        // console.log("_chargeFees()");
        if (totalFee != 0) {
            uint256 wftmBalance = IERC20(wftm).balanceOf(address(this));
            uint256 wftmFee = wftmBalance.mul(totalFee).div(PERCENT_DIVISOR);

            uint256 callFeeToUser = wftmFee.mul(callFee).div(PERCENT_DIVISOR);
            IERC20(wftm).safeTransfer(msg.sender, callFeeToUser);

            uint256 treasuryFeeToVault = wftmFee.mul(treasuryFee).div(
                PERCENT_DIVISOR
            );
            IERC20(wftm).safeTransfer(treasury, treasuryFeeToVault);
        }
    }

    function _compoundRewards() internal {
        // console.log("_compoundRewards()");
        uint256 wftmBalance = IERC20(wftm).balanceOf(address(this));
        // console.log("wftmBalance: ", wftmBalance);
        if (wftmBalance > 0) {
            IUniswapRouterETH(uniRouter)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    wftmBalance,
                    0,
                    wftmToBooRoute,
                    address(this),
                    block.timestamp.add(600)
                );
            uint256 booBalance = IERC20(boo).balanceOf(address(this));
            IBooMirrorWorld(xBoo).enter(booBalance);
        }
    }

    function _rebalance() internal {
        // console.log("rebalance()");
        uint256 xBooBalance = IERC20(xBoo).balanceOf(address(this));
        while (xBooBalance > 0) {
            uint256 bestYield = 0;
            uint8 bestYieldPoolId = WFTM_POOL_ID;
            uint256 bestYieldIndex = 0;
            for (
                uint256 index = 0;
                index < currentlyUsedPools.length;
                index++
            ) {
                uint8 poolId = currentlyUsedPools[index];
                if (hasAllocatedToPool[poolId] == false) {
                    uint256 currentPoolYield = poolYield[poolId];
                    if (currentPoolYield >= bestYield) {
                        bestYield = currentPoolYield;
                        bestYieldPoolId = poolId;
                        bestYieldIndex = index;
                    }
                }
            }
            uint256 poolDepositAmount = xBooBalance;
            IAceLab.PoolInfo memory poolInfo = aceLab.poolInfo(bestYieldPoolId);
            bool isNotWFTM = address(poolInfo.RewardToken) != wftm;
            // console.log("isNotWFTM: ", isNotWFTM);
            // console.log("poolDepositAmount: ", poolDepositAmount);
            // console.log(
            //     "poolInfo.xBooStakedAmount / maxPoolDilutionFactor: ",
            //     poolInfo.xBooStakedAmount / maxPoolDilutionFactor
            // );
            // console.log(
            //     "isNotWFTM && poolDepositAmount > (poolInfo.xBooStakedAmount / maxPoolDilutionFactor): ",
            //     isNotWFTM &&
            //         poolDepositAmount >
            //         (poolInfo.xBooStakedAmount / maxPoolDilutionFactor)
            // );
            if (
                isNotWFTM &&
                poolDepositAmount >
                (poolInfo.xBooStakedAmount / maxPoolDilutionFactor)
            ) {
                poolDepositAmount =
                    poolInfo.xBooStakedAmount /
                    maxPoolDilutionFactor;
            }
            // console.log("aceLab.deposit: ", poolDepositAmount);
            // console.log("into pool: ", bestYieldPoolId);
            aceLab.deposit(bestYieldPoolId, poolDepositAmount);
            totalPoolBalance = totalPoolBalance.add(poolDepositAmount);
            poolxBooBalance[bestYieldPoolId] = poolxBooBalance[bestYieldPoolId]
                .add(poolDepositAmount);
            hasAllocatedToPool[bestYieldPoolId] = true;
            xBooBalance = IERC20(xBoo).balanceOf(address(this));
            currentPoolId = bestYieldPoolId;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function _getMultiplier(
        uint256 _from,
        uint256 _to,
        IAceLab.PoolInfo memory pool
    ) internal pure returns (uint256) {
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
     * @dev Function to calculate the total underlaying {boo} held by the strat.
     * It takes into account both the funds in hand, as the funds allocated in the masterChef.
     */
    function balanceOf() public view returns (uint256) {
        // console.log("balanceOf()");
        // console.log("balanceOfBoo(): ", balanceOfBoo());
        // console.log("balanceOfxBoo(): ", balanceOfxBoo());
        // console.log("balanceOfPool(): ", balanceOfPool());
        uint256 balance = balanceOfBoo().add(
            balanceOfxBoo().add(balanceOfPool())
        );
        // console.log(balance);
        return balance;
    }

    /**
     * @dev It calculates how much {boo} the contract holds.
     */
    function balanceOfBoo() public view returns (uint256) {
        return IERC20(boo).balanceOf(address(this));
    }

    /**
     * @dev It calculates how much {boo} the contract has staked.
     */
    function balanceOfxBoo() public view returns (uint256) {
        return IBooMirrorWorld(xBoo).BOOBalance(address(this));
    }

    /**
     * @dev It calculates how much {boo} the strategy has allocated in the AceLab pools
     */
    function balanceOfPool() public view returns (uint256) {
        return IBooMirrorWorld(xBoo).xBOOForBOO(totalPoolBalance);
    }

    /**
     * @dev Function that has to be called as part of strat migration. It sends all the available funds back to the
     * vault, ready to be migrated to the new strat.
     */
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            uint8 poolId = currentlyUsedPools[index];
            uint256 balance = poolxBooBalance[poolId];
            aceLab.withdraw(poolId, balance);
            _swapRewardToWftm(poolId);
        }

        _compoundRewards();

        uint256 xBooBalance = IERC20(xBoo).balanceOf(address(this));
        IBooMirrorWorld(xBoo).leave(xBooBalance);

        uint256 booBalance = IERC20(boo).balanceOf(address(this));
        IERC20(boo).transfer(vault, booBalance);
    }

    /**
     * @dev Pauses deposits. Withdraws all funds from the AceLab contract, leaving rewards behind
     */
    function panic() public onlyOwner {
        pause();
        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            uint8 poolId = currentlyUsedPools[index];
            aceLab.emergencyWithdraw(poolId);
        }
        uint256 xBooBalance = IERC20(xBoo).balanceOf(address(this));
        IBooMirrorWorld(xBoo).leave(xBooBalance);

        uint256 booBalance = IERC20(boo).balanceOf(address(this));
        IERC20(boo).transfer(vault, booBalance);
    }

    /**
     * @dev Pauses the strat.
     */
    function pause() public onlyOwner {
        _pause();
        removeAllowances();
    }

    /**
     * @dev Unpauses the strat.
     */
    function unpause() external onlyOwner {
        _unpause();

        giveAllowances();

        deposit();
    }

    function giveAllowances() internal {
        // Give xBOO permission to use Boo
        IERC20(boo).safeApprove(xBoo, 0);
        IERC20(boo).safeApprove(xBoo, type(uint256).max);
        // Give xBoo contract permission to stake xBoo
        IERC20(xBoo).safeApprove(aceLabAddress, 0);
        IERC20(xBoo).safeApprove(aceLabAddress, type(uint256).max);
        // Give uniRouter permission to swap wftm to boo
        IERC20(wftm).safeApprove(uniRouter, 0);
        IERC20(wftm).safeApprove(uniRouter, type(uint256).max);
        _givePoolAllowances();
    }

    function removeAllowances() internal {
        // Give xBOO permission to use Boo
        IERC20(boo).safeApprove(xBoo, 0);
        // Give xBoo contract permission to stake xBoo
        IERC20(xBoo).safeApprove(aceLabAddress, 0);
        // Give uniRouter permission to swap wftm to boo
        IERC20(wftm).safeApprove(uniRouter, 0);
        _removePoolAllowances();
    }

    function _givePoolAllowances() internal {
        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            uint8 poolId = currentlyUsedPools[index];
            IAceLab.PoolInfo memory poolInfo = aceLab.poolInfo(poolId);
            poolInfo.RewardToken.safeApprove(uniRouter, 0);
            poolInfo.RewardToken.safeApprove(uniRouter, type(uint256).max);
        }
    }

    function _removePoolAllowances() internal {
        for (uint256 index = 0; index < currentlyUsedPools.length; index++) {
            uint8 poolId = currentlyUsedPools[index];
            IAceLab.PoolInfo memory poolInfo = aceLab.poolInfo(poolId);
            poolInfo.RewardToken.safeApprove(uniRouter, 0);
        }
    }

    /**
     * @dev updates the total fee, capped at 5%
     */
    function updateTotalFee(uint256 _totalFee)
        external
        onlyOwner
        returns (bool)
    {
        require(_totalFee <= MAX_FEE, "Fee Too High");
        totalFee = _totalFee;
        emit TotalFeeUpdated(totalFee);
        return true;
    }

    /**
     * @dev updates the call fee and adjusts the treasury fee to cover the difference
     */
    function updateCallFee(uint256 _callFee) external onlyOwner returns (bool) {
        callFee = _callFee;
        treasuryFee = PERCENT_DIVISOR.sub(callFee);
        emit CallFeeUpdated(callFee, treasuryFee);
        return true;
    }

    function updateTreasury(address newTreasury)
        external
        onlyOwner
        returns (bool)
    {
        treasury = newTreasury;
        return true;
    }

    function updateMaxPoolDilutionFactor(uint8 _maxPoolDilutionFactor)
        external
        onlyOwner
    {
        // _onlyAuthorized();
        require(_maxPoolDilutionFactor > 0, "Must be a positive number");
        maxPoolDilutionFactor = _maxPoolDilutionFactor;
    }

    // function _onlyAuthorized() internal view {
    //     require(
    //         msg.sender == strategist || msg.sender == owner(),
    //         "Not authorized"
    //     );
    // }

    // /**
    //  * @notice
    //  *  Used to change `strategist`.
    //  *
    //  *  This may only be called by governance or the existing strategist.
    //  * @param _strategist The new address to assign as `strategist`.
    //  */
    // function setStrategist(address _strategist) external {
    //     _onlyAuthorized();
    //     require(_strategist != address(0), "Cant use the 0 address");
    //     strategist = _strategist;
    //     emit StrategistUpdated(strategist);
    // }

    function addUsedPool(uint8 _poolId, address[] memory _poolRewardToWftmPaths)
        external
        onlyOwner
    {
        // _onlyAuthorized();
        currentlyUsedPools.push(_poolId);
        poolRewardToWftmPaths[_poolId] = _poolRewardToWftmPaths;
        address poolRewardToken;
        if (_poolRewardToWftmPaths.length > 0) {
            poolRewardToken = _poolRewardToWftmPaths[0];
        } else {
            IAceLab.PoolInfo memory poolInfo = aceLab.poolInfo(_poolId);
            poolRewardToken = address(poolInfo.RewardToken);
        }
        if (poolRewardToken != wftm) {
            IERC20(poolRewardToken).safeApprove(uniRouter, type(uint256).max);
        }
        // emit PoolAdded(_poolId);
    }

    // function removeUsedPool(uint8 _poolIndex) external onlyOwner {
    //     // _onlyAuthorized();
    //     uint8 poolId = currentlyUsedPools[_poolIndex];
    //     IAceLab.PoolInfo memory poolInfo = aceLab.poolInfo(poolId);
    //     poolInfo.RewardToken.safeApprove(uniRouter, 0);
    //     uint256 balance = poolxBooBalance[poolId];
    //     aceLab.withdraw(poolId, balance);
    //     totalPoolBalance = totalPoolBalance.sub(balance);
    //     poolxBooBalance[poolId] = 0;
    //     uint256 lastPoolIndex = currentlyUsedPools.length - 1;
    //     uint8 lastPoolId = currentlyUsedPools[lastPoolIndex];
    //     currentlyUsedPools[_poolIndex] = lastPoolId;
    //     currentlyUsedPools.pop();
    //     // emit PoolRemoved(poolId);
    // }
}
