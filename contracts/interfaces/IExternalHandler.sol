pragma solidity ^0.8.0;

interface IExternalHandler {
    function handle(address, uint256) external;
}