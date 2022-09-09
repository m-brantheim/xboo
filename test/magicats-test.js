const pools = require("../pools.json");
const hre = require("hardhat");
const chai = require("chai");
const { solidity, loadFixture } = require("ethereum-waffle");
const { ethers } = require("hardhat");
chai.use(solidity);
const { expect } = chai;

const moveTimeForward = async (seconds) => {
  await network.provider.send("evm_increaseTime", [seconds]);
  await network.provider.send("evm_mine");
};

const updatePools = async (acelab) => {
  const tx = await acelab.massUpdatePools();
  await tx.wait();
};

describe("Magicats Staking", function () {

  const i = 0;
  let Vault;
  let Strategy;
  let PaymentRouter;
  let Treasury;
  let Boo;
  let Acelab;
  let vault;
  let strategy;
  let paymentRouter;
  let paymentRouterAddress = "0x603e60d22af05ff77fdcf05c063f582c40e55aae";
  let treasury;
  let boo;
  let booAddress = "0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE";
  let xBooAddress = "0xa48d959AE2E88f1dAA7D5F611E01908106dE7598";
  let acelab;
  let self;
  let booWhale;
  let bigBooWhale;
  let selfAddress = "0x60BC5E0440C867eEb4CbcE84bB1123fad2b262B1";
  let strategist;
  let owner;

  async function deploySetup() {
    //reset network
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: "https://rpc.ankr.com/fantom"
          },
        },
      ],
    });
    console.log("providers");
    //get signers
    [owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners();
    const booHolder = "0xcbccad4eeee7bb58379bbf200d06ca6957efa843";
    const booWhaleAddress = "0x19fd5bc571aae24ea806e548292d5cf759a916f0";
    const bigBooWhaleAddress = "0xf778f4d7a14a8cb73d5261f9c61970ef4e7d7842";


    const strategistAddress = "0x3b410908e71Ee04e7dE2a87f8F9003AFe6c1c7cE";
    const treasuryAddr = '0x0e7c5313E9BB80b654734d9b7aB1FB01468deE3b';
    const paymentSplitterAddress = '0x63cbd4134c2253041F370472c130e92daE4Ff174';

    const superAdminAddress = '0x04C710a1E8a738CDf7cAD3a52Ba77A784C35d8CE';
    const adminAddress = '0x539eF36C804e4D735d8cAb69e8e441c12d4B88E0';
    const guardianAddress = '0xf20E25f2AB644C8ecBFc992a6829478a85A98F2c';
    const maintainerAddress = '0x81876677843D00a7D792E1617459aC2E93202576';

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [booHolder],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [booWhaleAddress],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [bigBooWhaleAddress],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [strategistAddress],
    });
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [selfAddress],
    });
    self = await ethers.provider.getSigner(selfAddress);
    booWhale = await ethers.provider.getSigner(booWhaleAddress);
    bigBooWhale = await ethers.provider.getSigner(bigBooWhaleAddress);
    strategist = await ethers.provider.getSigner(strategistAddress);
    await self.sendTransaction({
      to: bigBooWhaleAddress,
      value: ethers.utils.parseEther("0.1"),
    });
    ownerAddress = await owner.getAddress();
    console.log("addresses");

    //get artifacts
    StrategyIMPL = await ethers.getContractFactory("ReaperAutoCompoundXBoov2");
    PaymentRouter = await ethers.getContractFactory("PaymentRouter");
    Vault = await ethers.getContractFactory("ReaperVaultv1_3");
    Treasury = await ethers.getContractFactory("ReaperTreasury");
    Boo = await ethers.getContractFactory("SpookyToken");
    Acelab = await ethers.getContractFactory("AceLab");
    console.log("artifacts");

    //deploy contracts
    treasury = await Treasury.deploy();
    console.log("treasury");
    boo = await Boo.attach(booAddress);
    const aceLabAddress = "0x399D73bB7c83a011cD85DF2a3CdF997ED3B3439f";
    acelab = await Acelab.attach(aceLabAddress);
    console.log("boo attached");
    vault = await Vault.deploy(
      booAddress,
      "XBOO Single Stake Vault",
      "rfXBOO",
      432000,
      0,
      ethers.utils.parseEther("999999")
    );
    console.log("vault");

    console.log(`vault.address: ${vault.address}`);
    console.log(`treasury.address: ${treasury.address}`);

    const HEC_ID = 1;
    const LQDR_ID = 2;
    const SINGLE_ID = 3;
    const xTarot_ID = 4;
    const ORBS_ID = 5;
    const GALCX_ID = 6;
    const SD_ID = 7;

    const WFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";

    const HEC = "0x5C4FDfc5233f935f20D2aDbA572F770c2E377Ab0";
    const LQDR = "0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9";
    const GALCX = "0x70F9fd19f857411b089977E7916c05A0fc477Ac9";
    const SD = "0x412a13C109aC30f0dB80AD3Bd1DeFd5D0A6c0Ac6";
    const SINGLE = "0x8cc97B50Fe87f31770bcdCd6bc8603bC1558380B";
    const xTarot = "0x74D1D2A851e339B8cB953716445Be7E8aBdf92F4";
    const ORBS = "0x3E01B7E242D5AF8064cB9A8F9468aC0f8683617c";

    // Intermediate tokens
    const USDC = "0x04068da6c83afcfa0e13ba15a6696662335d5b75";
    const DAI = "0x8d11ec38a3eb5e956b052f67da8bdc9bef8abf3e";

    strategy = await hre.upgrades.deployProxy(
      StrategyIMPL,
      [
        vault.address,
        [treasuryAddr, paymentSplitterAddress],
        [strategistAddress],
        [superAdminAddress, adminAddress, guardianAddress],
      ],
      {kind: 'uups'},
    );
    console.log("strategy");

    paymentRouter = await PaymentRouter.attach(paymentRouterAddress);
    await paymentRouter
      .connect(strategist)
      .addStrategy(strategy.address, [strategistAddress], [100]);

    // const TUSD_PATHS = [TUSD, USDC, WFTM];
    // const SPA_PATHS = [SPA, DAI, WFTM];
    const HEC_PATHS = [HEC, USDC, WFTM];
    const SD_PATHS = [SD, USDC, WFTM];

    const Tarot = "0xC5e2B037D30a390e62180970B3aa4E91868764cD";

    const tx1 = await strategy.setRoute(HEC_ID, HEC_PATHS);
    const tx2 = await strategy.setRoute(LQDR_ID, [LQDR, WFTM]);
    const tx3 = await strategy.setRoute(GALCX_ID, [GALCX, WFTM]);
    const tx4 = await strategy.setRoute(SD_ID, SD_PATHS);
    const tx5 = await strategy.setRoute(xTarot_ID, [Tarot, WFTM]);
    const tx6 = await strategy.setRoute(ORBS_ID, [ORBS, USDC, WFTM]);
    const tx7 = await strategy.setRoute(SINGLE_ID, [SINGLE, USDC, WFTM]);


    await tx1.wait();
    await tx2.wait();
    await tx3.wait();
    await tx4.wait();
    await tx5.wait();
    await tx6.wait();
    await tx7.wait();
  

    await vault.initialize(strategy.address);

    console.log(`Strategy deployed to ${strategy.address}`);
    console.log(`Vault deployed to ${vault.address}`);
    console.log(`Treasury deployed to ${treasury.address}`);

    //approving LP token and vault share spend
    await boo.approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvals1");
    // await vault.approve(vault.address, ethers.utils.parseEther("1000000000"));
    // console.log("approvals2");
    await boo
      .connect(self)
      .approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvalsi");
    // await vault
    //   .connect(self)
    //   .approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvals4");
    await boo
      .connect(booWhale)
      .approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvals5");
    await vault
      .connect(booWhale)
      .approve(vault.address, ethers.utils.parseEther("1000000000"));
    await boo
      .connect(bigBooWhale)
      .approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvals5");
    await vault
      .connect(bigBooWhale)
      .approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvals6");

    await boo
    .connect(bigBooWhale)
    .transfer(booHolder, ethers.utils.parseEther("1000"));
    console.log("transfer 1000 boo to self address");

    MagicatsHandler = await ethers.getContractFactory("magicatsHandler");
    magicatsHandler = await MagicatsHandler.deploy(
        strategy.address,
        vault.address
    );


    await strategy.updateMagicatsHandler(magicatsHandler.address);
    await strategy.approveMagicats();


    //const bigWhaleDepositAmount = ethers.utils.parseEther("100000");
    const bigWhaleDepositAmount = ethers.utils.parseEther("1000");
    await vault.connect(bigBooWhale).deposit(bigWhaleDepositAmount);
    console.log("bigdeposit");
    const hecAlloc = 2000
    const lqdrAlloc = 0;
    const SingleAlloc = 0; //underperforming in tests
    const orbsAlloc = 3000
    const galcxalloc = 1500
    const SDAlloc = 1500
    const xTarotAlloc = 2000;
    balance = await strategy.totalPoolBalance();
    console.log(balance.toString());
    const newAlloc = [
    (balance).mul(hecAlloc).div("10000"), 
    (balance).mul(xTarotAlloc).div("10000"),
    (balance).mul(orbsAlloc).div("10000"), 
    (balance).mul(galcxalloc).div("10000"), 
    (balance).mul(SDAlloc).div("10000")];
    const pids = [HEC_ID, xTarot_ID, ORBS_ID, GALCX_ID, SD_ID];
    await strategy.setXBooAllocations(pids, newAlloc);
    console.log("set allocations");

    magicats = await ethers.getContractAt("IMagicat","0x2aB5C606a5AA2352f8072B9e2E8A213033e2c4c9");
    xboo = await ethers.getContractAt("IBooMirrorWorld", xBooAddress);
    console.log("magicats attached");

    return {
      vault, strategy, boo, acelab, magicatsHandler, magicats, xboo,
      self, selfAddress, booWhale, bigBooWhale, strategistAddress,
      HEC_ID, LQDR_ID, SINGLE_ID, xTarot_ID, ORBS_ID, GALCX_ID, SD_ID

    }
  }

  describe("Magicats Functions", function () {
    xit("should be able to deposit and withdraw magicats", async function () {
        const {
        vault, strategy, boo, acelab, magicatsHandler, magicats, xboo,
        self, selfAddress, booWhale, bigBooWhale, strategistAddress,
        HEC_ID, LQDR_ID, SINGLE_ID, xTarot_ID, ORBS_ID, GALCX_ID, SD_ID} 
        = await loadFixture(deploySetup);

        const magicatIds = await magicatsHandler.connect(self).getDepositableMagicats(selfAddress);
        console.log(`magicats IDS %s: ${magicatIds}, available for deposit`);
        await magicats.connect(self).setApprovalForAll(magicatsHandler.address, true);
        console.log(`approvals set`);
        await magicatsHandler.connect(self).deposit(magicatIds);

        await magicatsHandler.connect(self).setApprovalForAll(magicatsHandler.address, true);

        await magicatsHandler.connect(self).withdraw(magicatIds);
        await magicatsHandler.connect(self).deposit(magicatIds);
        await magicatsHandler.connect(strategist).updateStakedMagicats(GALCX_ID, magicatIds,[]);
        await magicatsHandler.connect(self).withdraw(magicatIds);

    });
    xit("should be able to see increased yield from the addition of magicat staking", async function(){
        const {
            vault, strategy, boo, acelab, magicatsHandler, magicats,
            self, selfAddress, booWhale, bigBooWhale, strategistAddress,
            HEC_ID, LQDR_ID, SINGLE_ID, xTarot_ID, ORBS_ID, GALCX_ID, SD_ID} 
            = await loadFixture(deploySetup);
    
            const magicatIds = await magicatsHandler.connect(self).getDepositableMagicats(selfAddress);
            console.log(`magicats IDS %s: ${magicatIds}, available for deposit`);
            await magicats.connect(self).setApprovalForAll(magicatsHandler.address, true);
            console.log(`approvals set`);
            await magicatsHandler.connect(self).deposit(magicatIds);
    
            await magicatsHandler.connect(self).setApprovalForAll(magicatsHandler.address, true);
    
            //BEFORE MAGICATS ARE STAKED
            const minute = 60;
            const hour = 60 * minute;
            await moveTimeForward(13 * hour);
            await updatePools(acelab);
            await strategy.harvest();
            await moveTimeForward(13 * hour);
            let apr = await strategy.averageAPRAcrossLastNHarvests(6);
            console.log(`apr0: ${apr}`);
            await strategy.harvest();
            await moveTimeForward(13 * hour);
            apr = await strategy.averageAPRAcrossLastNHarvests(6);
            console.log(`apr1: ${apr}`);
            await strategy.harvest();
            await moveTimeForward(13 * hour);
            apr = await strategy.averageAPRAcrossLastNHarvests(6);
            console.log(`apr2: ${apr}`);
            await strategy.harvest();
            await moveTimeForward(13 * hour);
            apr = await strategy.averageAPRAcrossLastNHarvests(6);
            console.log(`apr3: ${apr}`);
            await moveTimeForward(13 * hour);
            await strategy.harvest();
            apr = await strategy.averageAPRAcrossLastNHarvests(6);
            console.log(`apr4: ${apr}`);

            await magicatsHandler.connect(strategist).updateStakedMagicats(GALCX_ID, magicatIds,[]);
            console.log("staking magicats into acelab");
            await updatePools(acelab);
            await strategy.harvest();
            await moveTimeForward(13 * hour);
            apr = await strategy.averageAPRAcrossLastNHarvests(3);
            console.log(`apr1: ${apr}`);
            await strategy.harvest();
            await moveTimeForward(13 * hour);
            apr = await strategy.averageAPRAcrossLastNHarvests(3);
            console.log(`apr2: ${apr}`);
            await strategy.harvest();
            await moveTimeForward(13 * hour);
            apr = await strategy.averageAPRAcrossLastNHarvests(3);
            console.log(`apr3: ${apr}`);
            await strategy.harvest();
            await moveTimeForward(13 * hour);
            apr = await strategy.averageAPRAcrossLastNHarvests(3);
            console.log(`apr4: ${apr}`);
            await strategy.harvest();
            await moveTimeForward(13 * hour);
            apr = await strategy.averageAPRAcrossLastNHarvests(3);
            console.log(`apr5: ${apr}`);
            await strategy.harvest();
            await moveTimeForward(13 * hour);
            apr = await strategy.averageAPRAcrossLastNHarvests(3);
            console.log(`apr6: ${apr}`);

    });
    xit("should be able to claim rewards from magicat Staking", async function (){
        const {
            vault, strategy, boo, acelab, magicatsHandler, magicats, xboo,
            self, selfAddress, booWhale, bigBooWhale, strategistAddress,
            HEC_ID, LQDR_ID, SINGLE_ID, xTarot_ID, ORBS_ID, GALCX_ID, SD_ID} 
            = await loadFixture(deploySetup);
    
        const magicatIds = await magicatsHandler.connect(self).getDepositableMagicats(selfAddress);
        console.log(`magicats IDS %s: ${magicatIds}, available for deposit`);
        await magicats.connect(self).setApprovalForAll(magicatsHandler.address, true);
        console.log(`approvals set`);
        await magicatsHandler.connect(self).deposit(magicatIds);

        await magicatsHandler.connect(self).setApprovalForAll(magicatsHandler.address, true);
        await magicatsHandler.connect(strategist).updateStakedMagicats(GALCX_ID, magicatIds,[]);
        console.log("staking magicats into acelab");
        //BEFORE MAGICATS ARE STAKED
        const minute = 60;
        const hour = 60 * minute;
        await updatePools(acelab);
        await moveTimeForward(13 * hour);
        await strategy.harvest();
        apr = await strategy.averageAPRAcrossLastNHarvests(3);
        console.log(`apr1: ${apr}`);
        xbooBal = await xboo.balanceOf(magicatsHandler.address);
        console.log(`before processing the rewards into vault shares: ${
            ethers.utils.formatEther(xbooBal)
        }`);
        await magicatsHandler.processRewards();
        console.log("rewards handled");
        unclaimedRewards = await magicatsHandler.getMagicatRewards(magicatIds);
        console.log(`deposited magicats have ${unclaimedRewards} in unclaimed rewards`);
        await magicatsHandler.connect(self).claimRewards(magicatIds);
        rewardsClaimed = await vault.balanceOf(selfAddress);
        console.log(`claimed ${ethers.utils.formatEther(rewardsClaimed)} vault shares`);

        await moveTimeForward(13 * hour);
        await strategy.harvest();
        apr = await strategy.averageAPRAcrossLastNHarvests(3);
        console.log(`apr1: ${apr}`);
        await magicatsHandler.processRewards();
        console.log("rewards handled");
        unclaimedRewards = await magicatsHandler.getMagicatRewards(magicatIds);
        console.log(`deposited magicats have ${ethers.utils.formatEther(unclaimedRewards)} in unclaimed rewards`);
        await magicatsHandler.connect(self).claimRewards(magicatIds);
        rewardsClaimed = await vault.balanceOf(selfAddress);
        await moveTimeForward(13 * hour);
        console.log(`claimed ${ethers.utils.formatEther(rewardsClaimed)} vault shares`);
        await strategy.harvest();
        apr = await strategy.averageAPRAcrossLastNHarvests(3);
        console.log(`apr1: ${apr}`);
        await magicatsHandler.processRewards();
        console.log("rewards handled");
        unclaimedRewards = await magicatsHandler.getMagicatRewards(magicatIds);
        console.log(`deposited magicats have ${ethers.utils.formatEther(unclaimedRewards)} in unclaimed rewards`);
        await moveTimeForward(13 * hour);
        await strategy.harvest();
        apr = await strategy.averageAPRAcrossLastNHarvests(3);
        console.log(`apr1: ${apr}`);
        await magicatsHandler.processRewards();
        console.log("rewards handled");
        unclaimedRewards = await magicatsHandler.getMagicatRewards(magicatIds);
        console.log(`deposited magicats have ${ethers.utils.formatEther(unclaimedRewards)}in unclaimed rewards`);
        await magicatsHandler.connect(self).claimRewards(magicatIds);
        rewardsClaimed = await vault.balanceOf(selfAddress);
        console.log(`claimed ${ethers.utils.formatEther(rewardsClaimed)} vault shares`);
    });
    it("should not allow", async function (){
        const {
            vault, strategy, boo, acelab, magicatsHandler, magicats, xboo,
            self, selfAddress, booWhale, bigBooWhale, strategistAddress,
            HEC_ID, LQDR_ID, SINGLE_ID, xTarot_ID, ORBS_ID, GALCX_ID, SD_ID} 
            = await loadFixture(deploySetup);
    
        const magicatIds = await magicatsHandler.connect(self).getDepositableMagicats(selfAddress);
        console.log(`magicats IDS %s: ${magicatIds}, available for deposit`);
        await magicats.connect(self).setApprovalForAll(magicatsHandler.address, true);
        console.log(`approvals set`);
        await magicatsHandler.connect(self).deposit(magicatIds);

        await magicatsHandler.connect(self).setApprovalForAll(magicatsHandler.address, true);
        await magicatsHandler.connect(strategist).updateStakedMagicats(GALCX_ID, magicatIds,[]);
        console.log("staking magicats into acelab");

        console.log(`attempting to claim rewards from wrong address magicat Ids ${magicatIds}`);
        await expect(
            magicatsHandler.connect(bigBooWhale)
            .claimRewards(magicatIds)
            ).to.be.revertedWith("!approved");   

        //should not allow the withdrawal of nfts except by a user or approved party
        console.log(`attempting to withdraw from wrong address magicat Ids ${magicatIds}`);
        await expect(
            magicatsHandler.connect(bigBooWhale)
            .withdraw(magicatIds)
           ).to.be.revertedWith("!approved");
    });
  });
});
