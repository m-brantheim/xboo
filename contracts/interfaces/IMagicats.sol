// SPDX-License-Identifier: AGPLv3

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMagicat is IERC721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}
