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

contract magicatsHandler is IERC721Receiver, ERC721Enumerable {
    address aceLab = 0x399D73bB7c83a011cD85DF2a3CdF997ED3B3439f;
    address public constant Magicats = 0x2aB5C606a5AA2352f8072B9e2E8A213033e2c4c9;
    IBooMirrorWorld public constant xBoo =
        IBooMirrorWorld(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598); // xBoo
    IERC20 public constant Boo =
        IERC20(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE); // Boo

    address public vault;

    struct Magicat{
        uint256 magicatId;
        uint256 manapoints;
        uint256 lastHarvestClaimed;
    }
    struct Harvest{
        uint256 amount;
        uint256 totalManaPoints;
        uint256 timestamp;
    }
    uint256 totalMp;

    Harvest[] harvests;
    mapping(uint256 => Magicat) idToMagicat;
    address strategy;

    constructor(address _strategy, address _vault) ERC721("reaper magicats", "rfMagicats")
    {
        strategy = _strategy;
        _approveMagicatsFor(strategy);
        vault = _vault;
    }
    function deposit(uint256[] calldata magicatsIds) external{
        Magicat memory deposited;
        for(uint i; i < magicatsIds.length; i++){
            deposited.magicatId = magicatsIds[i];
            deposited.manapoints = IAceLab(aceLab).rarityOf(magicatsIds[i]);
            deposited.lastHarvestClaimed = harvests.length;

            totalMp += deposited.manapoints;
            idToMagicat[magicatsIds[i]] = deposited;

            

            _safeMint(msg.sender, magicatsIds[i]);
            //will seperate these in the future, or possibly combine them
            IERC721(Magicats).transferFrom(msg.sender, address(this), magicatsIds[i]);

            IERC721(Magicats).transferFrom(address(this), strategy, magicatsIds[i]);
        }
    }

    function withdraw(uint256[] calldata magicatsIds) external{
        for(uint i; i < magicatsIds.length; i++){
            require(_isApprovedOrOwner(address(this), magicatsIds[i]), "!approved");
            IERC721(Magicats).transferFrom(address(this), msg.sender, magicatsIds[i]);
            _burn(magicatsIds[i]);

        }
    }

    function updateStakedMagicats(uint poolID, uint[] calldata IDsToStake, uint[] calldata IDsToUnstake) external{
        IStrategy(strategy).updateMagicats(poolID, IDsToStake, IDsToUnstake);
    }

    function _approveMagicatsFor(address operator) internal{
        IERC721(Magicats).setApprovalForAll(operator, true);
    }

    function updateStrategy(address _strategy) external{
        strategy = _strategy;
    }

    function processRewards() external{
        Harvest memory latestHarvest;
        uint256 beforeAmount = IERC20(vault).balanceOf(address(this));
        _redepositGains();
        latestHarvest.amount = IERC20(vault).balanceOf(address(this)) - beforeAmount;
        latestHarvest.totalManaPoints = totalMp;
        latestHarvest.timestamp = block.timestamp;
        harvests.push(latestHarvest);
    }

    function getMagicatRewards(uint256 id) public view returns (uint256) {
        uint256 totalHarvests = harvests.length;
        Magicat memory cat =  idToMagicat[id];
        uint256 magicatShare;
        uint256 unclaimedRewards;
        for(uint i = cat.lastHarvestClaimed; i < totalHarvests; i++){
            magicatShare = harvests[i].amount * cat.manapoints / totalMp;
            unclaimedRewards += magicatShare;
        }

        return unclaimedRewards;
        
    }

    function _claimRewards(uint256 _id) internal {
        uint256 owed = getMagicatRewards(_id);
        IERC20(vault).transfer(msg.sender, owed);
    }

    function claimRewards(uint256[] calldata ids) public {
        for(uint i = 0; i < ids.length; i++){
            require(_isApprovedOrOwner(msg.sender, ids[i]), "!approved");
            _claimRewards(ids[i]);
            idToMagicat[ids[i]].lastHarvestClaimed = harvests.length - 1;
        }
    }

    function _redepositGains() internal {
        uint256 xbooBal = xBoo.balanceOf(address(this));
        xBoo.leave(xbooBal);
        uint256 BooBal = Boo.balanceOf(address(this));
        Boo.approve(vault, BooBal);
        IVault(vault).deposit(BooBal);
    }

    function getDepositableMagicats(address owner) external view returns (uint [] memory){
        uint256 balance = IMagicat(Magicats).balanceOf(owner);
        uint256[] memory ids;
        for(uint i = 0; i < balance; i++){
            ids[i] = IMagicat(Magicats).tokenOfOwnerByIndex(owner, i);
        }

        return ids;
    }

    function getDepositedMagicats(address owner) external view returns (uint [] memory){
        uint256 balance = ERC721.balanceOf(owner);
        uint256[] memory ids;
         for(uint i = 0; i < balance; i++){
            ids[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
        }

        return ids;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return this.onERC721Received.selector;
    }
}