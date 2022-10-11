// SPDX-License-Identifier: AGPLv3

pragma solidity 0.8.9;

import "./abstract/ReaperBaseStrategy.sol";
import "./interfaces/IAceLab.sol";
import "./interfaces/IBooMirrorWorld.sol";
import "./interfaces/IUniswapRouterETH.sol";
import "./interfaces/IMagicatsHandler.sol";
import "./interfaces/IExternalHandler.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "forge-std/Test.sol";

/**
 * @dev This is a strategy to stake Boo into XBOO, and then stake XBOO in different pools to collect more rewards
 * The strategy will compound the pool rewards into Boo which will be deposited into the strategy for more yield.
 */
contract ReaperAutoCompoundXBoov2 is ReaperBaseStrategyv3, IERC721ReceiverUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IBooMirrorWorld;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    /**
     * @dev Tokens Used:
     * {WFTM} - Required for liquidity routing when doing swaps. Also used to charge fees on yield.
     * {XBOO} - Token generated by staking our funds. Also used to stake in secondary pools.
     * {Boo} - Token that the strategy maximizes.
     */
    address public constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public constant USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    IBooMirrorWorld public constant XBOO = IBooMirrorWorld(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598); // XBOO
    IERC20Upgradeable public constant BOO = IERC20Upgradeable(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE); // BOO

    /**
     * @dev Third Party Contracts:
     * {UNIROUTER} - the UNIROUTER for target DEX
     * {MAGICATS} - NFT collection that improves staking rewards
     * {aceLab} - Address to AceLab, the SpookySwap contract to stake XBOO
     * {magicatsHandler} - NFT vault for magicats that allows for management + deposit/withdraw of magicatNFTs
     */
    address public constant UNIROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address public constant CURRENT_ACE_LAB = 0x399D73bB7c83a011cD85DF2a3CdF997ED3B3439f;
    address public constant MAGICATS = 0x2aB5C606a5AA2352f8072B9e2E8A213033e2c4c9;
    address public magicatsHandler;
    address public aceLab;
    //@audit remove constants, set values in initialize
    //@audit check setters for aceLab and Magicats

    /**
     * @dev Routes we take to swap tokens
     * {WFTMToBOOPath} - Route we take to get from {WFTM} into {BOO}.
     * {WFTMToUSDCPath} - Route we take to get from {WFTM} into {USDC}.
     * {poolRewardToWFTMPaths} - Routes for each pool to get from {pool reward token} into {WFTM}.
     */
    address[] public WFTMToBOOPath;
    address[] public WFTMToUSDCPath;
    mapping(uint256 => address[]) public poolRewardToWFTMPaths;

    /**
     * @dev Variables for pool selection
     * {currentPoolId} - Pool id for the the current pool the strategy deposits XBOO into
     */
    uint256 public currentPoolId;

    /**
     * @dev Variables for pool selection
     * {totalPoolBalance} - The total amount of XBOO currently deposited into pools
     * {poolXBOOBalance} - The amount of XBOO deposited into each pool
     */
    uint256 public totalPoolBalance;
    mapping(uint256 => uint256) public poolXBOOBalance;

    /***
     * {accCatDebt} - mapping of poolID -> accumulated catDebt between harvest. accounted for each time catDebt is reset (deposit/withdraw/harvest).
     * {catBOOstPercentage} - variable used in calculating rewards diverted to magicatsHandler, the raw percent the harvest was increased via magicats
     * {catProvisionFee} - amount of BOOsted harvest diverted to magicatsHandler
     */
    mapping(uint256 => uint256) public accCatDebt;
    uint256 public catBOOstPercentage; 
    uint256 public catProvisionFee; 

    //mapping of poolIds to a flag that specifies if the token requires special preperation to turn into WFTM (ex. xTaort)
    mapping(uint256 => bool) public requiresSpecialHandling;
    //mapping of poolIds to addresses of contracts to do external handling of tokens, these can be consolidated or one offs,
    //making this modular allows for all current and future possible rewards to be handled
    mapping(uint256 => address) public specialHandler;

    /**
     * @dev Fee variables
     * {useSecurityFee} - If security fee should be applied on withdraw, controlled by the fee moderator
     */
    bool public useSecurityFee; // remove, just set var to 0

    /**
     * {UpdatedStrategist} Event that is fired each time the strategist role is updated.
     */
    event UpdatedStrategist(address newStrategist);

    /**
     * @dev Initializes the strategy. Sets parameters, saves routes, and gives allowances.
     * @notice see documentation for each variable above its respective declaration.
     */
    // constructor(){}
    function initialize(
        address _vault,
        address[] memory _feeRemitters,
        address[] memory _strategists,
        address[] memory _multisigRoles
    ) public initializer {
        __ReaperBaseStrategy_init(_vault, _feeRemitters, _strategists, _multisigRoles);
        useSecurityFee = false;

        aceLab = CURRENT_ACE_LAB;
        currentPoolId = 5;
        totalPoolBalance = 0;
        WFTMToBOOPath = [WFTM, address(BOO)];
        WFTMToUSDCPath = [WFTM, USDC];
        catProvisionFee = 1500;

        _giveAllowances();
    }

    /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone deposits in the strategy's vault contract.
     * It deposits {BOO} into XBOO (BOOMirrorWorld) to farm {XBOO} and finally,
     * XBOO is deposited into other pools to earn additional rewards
     */
    function _deposit() internal override whenNotPaused {
        uint256 BOOBalance = BOO.balanceOf(address(this));
        if (BOOBalance != 0) {
            XBOO.enter(BOOBalance);
        }

        _aceLabDeposit(currentPoolId, XBOO.balanceOf(address(this)));
    }

    /**
     * @dev Function to deposit into AceLab while keeping internal accounting
     *      updated.
     */
    function _aceLabDeposit(uint256 _poolId, uint256 _XBOOAmount) internal {
        totalPoolBalance = totalPoolBalance.add(_XBOOAmount);
        poolXBOOBalance[_poolId] = poolXBOOBalance[_poolId].add(_XBOOAmount);
        _writeCatDebt(_poolId);
        IAceLab(aceLab).deposit(_poolId, _XBOOAmount);
    }

    /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {BOO} from the AceLab pools.
     * The available {BOO} minus fees is returned to the vault.
     */
    function _withdraw(uint256 _amount) internal override {
        uint256 BOOBalance = BOO.balanceOf(address(this));

        if (BOOBalance < _amount) {
            uint256 poolLength = IAceLab(aceLab).poolLength();

            uint256 withdrawPercentage = ((_amount - BOOBalance) * PERCENT_DIVISOR) / balanceOfPool();
            // remove as much as possible from pool before going to
            for (uint256 i = 0; i < poolLength; i++) {
                if (poolXBOOBalance[i] != 0) {
                    // seems overkill to have internal accounting to simply check != 0
                    _aceLabWithdraw(i, ((withdrawPercentage * poolXBOOBalance[i]) / PERCENT_DIVISOR));
                }
            }

            uint256 XBOOBalance = XBOO.balanceOf(address(this));
            XBOO.leave(XBOOBalance);
            BOOBalance = BOO.balanceOf(address(this));
        }

        if (BOOBalance > _amount) {
            BOOBalance = _amount;
        }

        BOO.safeTransfer(vault, BOOBalance);
    }

    /**
     * @dev Function to withdraw from AceLab while keeping internal accounting
     *      updated.
     */
    function _aceLabWithdraw(uint256 _poolId, uint256 _XBOOAmount) internal {
        totalPoolBalance = totalPoolBalance.sub(_XBOOAmount);
        poolXBOOBalance[_poolId] = poolXBOOBalance[_poolId].sub(_XBOOAmount);
        _writeCatDebt(_poolId);
        IAceLab(aceLab).withdraw(_poolId, _XBOOAmount);
    }

    /**
     * @dev Function to set Allocations of XBOO in acelab, called by Keepers or strategists to maintain maximal APR
     * {withdrawPoolIds} - Pool Ids that the strategy should reduce the balance of
     * {withdrawAmounts} - corresponding to the withdrawPoolIds, the amount those pIds should be reduced
     * {depositPoolIds} - Pool Ids that the strategy should increase the balance of
     * {depositAmounts} - corresponding to the depositPoolIds, the amount those pIds should be increased
     */
    function setXBooAllocations(
        uint256[] calldata withdrawPoolIds,
        uint256[] calldata withdrawAmounts,
        uint256[] calldata depositPoolIds,
        uint256[] calldata depositAmounts
    ) external {
        _atLeastRole(KEEPER);
        require(
            depositPoolIds.length == depositAmounts.length && withdrawPoolIds.length == withdrawAmounts.length,
            "pools not same length"
        );
        require(
            depositPoolIds.length <= IAceLab(aceLab).poolLength() &&
                withdrawPoolIds.length <= IAceLab(aceLab).poolLength(),
            "longer than poolLength"
        );

        // store numpools in local var and use unchecked inc
        for (uint256 i = 0; i < withdrawPoolIds.length; i++) {
            _aceLabWithdraw(withdrawPoolIds[i], withdrawAmounts[i]);
        }

        for (uint256 i = 0; i < depositPoolIds.length; i++) {
            uint256 XBOOAvailable = IERC20Upgradeable(XBOO).balanceOf(address(this));
            if (XBOOAvailable == 0) {
                return;
            }
            uint256 depositAmount = MathUpgradeable.min(XBOOAvailable, depositAmounts[i]);
            _aceLabDeposit(depositPoolIds[i], depositAmount);
        }
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     * 1. It claims rewards from the AceLab pools and estimated the current yield for each pool.
     * 2. It charges the system fees to simplify the split.
     * 3. It swaps the {WFTM} token for {BOO} which is deposited into {XBOO}
     * 4. It distributes the XBOO using a yield optimization algorithm into various pools.
     */
    function _harvestCore() internal override returns (uint256 callerFee) {
        _claimAllRewards();
        catBOOstPercentage = _processRewards();
        console.log("returned catBOOstPercentage was %s", catBOOstPercentage);
        callerFee = _chargeFees();
        _swapWFTMToBOO();
        _payMagicatDepositors(catBOOstPercentage);
        _enterXBOO();
        _aceLabDeposit(currentPoolId, XBOO.balanceOf(address(this)));
        if(magicatsHandler != address(0) && catBOOstPercentage != 0){
            IMagicatsHandler(magicatsHandler).processRewards();
        }
    }

    function _claimAllRewards() internal {
        uint256 poolLength = IAceLab(aceLab).poolLength(); // enumerableset of poolIDs deposited in?
        uint256 pending;
        for (uint256 i = 0; i < poolLength; i++) {
            (pending, ) = IAceLab(aceLab).pendingRewards(i, address(this));
            if (pending != 0) {
                _aceLabWithdraw(i, 0);
            }
        }
    }

    /**
     * @notice Converts all reward tokens in WFTM and calculates the XBOO % that
     *         was BOOsted by the cats.
     */
    function _processRewards() internal returns (uint256) {
        uint256 poolLength = IAceLab(aceLab).poolLength();
        uint256 tokenBal;
        address _handler;
        uint256 WFTMBalBefore;
        uint256 WFTMBalAfter;
        uint256 catBoostPercent;
        uint256 catBoostWFTM;
        uint256 catBoostTotal;
        uint256 totalHarvest;
        address rewardToken;
        for (uint256 i = 0; i < poolLength; i++) {
            rewardToken = address(IAceLab(aceLab).poolInfo(i).RewardToken);
            tokenBal = IERC20Upgradeable(rewardToken).balanceOf(address(this));
            if (tokenBal != 0) {
                WFTMBalBefore = IERC20Upgradeable(WFTM).balanceOf(address(this));

                //leave is pretty standard for xTokens if it does not have leave we will need an external handler
                try IBooMirrorWorld(rewardToken).leave(tokenBal) {} catch {}

                if (accCatDebt[i] != 0) {
                    catBoostPercent = (accCatDebt[i] * PERCENT_DIVISOR) / tokenBal;
                } else {
                    catBoostPercent = 0;
                }

                _handler = _requireExternalHandling(i);
                if (_handler == address(this)) {
                    _swapRewardToWFTM(i);
                } else if (_handler != address(this) && _handler != address(0)) {
                    IERC20Upgradeable(rewardToken).approve(_handler, tokenBal);
                    //external call to handler
                }

                WFTMBalAfter = IERC20Upgradeable(WFTM).balanceOf(address(this));
                totalHarvest += (WFTMBalAfter - WFTMBalBefore);
                catBoostWFTM = ((WFTMBalAfter - WFTMBalBefore) * catBoostPercent) / PERCENT_DIVISOR;
                catBoostTotal += catBoostWFTM;
                accCatDebt[i] = 0;
            }
        }

        if (catBoostTotal == 0) {
            return 0;
        }
        return ((catBoostTotal * PERCENT_DIVISOR) / totalHarvest);
    }

    /**
     * @dev Swaps any pool reward token to WFTM
     */
    function _swapRewardToWFTM(uint256 _poolId) internal {
        address[] memory rewardToWFTMPath = poolRewardToWFTMPaths[_poolId];
        address rewardToken = rewardToWFTMPath[0];
        uint256 poolRewardTokenBal = IERC20Upgradeable(rewardToken).balanceOf(address(this));
        if (poolRewardTokenBal != 0 && rewardToken != WFTM) {
            IERC20Upgradeable(rewardToken).safeApprove(UNIROUTER, poolRewardTokenBal);
            IUniswapRouterETH(UNIROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                poolRewardTokenBal,
                0,
                rewardToWFTMPath,
                address(this),
                block.timestamp
            );
        }
    }

    /**
     * @dev Takes out fees from the rewards. Set by constructor
     * callFeeToUser is set as a percentage of the fee,
     * as is treasuryFeeToVault
     */
    function _chargeFees() internal returns (uint256 callFeeToUser) {
        uint256 WFTMFee = IERC20Upgradeable(WFTM).balanceOf(address(this)).mul(totalFee).div(PERCENT_DIVISOR);
        // charge in stable

        if (WFTMFee != 0) {
           IUniswapRouterETH(UNIROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                WFTMFee,
                0,
                WFTMToUSDCPath,
                address(this),
                block.timestamp
            );
            uint256 USDCBal = IERC20Upgradeable(USDC).balanceOf(address(this));
            callFeeToUser = USDCBal.mul(callFee).div(PERCENT_DIVISOR);
            uint256 treasuryFeeToVault = USDCBal.mul(treasuryFee).div(PERCENT_DIVISOR);

            IERC20Upgradeable(USDC).safeTransfer(msg.sender, callFeeToUser);
            IERC20Upgradeable(USDC).safeTransfer(treasury, treasuryFeeToVault);
        }
    }

    /**
     * @dev Swaps all {WFTM} into {BOO}
     */
    function _swapWFTMToBOO() internal {
        uint256 WFTMBalance = IERC20Upgradeable(WFTM).balanceOf(address(this));
        if (WFTMBalance != 0) {
            IUniswapRouterETH(UNIROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                WFTMBalance,
                0,
                WFTMToBOOPath,
                address(this),
                block.timestamp
            );
        }
    }

    function _enterXBOO() internal {
        uint256 BOOBalance = BOO.balanceOf(address(this));
        XBOO.enter(BOOBalance);
    }

    function _payMagicatDepositors(uint256 percentage) internal {
        uint256 BOOBalance = BOO.balanceOf(address(this));
        uint256 magicatsCut = (BOOBalance * percentage) / PERCENT_DIVISOR;
        uint256 magicatPayout = (magicatsCut * catProvisionFee) / PERCENT_DIVISOR;
        IERC20Upgradeable(BOO).transfer(magicatsHandler, magicatPayout);
    }

    function _writeCatDebt(uint256 _poolId) internal {
        (, uint256 catReward) = IAceLab(aceLab).pendingRewards(_poolId, address(this));
        accCatDebt[_poolId] += catReward;
    }

    /**
     * @dev Function to calculate the total underlaying {BOO} held by the strat.
     * It takes into account both the funds in hand, as the funds allocated in XBOO and the AceLab pools.
     */
    function balanceOf() public view override returns (uint256) {
        return balanceOfBOO() + balanceOfXBOO() + balanceOfPool();
    }

    /**
     * @dev It calculates how much {BOO} the contract holds.
     */
    function balanceOfBOO() public view returns (uint256) {
        return BOO.balanceOf(address(this));
    }

    /**
     * @dev It calculates how much {BOO} the contract has staked as XBOO.
     */
    function balanceOfXBOO() public view returns (uint256) {
        return XBOO.BOOBalance(address(this));
    }

    /**
     * @dev It calculates how much {BOO} the strategy has allocated in the AceLab pools
     */
    function balanceOfPool() public view returns (uint256) {
        return XBOO.xBOOForBOO(totalPoolBalance);
    }

    /**
     * @dev Pauses deposits. Withdraws all funds from the AceLab contract, leaving rewards behind.
     */
    function _reclaimWant() internal override {
        for (uint256 index = 0; index < IAceLab(aceLab).poolLength(); index++) {
            (uint256 amount, , , ) = IAceLab(aceLab).userInfo(index, address(this));
            if (amount != 0) {
                IAceLab(aceLab).emergencyWithdraw(index);
            }
        }
        totalPoolBalance = IAceLab(aceLab).balanceOf(address(this));
        uint256 XBOOBalance = XBOO.balanceOf(address(this));
        XBOO.leave(XBOOBalance);

        // uint256 BOOBalance = BOO.balanceOf(address(this));
        // BOO.transfer(vault, BOOBalance);
    }

    /**
     * @dev Pauses the strat.
     */
    function pause() public override {
        _atLeastRole(GUARDIAN);
        _pause();
        _removeAllowances();
    }

    /**
     * @dev Unpauses the strat.
     */
    function unpause() public override {
        _atLeastRole(ADMIN);
        _giveAllowances();
        _unpause();
        deposit();
    }

    /**
     * @dev Gives max allowance of {BOO} for the {XBOO} contract,
     * {XBOO} allowance for the {aceLab} contract,
     * {WFTM} allowance for the {UNIROUTER}
     * in addition to allowance to all pool rewards for the {UNIROUTER}.
     */
    function _giveAllowances() internal {
        // Give XBOO permission to use BOO
        BOO.safeApprove(address(XBOO), 0);
        BOO.safeApprove(address(XBOO), type(uint256).max);
        // Give XBOO contract permission to stake XBOO
        XBOO.safeApprove(aceLab, 0);
        XBOO.safeApprove(aceLab, type(uint256).max);
        // Give UNIROUTER permission to swap WFTM to BOO
        IERC20Upgradeable(WFTM).safeApprove(UNIROUTER, 0);
        IERC20Upgradeable(WFTM).safeApprove(UNIROUTER, type(uint256).max);

        _approveMagicatsFor(aceLab);
    }

    /**
     * @dev Removes all allowance of {BOO} for the {XBOO} contract,
     * {XBOO} allowance for the {aceLab} contract,
     * {WFTM} allowance for the {UNIROUTER}
     * in addition to allowance to all pool rewards for the {UNIROUTER}.
     */
    function _removeAllowances() internal {
        // Remove XBOO permission to use BOO
        BOO.safeApprove(address(XBOO), 0);
        // Remove XBOO contract permission to stake XBOO
        XBOO.safeApprove(aceLab, 0);
        // Remove UNIROUTER permission to swap WFTM to BOO
        IERC20Upgradeable(WFTM).safeApprove(UNIROUTER, 0);
    }

    function _approveMagicatsFor(address operator) internal {
        IERC721Upgradeable(MAGICATS).setApprovalForAll(operator, true);
    }

    function updateMagicats(
        uint256 poolID,
        uint256[] memory IDsToStake,
        uint256[] memory IDsToUnstake
    ) external {
        //needs to be secured, called by the handler contract
        _atLeastRole(MAGICATS_HANDLER);
        if (IDsToStake.length > 0) {
            IAceLab(aceLab).deposit(poolID, 0, IDsToStake);
        }

        if (IDsToUnstake.length > 0) {
            IAceLab(aceLab).withdraw(poolID, 0, IDsToUnstake);
        }
    }

    function updateMagicatsHandler(address handler) external {
        _atLeastRole(STRATEGIST);
        IERC721Upgradeable(MAGICATS).setApprovalForAll(magicatsHandler, false);
        if (magicatsHandler != address(0)) {
            revokeRole(MAGICATS_HANDLER, magicatsHandler);
        }
        grantRole(MAGICATS_HANDLER, handler);
        magicatsHandler = handler;
        _approveMagicatsFor(magicatsHandler);
    }

    function _requireExternalHandling(uint256 pid) internal view returns (address) {
        if (requiresSpecialHandling[pid] == true) {
            return specialHandler[pid];
        } else {
            return address(this);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function retireStrat() external {}

    function updateCatProvisionFee(uint256 _fee) external {
        _atLeastRole(STRATEGIST);
        catProvisionFee = _fee;
    }

    function setRoute(uint256 poolId, address[] calldata routes) external {
        _atLeastRole(STRATEGIST);
        poolRewardToWFTMPaths[poolId] = routes;
    }
}
