// SPDX-License-Identifier: AGPLv3

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMagicats.sol";
import "./interfaces/IAceLab.sol";
import "./interfaces/IBooMirrorWorld.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IVault.sol";

import "forge-std/console.sol";

// rename titlecase
contract magicatsHandler is IERC721Receiver, ERC721Enumerable {
    address aceLab = 0x399D73bB7c83a011cD85DF2a3CdF997ED3B3439f;
    address public constant Magicats = 0x2aB5C606a5AA2352f8072B9e2E8A213033e2c4c9;
    IBooMirrorWorld public constant xBoo = IBooMirrorWorld(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598);
    IERC20 public constant Boo = IERC20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE);

    address public vault; // immutable

    // descriptive comments
    struct Magicat {
        uint256 magicatId;
        uint256 manapoints;
        uint256 lastHarvestClaimed;
    }
    struct Harvest {
        uint256 amount;
        uint256 totalManaPoints;
        uint256 timestamp;
    }
    uint256 totalMp;

    Harvest[] harvests;
    mapping(uint256 => Magicat) idToMagicat;
    mapping(uint256 => uint256) MagicatIdToStakedPid; // camelcase
    address strategy; // immutable

    constructor(address _strategy, address _vault) ERC721("reaper magicats", "rfMagicats") {
        strategy = _strategy;
        _approveMagicatsFor(strategy);
        vault = _vault;
    }

    function deposit(uint256[] memory magicatsIds) external {
        Magicat memory deposited;
        for (uint256 i; i < magicatsIds.length; i++) {
            deposited.magicatId = magicatsIds[i];
            deposited.manapoints = IAceLab(aceLab).rarityOf(magicatsIds[i]);
            deposited.lastHarvestClaimed = harvests.length;

            totalMp += deposited.manapoints;
            idToMagicat[magicatsIds[i]] = deposited;

            _safeMint(msg.sender, magicatsIds[i]);
            //will seperate these in the future, or possibly combine them
            IERC721(Magicats).safeTransferFrom(msg.sender, address(this), magicatsIds[i]);

            IERC721(Magicats).safeTransferFrom(address(this), strategy, magicatsIds[i]);
        }
    }

    function withdraw(uint256[] memory magicatsIds) external {
        for (uint256 i; i < magicatsIds.length; i++) {
            require(_isApprovedOrOwner(msg.sender, magicatsIds[i]), "!approved");
            if (IERC721(Magicats).ownerOf(magicatsIds[i]) == strategy) {
                _burn(magicatsIds[i]);
                IERC721(Magicats).transferFrom(strategy, msg.sender, magicatsIds[i]);
            } else if (IERC721(Magicats).ownerOf(magicatsIds[i]) == aceLab) {
                _burn(magicatsIds[i]);
                // uint256[] memory empty;
                uint256[] memory unstake = new uint256[](1);
                unstake[0] = magicatsIds[i]; //there is probably a better way to do this
                _updateStakedMagicats(MagicatIdToStakedPid[magicatsIds[i]], new uint256[](0), unstake);
                IERC721(Magicats).transferFrom(strategy, msg.sender, magicatsIds[i]);
            }
            // claim first
            // reduce totalMp
            // clear out mapping
        }
    }

    function _updateStakedMagicats(
        uint256 poolID,
        uint256[] memory IDsToStake,
        uint256[] memory IDsToUnstake
    ) internal {
        IStrategy(strategy).updateMagicats(poolID, IDsToStake, IDsToUnstake);
        for (uint256 i = 0; i < IDsToStake.length; i++) {
            MagicatIdToStakedPid[IDsToStake[i]] = poolID;
        }
        //we don't need to update unstaked because unstaked will sit in the strategy and therefore have no need for a poolID
    }

    function updateStakedMagicats(
        uint256 poolID,
        uint256[] memory IDsToStake,
        uint256[] memory IDsToUnstake
    ) external {
        //require(_atLeastRole(KEEPER), "!AUTHORIZED");
        _updateStakedMagicats(poolID, IDsToStake, IDsToUnstake);
    }

    function _approveMagicatsFor(address operator) internal {
        IERC721(Magicats).setApprovalForAll(operator, true);
    }

    function updateStrategy(address _strategy) external {
        strategy = _strategy;
    }

    function processRewards() external {
        Harvest memory latestHarvest;
        uint256 beforeAmount = IERC20(vault).balanceOf(address(this));
        _redepositGains();
        latestHarvest.amount = IERC20(vault).balanceOf(address(this)) - beforeAmount;
        latestHarvest.totalManaPoints = totalMp;
        latestHarvest.timestamp = block.timestamp;
        harvests.push(latestHarvest);
    }

    function getMagicatReward(uint256 id) public view returns (uint256) {
        uint256 totalHarvests = harvests.length;
        Magicat memory cat = idToMagicat[id];
        uint256 magicatShare;
        uint256 unclaimedReward;
        for (uint256 i = cat.lastHarvestClaimed; i < totalHarvests; i++) {
            magicatShare = (harvests[i].amount * cat.manapoints) / harvests[i].totalManaPoints;
            unclaimedReward += magicatShare;
        }

        return unclaimedReward;
    }

    function getMagicatRewards(uint256[] memory ids) external view returns (uint256) {
        uint256 unclaimedRewards;
        for (uint256 i = 0; i < ids.length; i++) {
            unclaimedRewards += getMagicatReward(ids[i]);
        }
        return unclaimedRewards;
    }

    function _claimRewards(uint256 _id) internal {
        uint256 owed = getMagicatReward(_id);
        IERC20(vault).transfer(msg.sender, owed);
    }

    function claimRewards(uint256[] memory ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            require(_isApprovedOrOwner(msg.sender, ids[i]), "!approved");
            _claimRewards(ids[i]);
            idToMagicat[ids[i]].lastHarvestClaimed = harvests.length;
        }
    }

    function _redepositGains() internal {
        // when strategy is fixed there should be only boo here
        uint256 xbooBal = xBoo.balanceOf(address(this));
        xBoo.leave(xbooBal);
        uint256 BooBal = Boo.balanceOf(address(this));
        Boo.approve(vault, BooBal);
        IVault(vault).deposit(BooBal);
    }

    function getDepositableMagicats(address owner) external view returns (uint256[] memory) {
        uint256 balance = IMagicat(Magicats).balanceOf(owner);
        uint256[] memory ids = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            ids[i] = IMagicat(Magicats).tokenOfOwnerByIndex(owner, i);
        }

        return ids;
    }

    function getDepositedMagicats(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        console.log("found %s nfts", balance);
        uint256[] memory ids;
        for (uint256 i = 0; i < balance; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
            console.log("ids of i: %s, is set to %s", i, ids[i]);
        }

        return ids;
    }

    function massUnstakeMagicats() external {
        //_atLeastRole(Strategist);
        for (uint256 i = 0; i < IAceLab(aceLab).poolLength(); i++) {
            uint256[] memory stakedMagicats = IAceLab(aceLab).getStakedMagicats(i, strategy);
            uint256[] memory empty;
            _updateStakedMagicats(i, empty, stakedMagicats);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
