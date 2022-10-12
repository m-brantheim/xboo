pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/ReaperAutoCompoundXBoo.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/magicatsHandler.sol";
import "../contracts/ReaperVaultv1_3.sol";
import "./abstracts/XbooConstants.t.sol";
import "./xboo-test.t.sol";

contract magicatTest is xBooTest{

    MagicatsHandler handler;

   function setUp() public override{
        xBooTest.setUp();

        address[] memory msRoles = new address[](2);
        msRoles[0] = address(0xb0C9D5851deF8A2Aac4A23031CA2610f8C3483F9);
        msRoles[1] = address(1337);
        address[] memory strategists = new address[](1); 
        strategists[0] = address(0xb0C9D5851deF8A2Aac4A23031CA2610f8C3483F9);


        handler = new MagicatsHandler(
            address(XbooStrat),
            address(vault),
            strategists,
            msRoles
        );

        vm.label(address(handler), "catHandler");
        XbooStrat.updateMagicatsHandler(address(handler));

        vm.startPrank(user1);
        uint256 startingBalance = Boo.balanceOf(user1);
        vault.deposit(startingBalance);
        vm.stopPrank();
        setAllocations();

   }
    function testMagicatDepositAndWithdraw() public {
        address magicatOwner = 0x60BC5E0440C867eEb4CbcE84bB1123fad2b262B1;
        vm.label(magicatOwner, "magicatOwner");
        vm.startPrank(magicatOwner);
        uint256[] memory ownedMagicats = handler.getDepositableMagicats(magicatOwner);
        
        //try to deposit without approvals should fail
        vm.expectRevert("ERC721: transfer caller is not owner nor approved");
        handler.deposit(ownedMagicats);
 
        IMagicat(currentMagicats).setApprovalForAll(address(handler), true);
        handler.deposit(ownedMagicats);
        
        //should not be able to deposit already desposited nfts
        vm.expectRevert("ERC721: transfer of token that is not own");
        handler.deposit(ownedMagicats);

        vm.stopPrank();
        
        uint256[] memory depositedMagicats = handler.getDepositedMagicats(magicatOwner);
        
        //leet hacker ops
        vm.startPrank(address(31337));
        //expect handler to revert on withdrawing someone elses nfts
        vm.expectRevert("!approved");        
        handler.withdraw(depositedMagicats);

        vm.stopPrank();
        vm.startPrank(magicatOwner);
        handler.withdraw(depositedMagicats);
    }

    function testMagicatDepositAndSeeProfitOnHarvest() public {
        address magicatOwner = 0x60BC5E0440C867eEb4CbcE84bB1123fad2b262B1;
        vm.startPrank(magicatOwner);
        uint256[] memory ownedMagicats = handler.getDepositableMagicats(magicatOwner);
        IMagicat(currentMagicats).setApprovalForAll(address(handler), true);
        handler.deposit(ownedMagicats);
        vm.stopPrank();

        setMagicatAllocations();

        uint iterations = 10;
        uint apr;
        uint time = uint(block.timestamp);
        for(uint i = 0; i < iterations; i++){
            vm.warp(time += 13 hours);
            XbooStrat.harvest();
            apr = uint(XbooStrat.averageAPRAcrossLastNHarvests(6));
            console.log("APR is : %s", apr);
        }

        uint[] memory userOwnedMagicats = handler.getDepositedMagicats(magicatOwner);
        uint userStartingVaultShares = vault.balanceOf(magicatOwner);
        uint dueRewardsForAllCats = handler.getMagicatRewards(userOwnedMagicats);
        uint[] memory subArray = new uint[](1);
        subArray[0] = userOwnedMagicats[0];
        uint dueRewardForSubArray = handler.getMagicatRewards(subArray);

        vm.startPrank(magicatOwner);
        //Assert that helper function returns the same amount as the amount claimed
        handler.claimRewards(subArray);
        uint afterClaimingVaultShares = vault.balanceOf(magicatOwner);

        assertEq(dueRewardForSubArray, afterClaimingVaultShares - userStartingVaultShares);
        
        //Assert that withdrawing claims rewards for the nft
        subArray[0] = userOwnedMagicats[1];
        dueRewardForSubArray = handler.getMagicatRewards(subArray);
        handler.withdraw(subArray);
        uint afterWithdrawVaultShares = vault.balanceOf(magicatOwner);
        assertEq(dueRewardForSubArray, afterWithdrawVaultShares - afterClaimingVaultShares);
        
        //assert that redepositing between harvests does not double rewards
        handler.deposit(subArray);
        assertEq(0, handler.getMagicatRewards(subArray));
        
        //assert that approving the handler doesnt accidentally allow for nft withdrawal or reward claim
        handler.setApprovalForAll(address(handler), true);
        vm.stopPrank();
        vm.startPrank(address(31337));
        
        subArray[0] = userOwnedMagicats[2];
        vm.expectRevert("!approved");
        handler.claimRewards(subArray);
        vm.expectRevert("!approved");
        handler.withdraw(subArray);
    }

    function testMagicatHandlerMigration() public {
        MagicatsHandler handler2;
        address[] memory msRoles = new address[](2);
        msRoles[0] = address(0xb0C9D5851deF8A2Aac4A23031CA2610f8C3483F9);
        msRoles[1] = address(1337);
        address[] memory strategists = new address[](1); 
        strategists[0] = address(0xb0C9D5851deF8A2Aac4A23031CA2610f8C3483F9);


        handler2 = new MagicatsHandler(
            address(XbooStrat),
            address(vault),
            strategists,
            msRoles
        );

        vm.label(address(handler2), "new handler");

        address magicatOwner = 0x60BC5E0440C867eEb4CbcE84bB1123fad2b262B1;
        vm.startPrank(magicatOwner);
        uint256[] memory ownedMagicats = handler.getDepositableMagicats(magicatOwner);
        IMagicat(currentMagicats).setApprovalForAll(address(handler), true);
        handler.deposit(ownedMagicats);
        vm.stopPrank();

        setMagicatAllocations();

        vm.startPrank(0xb0C9D5851deF8A2Aac4A23031CA2610f8C3483F9);
        handler.massUnstakeMagicats();
        XbooStrat.updateMagicatsHandler(address(handler2));
        vm.stopPrank();




    }

    function setMagicatAllocations() public {
        uint aceLabBalanceBeforeAllocation = IMagicat(currentMagicats).balanceOf(address(currentAceLab));

        vm.startPrank(0xb0C9D5851deF8A2Aac4A23031CA2610f8C3483F9);
        handler.massUnstakeMagicats();
        uint[] memory stratIds = getStrategyMagicats();
        console.log(stratIds.length);
        console.log(stratIds[0]);
        uint[] memory empty = new uint[](0);
        handler.updateStakedMagicats(HEC_ID, stratIds, empty);
        vm.stopPrank();

        uint stratBalanceAfterAllocation = IMagicat(currentMagicats).balanceOf(address(XbooStrat));
        uint aceLabBalanceAfterAllocation = IMagicat(currentMagicats).balanceOf(address(currentAceLab));
        console.log("acelab nft balance before allocation %s", aceLabBalanceBeforeAllocation);
        console.log("strat nft balance after allocation %s", stratBalanceAfterAllocation);
        console.log("acelab nft after before allocation %s", aceLabBalanceAfterAllocation);
        
    
    }

    function getStrategyMagicats() public returns (uint[] memory){
        uint balance = IMagicat(currentMagicats).balanceOf(address(XbooStrat));
        uint[] memory ids = new uint[](balance);
        for(uint i = 0; i < balance; i++){
            ids[i] = IMagicat(currentMagicats).tokenOfOwnerByIndex(address(XbooStrat), i);
        }

        return ids;
    }
}