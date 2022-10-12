pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../contracts/ReaperAutoCompoundXBoo.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/ReaperVaultv1_3.sol";

abstract contract XbooConstants is Test {
    IBooMirrorWorld public constant xBoo = IBooMirrorWorld(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598); // xBoo

    IERC20Upgradeable public constant Boo = IERC20Upgradeable(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE); // Boo
    address public constant currentAceLab = 0x399D73bB7c83a011cD85DF2a3CdF997ED3B3439f;
    address public constant currentMagicats = 0x2aB5C606a5AA2352f8072B9e2E8A213033e2c4c9;
    address public constant uniRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address user1 = address(1);

    uint256 HEC_ID = 1;
    uint256 LQDR_ID = 2;
    uint256 SINGLE_ID = 3;
    uint256 xTarot_ID = 4;
    uint256 ORBS_ID = 5;
    uint256 GALCX_ID = 6;
    uint256 SD_ID = 7;

    address WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address HEC = 0x5C4FDfc5233f935f20D2aDbA572F770c2E377Ab0;
    address LQDR = 0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9;
    address GALCX = 0x70F9fd19f857411b089977E7916c05A0fc477Ac9;
    address SD = 0x412a13C109aC30f0dB80AD3Bd1DeFd5D0A6c0Ac6;
    address SINGLE = 0x8cc97B50Fe87f31770bcdCd6bc8603bC1558380B;
    address xTarot = 0x74D1D2A851e339B8cB953716445Be7E8aBdf92F4;
    address ORBS = 0x3E01B7E242D5AF8064cB9A8F9468aC0f8683617c;
    address Tarot = 0xC5e2B037D30a390e62180970B3aa4E91868764cD;

    // Intermediate tokens
    address USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address DAI = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;

    address BigBooWhale = 0xf778F4D7a14A8CB73d5261f9C61970ef4E7D7842;
}
