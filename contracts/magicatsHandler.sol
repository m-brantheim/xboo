pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IAceLab.sol";
import "./interfaces/IStrategy.sol";

contract magicatsHandler is IERC721Receiver, ERC721 {
    address aceLab = 0x399D73bB7c83a011cD85DF2a3CdF997ED3B3439f;
    address public constant Magicats = 0x2aB5C606a5AA2352f8072B9e2E8A213033e2c4c9;

    struct magicat{
        uint256 magicatId;
        uint256 manapoints;
    }
    magicat[] managedMagicats;
    mapping(address => magicat[]) userMagicats;
    address strategy;

    constructor(address _strategy) ERC721("reaper magicats", "rfMagicats")
    {
        strategy = _strategy;
        _approveMagicatsFor(strategy);
    }
    function deposit(uint256[] calldata magicatsIds) external{
        magicat memory deposited;
        for(uint i; i < magicatsIds.length; i++){
            deposited.magicatId = magicatsIds[i];
            deposited.manapoints = IAceLab(aceLab).rarityOf(magicatsIds[i]);

            managedMagicats.push(deposited);
            userMagicats[msg.sender].push(deposited);

            

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

    function updateMagicats(uint poolID, uint[] calldata IDsToStake, uint[] calldata IDsToUnstake) external{
        IStrategy(strategy).updateMagicats(poolID, IDsToStake, IDsToUnstake);
    }

    function _approveMagicatsFor(address operator) internal{
        IERC721(Magicats).setApprovalForAll(operator, true);
    }

    function updateStrategy(address _strategy) external{
        strategy = _strategy;
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