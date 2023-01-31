// SPDX-License-Identifier: AGPLv3

pragma solidity ^0.8.0;

interface IMagicatsHandler {
    function processRewards() external;

    function massUnstakeMagicats() external;

    function withdrawAllMagicatsFromStrategy() external;

    function getDepositableMagicats(address) external returns (uint256[] memory);
}
