pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/ReaperAutoCompoundXBoo.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/magicatsHandler.sol";
import "../contracts/ReaperVaultv1_3.sol";
import "./abstracts/XbooConstants.t.sol";


contract xBooTest is XbooConstants {
    
   
    ReaperAutoCompoundXBoov2 XbooStrat;
    ReaperAutoCompoundXBoov2 stratIMPL;
    ReaperVaultv1_3 vault;
    ERC1967Proxy stratProxy;
    
    
    function setUp() public {
        vault = new ReaperVaultv1_3(
            address(Boo),
            "XBOO Single Stake Vault",
            "rfXBOO",
            0,
            0,
            type(uint).max
        );
        vm.label(address(vault), "boo vault");
        
        stratIMPL = new ReaperAutoCompoundXBoov2();
        vm.label(address(stratIMPL), "strategy Implementation");
        stratProxy = new ERC1967Proxy(
            address (stratIMPL),
            "" //args
        );
        vm.label(address(stratProxy), "ERC1967 Proxy: Strategy Proxy");

        XbooStrat = ReaperAutoCompoundXBoov2(address(stratProxy));

        address[] memory feeRemitters = new address[](2); 
        feeRemitters[0] = address(0xb0C9D5851deF8A2Aac4A23031CA2610f8C3483F9);
        feeRemitters[1] = address(1);
        address[] memory strategists = new address[](1); 

        address[] memory msRoles = new address[](3);
        msRoles[0] = address(0xb0C9D5851deF8A2Aac4A23031CA2610f8C3483F9);
        msRoles[1] = address(1337);
        msRoles[2] = address(31337);

        strategists[0] = address(0xb0C9D5851deF8A2Aac4A23031CA2610f8C3483F9);

        XbooStrat.initialize(address(vault), feeRemitters, strategists, msRoles);
        vault.initialize(address(XbooStrat));

        address dummyMagicats = address(33333);
        XbooStrat.updateMagicatsHandler(dummyMagicats);
        vm.label(dummyMagicats, "dummy magicats handler");

        setRoutes();

        vm.deal(user1, 1 ether);
        vm.label(user1, "user1");
        vm.label(BigBooWhale, "BigBooWhale");
        vm.label(address(Boo), "BooToken");
        vm.prank(BigBooWhale);
        Boo.transfer(user1, 10000 ether);
        vm.stopPrank();

        vm.label(currentAceLab, "aceLab");
        vm.label(currentMagicats, "magicats");
        vm.label(WFTM,"WFTM");
        vm.label(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598, "xBoo");
    }

    function testDepositAndWithdraw() public {
        vm.startPrank(user1);
        Boo.approve(address(vault), type(uint256).max);
        uint256 startingBalance = Boo.balanceOf(user1);
        console2.log("starting balance is : %s", startingBalance);
        vault.deposit(startingBalance);
        vm.stopPrank();
        setAllocations();
        console2.log("deposited all boo and recieve %s shares", vault.balanceOf(user1));
        console2.log("strat believes it has a total of %s boo", XbooStrat.balanceOfPool());
        vm.startPrank(user1);
        vault.withdrawAll();
        vm.stopPrank();
        console2.log("withdrawingAll");
        uint256 endingBalance = Boo.balanceOf(user1);
        console2.log("ending balance is: %s", endingBalance);
        assertGe(startingBalance, endingBalance);
       
    }

    function testDepositAndHarvestAndSeeYield() public {
        vm.startPrank(user1);
        Boo.approve(address(vault), type(uint256).max);
        uint256 startingBalance = Boo.balanceOf(user1);
        
        console2.log("starting balance is : %s", startingBalance);
        
        vault.deposit(startingBalance);
        vm.stopPrank();
        
        setAllocations();
        IAceLab(currentAceLab).massUpdatePools();
        
        console2.log("deposited all boo and recieve %s shares", vault.balanceOf(user1));
        console2.log("strat believes it has a total of %s boo", XbooStrat.balanceOfPool());
        uint time = uint(block.timestamp);
        uint256 apr;
        uint iterations = 10;
        for(uint i; i < iterations; i++){
            vm.warp(time += 13 hours);
            XbooStrat.harvest();
            apr = uint(XbooStrat.averageAPRAcrossLastNHarvests(6));
            console.log("APR is : %s", apr);
        }
    }



    /*
    ///////////////////// HELPER FUNCTIONS ////////////////////
    */

    function setRoutes() public {
        address[] memory hecRoute = new address[](3);
        hecRoute[0] = HEC; hecRoute[1] = USDC; hecRoute[2] = WFTM; 
        address[] memory lqdrRoute = new address[](2);
        lqdrRoute[0] = LQDR; lqdrRoute[1] = WFTM;
        address[] memory OrbsRoute = new address[](3);
        OrbsRoute[0] = ORBS; OrbsRoute[1] = USDC; OrbsRoute[2] = WFTM;
        address[] memory xTarotRoute = new address[](2);
        xTarotRoute[0] = Tarot; xTarotRoute[1] = WFTM;
        address[] memory GALCXRoute = new address[](2);
        GALCXRoute[0] = GALCX; GALCXRoute[1] = WFTM;
        address[] memory SDRoute = new address[](3);
        SDRoute[0] = SD; SDRoute[1] = USDC; SDRoute[2] = WFTM;
        address[] memory singleRoute = new address[](3);
        singleRoute[0] = SINGLE; singleRoute[1] = USDC; singleRoute[2] = WFTM; 

        XbooStrat.setRoute(HEC_ID, hecRoute);
        XbooStrat.setRoute(LQDR_ID, lqdrRoute);
        XbooStrat.setRoute(GALCX_ID, GALCXRoute);
        XbooStrat.setRoute(SD_ID, SDRoute);
        XbooStrat.setRoute(xTarot_ID, xTarotRoute);
        XbooStrat.setRoute(ORBS_ID, OrbsRoute);
        XbooStrat.setRoute(SINGLE_ID, singleRoute);
        vm.label(HEC, "Hec");
        vm.label(LQDR, "LQDR");
        vm.label(ORBS, "ORBS");
        vm.label(Tarot, "Tarot");
        vm.label(xTarot, "xTarot");
        vm.label(GALCX, "GALCX");
        vm.label(SD, "SD");
        vm.label(SINGLE, "SINGLE");
        vm.label(USDC, "USDC");
        vm.label(uniRouter, "SpookySwap Router");

    }

    function setAllocations() public{
        uint hecAlloc = 0;
        uint orbsAlloc = 10000;
        uint galcxAlloc = 0;
        uint xTarotAlloc = 0;
        uint stratBalance = XbooStrat.balanceOfPool();
        uint length = IAceLab(currentAceLab).poolLength();
        uint[] memory idealAmounts = new uint[](length);
        uint[] memory currentAmounts = new uint[](length);
        for(uint i ; i < length; i++){
            console2.log(i);
            uint temp;
            (temp,,,) = IAceLab(currentAceLab).userInfo(i, address(XbooStrat));
            //console2.log(temp);
            currentAmounts[i] = temp;
            //console2.log(currentAmounts[i]);
            if(i == HEC_ID){
                idealAmounts[i] = (hecAlloc * stratBalance) / 10000;
            }
            else if(i == ORBS_ID){
                idealAmounts[i] = (orbsAlloc * stratBalance) / 10000;
            }
            else if(i == xTarot_ID){
                idealAmounts[i] = (xTarotAlloc * stratBalance) / 10000;
            }
            else if(i == GALCX_ID){
                idealAmounts[i] = (galcxAlloc * stratBalance) / 10000;
            }
            else{
                idealAmounts[i] = 0;
            }
            //console2.log( idealAmounts[i]);
            
        }
        console.log("after for");
        uint amtWithdraws;
        uint amtDeposits;
        uint[] memory withdrawPoolIds = new uint[](length);
        uint[] memory withdrawAmounts = new uint[](length);
        uint[] memory depositPoolIds = new uint[](length);
        uint[] memory depositAmounts = new uint[](length);

        for(uint i; i < length; i++ ){
            if(idealAmounts[i] > currentAmounts[i]){
                //deposit
                depositPoolIds[amtDeposits] = i;
                depositAmounts[amtDeposits] = idealAmounts[i] - currentAmounts[i];
                amtDeposits+=1;
            }
            if(idealAmounts[i] < currentAmounts[i]){
                 //deposit
                withdrawPoolIds[amtWithdraws] = i;
                withdrawAmounts[amtWithdraws] = currentAmounts[i] - idealAmounts[i];
                amtWithdraws+=1;               
            }
        }

        XbooStrat.setXBooAllocations(withdrawPoolIds, withdrawAmounts, depositPoolIds, depositAmounts);

    }
}
