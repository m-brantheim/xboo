pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMagicat is IERC721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);
    function ownerOf(uint256 tokenId) external returns (address);
    function balanceOf(address owner) external returns (uint256);
}