// SPDX-License-Identifier: AGPLv3

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/IMagicats.sol";
import "./interfaces/IAceLab.sol";
import "./interfaces/IBooMirrorWorld.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IVault.sol";

import "forge-std/Test.sol";

contract MagicatsHandler is AccessControlEnumerable, ERC721Enumerable {

    bytes32 public constant KEEPER = keccak256("KEEPER");
    bytes32 public constant STRATEGIST = keccak256("STRATEGIST");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32[] private cascadingAccess;

    address aceLab = 0x399D73bB7c83a011cD85DF2a3CdF997ED3B3439f;
    address public constant Magicats = 0x2aB5C606a5AA2352f8072B9e2E8A213033e2c4c9;
    IBooMirrorWorld public constant xBoo =
        IBooMirrorWorld(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598); // xBoo
    IERC20 public constant Boo =
        IERC20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE); // Boo

    address public immutable vault;
    /***
     * @dev Struct used for internal accounting of deposited Magicats
     * {magicatId} - the Id of the deposited magicat
     * {manapoints} - the associated manapoints of the magicat, used for determining share of rewards
     * {lastHarvestClaimed} - position in array of last claimed rewards, initalized as the length of the array 
     */
    struct Magicat{
        uint256 magicatId;
        uint256 manapoints;
        uint256 lastHarvestClaimed;
    }
    /***
     * @dev Struct used for interal accounting of harvested rewards, denominated in boo vaultshares
     * {amount} - the total amount of the harvest in vaultshares
     * {totalManaPoints} - the total amount of manapoints from all deposited magicats
     * {timestamp} - block timestamp of harvest, used for calculating apr
     */
    struct Harvest{
        uint256 amount;
        uint256 totalManaPoints;
        uint256 timestamp;
    }

    // total manapoints of all deposited magicats
    uint256 totalMp;

    // array of harvests, written each time harvest is called
    Harvest[] harvests;
    /***
     * {idToMagicat} - magicatId to Magicat Struct
     * {magicatIdToStakedPid} - mapping for keeping track of where each magicat is deposited in the aceLab contract
     */
    mapping(uint256 => Magicat) idToMagicat;
    mapping(uint256 => uint256) magicatIdToStakedPid;
    // address of the strategy the magicatsHandler hooks into
    address immutable strategy;

    constructor(
        address _strategy, 
        address _vault,
        address[] memory _strategists,
        address[] memory _multisigRoles
        ) ERC721("reaper magicats", "rfMagicats")
    {
        strategy = _strategy;
        _approveMagicatsFor(strategy);
        vault = _vault;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _multisigRoles[0]);
        _grantRole(ADMIN, _multisigRoles[1]);

        for (uint256 i = 0; i < _strategists.length; i++) {
            _grantRole(STRATEGIST, _strategists[i]);
        }

        cascadingAccess = [DEFAULT_ADMIN_ROLE, ADMIN, STRATEGIST, KEEPER];
    }
    /***
     * @notice deposit function for Magicat NFTs
     * @param magicatsIds - array of NFT ids to deposit
     * @dev creates a mirrored NFT of the deposit that allows for claiming rewards
     * as well as reclaiming of deposited NFT. Sends NFTs directly to strategy
     */
    function deposit(uint256[] memory magicatsIds) external{
        Magicat memory deposited;
        for(uint i; i < magicatsIds.length; i++){
            deposited.magicatId = magicatsIds[i];
            deposited.manapoints = IAceLab(aceLab).rarityOf(magicatsIds[i]);
            deposited.lastHarvestClaimed = harvests.length;

            totalMp += deposited.manapoints;
            idToMagicat[magicatsIds[i]] = deposited;

            _safeMint(msg.sender, magicatsIds[i]);

            IERC721(Magicats).safeTransferFrom(msg.sender, strategy, magicatsIds[i]);

        }
    }

    /***
     * @notice Withdraw function for Magicat NFTs
     * @param magicatsIds - array of NFTs to withdraw
     * @dev rewards are forcefully claimed for all withdrawn nfts because they would be lost in limbo otherwise
     * this also burns the underlying nft.
     */
    function withdraw(uint256[] memory magicatsIds) external{
        claimRewards(magicatsIds);
        for(uint i; i < magicatsIds.length; i++){
            require(_isApprovedOrOwner(msg.sender, magicatsIds[i]), "!approved");
            totalMp -= idToMagicat[magicatsIds[i]].manapoints;

            if(IERC721(Magicats).ownerOf(magicatsIds[i]) == strategy){
                _burn(magicatsIds[i]);
                IERC721(Magicats).transferFrom(strategy, msg.sender, magicatsIds[i]);
  
            }else if (IERC721(Magicats).ownerOf(magicatsIds[i]) == aceLab){
                _burn(magicatsIds[i]);
                uint[] memory unstake = new uint[](1);
                unstake[0] = magicatsIds[i];
                _updateStakedMagicats(magicatIdToStakedPid[magicatsIds[i]], new uint256[](0), unstake);
                IERC721(Magicats).transferFrom(strategy, msg.sender, magicatsIds[i]);
  
            }

            delete idToMagicat[magicatsIds[i]];
            delete magicatIdToStakedPid[magicatsIds[i]];
        }
    }

    /***
     * @dev internal function for interacting with the strategy-held magicats accross all poolIds
     * @param poolID, the acelab poolID to operate on
     * @param IDsToStake the magicatIds to Stake
     * @param IDsToUnstake the magicatIds to unstake
     */
    function _updateStakedMagicats(uint poolID, uint[] memory IDsToStake, uint[] memory IDsToUnstake) internal{
        IStrategy(strategy).updateMagicats(poolID, IDsToStake, IDsToUnstake);
        for(uint i = 0; i < IDsToStake.length; i++){
            magicatIdToStakedPid[IDsToStake[i]] = poolID;
        }
    }
    /***
     * @notice external function to update the staked magicats 
     * @param poolID, the acelab poolID to operate on
     * @param IDsToStake the magicatIds to Stake
     * @param IDsToUnstake the magicatIds to unstake 
     */
    function updateStakedMagicats(uint poolID, uint[] memory IDsToStake, uint[] memory IDsToUnstake) external{
        _atLeastRole(KEEPER);
        _updateStakedMagicats(poolID, IDsToStake, IDsToUnstake);
    }

    /***
     * @dev function for approving all MagicatNFTs for a specific address,
     * required for operability between strategy and handler
     */
    function _approveMagicatsFor(address operator) internal{
        IERC721(Magicats).setApprovalForAll(operator, true);
    }

    /***
     * @notice function for harvesting and redepositing boo into vault
     * writes to harvest log and allows for reward claims
     */
    function processRewards() external{
        Harvest memory latestHarvest;
        uint256 beforeAmount = IERC20(vault).balanceOf(address(this));
        _redepositGains();
        latestHarvest.amount = IERC20(vault).balanceOf(address(this)) - beforeAmount;
        latestHarvest.totalManaPoints = totalMp;
        latestHarvest.timestamp = block.timestamp;
        harvests.push(latestHarvest);
    }

    /***
     * @dev helper function calculating the unclaimed rewards of a single deposited ID
     * used by both the front end helper getMagicatsRewards, but also in the process of claiming
     * for a single ID
     */
    function getMagicatReward(uint256 id) public view returns (uint256) {
        uint256 totalHarvests = harvests.length;
        Magicat memory cat =  idToMagicat[id];
        uint256 magicatShare;
        uint256 unclaimedReward;
        for(uint i = cat.lastHarvestClaimed; i < totalHarvests; i++){
            magicatShare = harvests[i].amount * cat.manapoints / harvests[i].totalManaPoints;
            unclaimedReward += magicatShare;
        }

        return unclaimedReward;     
    }

    /***
     * @dev front end helper function for calculating the unclaimed rewards of an array of magicatIDs
     */
    function getMagicatRewards(uint[] memory ids) public view returns (uint256){
        uint256 unclaimedRewards;
        for(uint i = 0; i < ids.length; i++){
            unclaimedRewards += getMagicatReward(ids[i]);
        }
        return unclaimedRewards;
    }

    /***
     * @dev internal function for simple reward claiming
     * also updated the lastHarvestClaimed to align with Checks-Effects-Interaction pattern
     */
    function _claimRewards(uint256 _id) internal {
        uint256 owed = getMagicatReward(_id);
        idToMagicat[_id].lastHarvestClaimed = harvests.length;
        IERC20(vault).transfer(msg.sender, owed);
    }

    /***
     * @notice function for claiming rewards of an array of IDs
     * @param ids - array of NFT ids to claim rewards for
     * @dev after claiming 
     */
    function claimRewards(uint256[] memory ids) public {
        for(uint i = 0; i < ids.length; i++){
            require(_isApprovedOrOwner(msg.sender, ids[i]), "!approved");
            _claimRewards(ids[i]);
        }
    }

    /***
     * @dev internal function to deposit gained boo from strategy harvest back into the underlying vault
     */
    function _redepositGains() internal {
        uint256 BooBal = Boo.balanceOf(address(this));
        Boo.approve(vault, BooBal);
        IVault(vault).deposit(BooBal);
    }

    /***
     * @notice view function/front-end helper for getting an array of magicat NFTs owned by user {owner}
     * @param owner - the address to query the Magicat balance of
     */
    function getDepositableMagicats(address owner) external view returns (uint [] memory){
        uint256 balance = IMagicat(Magicats).balanceOf(owner);
        uint256[] memory ids = new uint[](balance);
        for(uint i = 0; i < balance; i++){
            ids[i] = IMagicat(Magicats).tokenOfOwnerByIndex(owner, i);
        }

        return ids;
    }

    /***
     * @notice view function for getting an array of deposited NFTs for an address:{owner} 
     * @param owner - the address to query the internal NFT balance of
     */
    function getDepositedMagicats(address owner) external view returns (uint [] memory){
        uint256 balance = balanceOf(owner);
        uint256[] memory ids = new uint[](balance);
         for(uint i = 0; i < balance; i++){
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }

        return ids;
    }
    /***
     * @notice external function for iterating through all pools and unstaking all magicats
     * can be called by keeper for hard reset of staked NFTs for large repositioning as 
     * management of nfts can be quite difficult to when doing large amounts of unstake-restaking
     */
    function massUnstakeMagicats() external {
        _atLeastRole(KEEPER);
        for(uint i = 0; i < IAceLab(aceLab).poolLength(); i++){
            uint[] memory stakedMagicats = IAceLab(aceLab).getStakedMagicats(i, strategy);
            uint[] memory empty;
            _updateStakedMagicats(i,empty,stakedMagicats);
        }
    }

    /**
     * @dev Internal function that checks cascading role privileges. Any higher privileged role
     * should be able to perform all the functions of any lower privileged role. This is
     * accomplished using the {cascadingAccess} array that lists all roles from most privileged
     * to least privileged.
     */
    function _atLeastRole(bytes32 role) internal view {
        uint256 numRoles = cascadingAccess.length;
        uint256 specifiedRoleIndex;
        for (uint256 i = 0; i < numRoles; i++) {
            if (role == cascadingAccess[i]) {
                specifiedRoleIndex = i;
                break;
            } else if (i == numRoles - 1) {
                revert();
            }
        }

        for (uint256 i = 0; i <= specifiedRoleIndex; i++) {
            if (hasRole(cascadingAccess[i], msg.sender)) {
                break;
            } else if (i == specifiedRoleIndex) {
                revert();
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4){
        return this.onERC721Received.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, AccessControlEnumerable) returns (bool){
        return(
            ERC721Enumerable.supportsInterface(interfaceId) ||
            AccessControlEnumerable.supportsInterface(interfaceId)
        );
    }
}