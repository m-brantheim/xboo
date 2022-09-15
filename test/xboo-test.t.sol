pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/ReaperAutoCompoundXBoo.sol";
import "../contracts/ReaperVaultv1_3.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract xBooTest is Test {
    
    IBooMirrorWorld public constant xBoo =
        IBooMirrorWorld(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598); // xBoo
    IERC20Upgradeable public constant Boo =
        IERC20Upgradeable(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE); // Boo
     address public constant currentAceLab = 0x399D73bB7c83a011cD85DF2a3CdF997ED3B3439f;
    address public constant currentMagicats = 0x2aB5C606a5AA2352f8072B9e2E8A213033e2c4c9;
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
            0
        );
        
        stratIMPL = new ReaperAutoCompoundXBoov2();
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
        strategists[0] = address(0xb0C9D5851deF8A2Aac4A23031CA2610f8C3483F9);

        wrappedProxy.initialize(feeRemitters, strategists);
    }
}
