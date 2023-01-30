pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/MagicatsHandlerUpgradeable.sol";
import "./abstracts/XbooConstants.t.sol";

contract ProductionMagicatUpgrade is XbooConstants {
    address payable public existingHandler = payable(0xD3BF27E1606dF8Ac80f4Fd3c4faF47b8c31a1021);
    MagicatsHandlerUpgradeable public currentHandler;
    MagicatsHandlerUpgradeable public newHandler;

    uint256 public oldMP;
    uint256 public oldSupply;

    function setUp() public {
        currentHandler = MagicatsHandlerUpgradeable(existingHandler);
        vm.label(existingHandler, "handler");
        oldMP = currentHandler.totalMp();
        oldSupply = currentHandler.totalSupply();
        console.log("oldMP: ", oldMP);
        console.log("oldSupply: ", oldSupply);
        newHandler = new MagicatsHandlerUpgradeable();
        console.log("address(newHandler): ", address(newHandler));
    }

    function testHandlerProductionUpgradeValidity() public {
        vm.expectRevert();
        uint256 lastAllocation = currentHandler.lastAllocationTimestamp();

        vm.startPrank(0xe1610bB38Ce95254dD77cbC82F9c1148569B560e);
        currentHandler.upgradeTo(address(newHandler));

        uint256 newMP = currentHandler.totalMp();
        uint256 newSupply = currentHandler.totalSupply();
        console.log("newMP: ", newMP);
        console.log("newSupply: ", newSupply);
        assertGe(newMP, oldMP);
        assertGe(newSupply, oldSupply);

        lastAllocation = currentHandler.lastAllocationTimestamp();
        console.log("lastAllocation: ", lastAllocation);
        assertEq(lastAllocation, 0);

        uint256[] memory args = new uint256[](0);
        uint256 poolID = 0;
        currentHandler.updateStakedMagicats(poolID, args, args);
        lastAllocation = currentHandler.lastAllocationTimestamp();
        console.log("lastAllocation: ", lastAllocation);
        assertEq(lastAllocation, block.timestamp);
    }
}
