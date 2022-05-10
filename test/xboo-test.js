const pools = require("../pools.json");
const hre = require("hardhat");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");
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

describe("Vaults", function () {
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
  let selfAddress;
  let strategist;
  let owner;

  beforeEach(async function () {
    //reset network
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: "https://rpc.ftm.tools/",
            blockNumber: 37974400,
          },
        },
      ],
    });
    console.log("providers");
    //get signers
    [owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners();
    const booHolder = "0x7Ba7f4773fa7890BaD57879F0a1Faa0eDffB3520";
    const booWhaleAddress = "0xF44813dDc3a9D672bD55DcC4E14d46E32fb87673";
    const bigBooWhaleAddress = "0xf778f4d7a14a8cb73d5261f9c61970ef4e7d7842";
    const strategistAddress = "0x3b410908e71Ee04e7dE2a87f8F9003AFe6c1c7cE";
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
    self = await ethers.provider.getSigner(booHolder);
    booWhale = await ethers.provider.getSigner(booWhaleAddress);
    bigBooWhale = await ethers.provider.getSigner(bigBooWhaleAddress);
    strategist = await ethers.provider.getSigner(strategistAddress);
    await self.sendTransaction({
      to: bigBooWhaleAddress,
      value: ethers.utils.parseEther("0.1"),
    });
    selfAddress = await self.getAddress();
    ownerAddress = await owner.getAddress();
    console.log("addresses");

    //get artifacts
    Strategy = await ethers.getContractFactory("ReaperAutoCompoundXBoo");
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
    const aceLabAddress = "0x2352b745561e7e6FCD03c093cE7220e3e126ace0";
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

    // const WFTM_ID = 2;
    // const WOO_ID = 8;
    // const TREEB_ID = 9;
    // const FONT_ID = 10;
    // const YEL_ID = 16;
    // const TUSD_ID = 17;
    // const YOSHI_ID = 18;
    // const SPA_ID = 19;
    // const OOE_ID = 22;
    // const HND_ID = 23;
    // const BRUSH_ID = 24;

    // const WOO = "0x6626c47c00F1D87902fc13EECfaC3ed06D5E8D8a";
    // const TREEB = "0xc60D7067dfBc6f2caf30523a064f416A5Af52963";
    // const FONT = "0xbbc4A8d076F4B1888fec42581B6fc58d242CF2D5";
    // const YEL = "0xD3b71117E6C1558c1553305b44988cd944e97300";
    // const TUSD = "0x9879aBDea01a879644185341F7aF7d8343556B7a";
    // const YOSHI = "0x3dc57B391262e3aAe37a08D91241f9bA9d58b570";
    // const SPA = "0x5602df4A94eB6C680190ACCFA2A475621E0ddBdc";
    // const OOE = "0x9d8F97A3C2f9f397B6D46Cbe2d39CC1D8Cf19010";
    // const HND = "0x10010078a54396F62c96dF8532dc2B4847d47ED3";
    // const BRUSH = "0x85dec8c4B2680793661bCA91a8F129607571863d";

    const HEC_ID = 21;
    const LQDR_ID = 11;
    const GALCX_ID = 35;
    const SD_ID = 34;
    const LUNA_ID = 33;
    const BEFTM_ID = 32;
    const RING_ID = 31;
    const SOLID_ID = 30;

    const WFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";

    const HEC = "0x5C4FDfc5233f935f20D2aDbA572F770c2E377Ab0";
    const LQDR = "0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9";
    const GALCX = "0x70F9fd19f857411b089977E7916c05A0fc477Ac9";
    const SD = "0x412a13C109aC30f0dB80AD3Bd1DeFd5D0A6c0Ac6";
    const LUNA = "0x593AE1d34c8BD7587C11D539E4F42BFf242c82Af";
    const BEFTM = "0x7381eD41F6dE418DdE5e84B55590422a57917886";
    const RING = "0x582423C10c9e83387a96d00A69bA3D11ee47B7b5";
    const SOLID = "0x888EF71766ca594DED1F0FA3AE64eD2941740A20";

    // Intermediate tokens
    const USDC = "0x04068da6c83afcfa0e13ba15a6696662335d5b75";
    const DAI = "0x8d11ec38a3eb5e956b052f67da8bdc9bef8abf3e";

    strategy = await Strategy.deploy(
      vault.address,
      [treasury.address, paymentRouterAddress],
      [strategistAddress]
    );
    console.log("strategy");

    paymentRouter = await PaymentRouter.attach(paymentRouterAddress);
    await paymentRouter
      .connect(strategist)
      .addStrategy(strategy.address, [strategistAddress], [100]);

    // const TUSD_PATHS = [TUSD, USDC, WFTM];
    // const SPA_PATHS = [SPA, DAI, WFTM];
    const HEC_PATHS = [HEC, DAI, WFTM];
    const SD_PATHS = [SD, USDC, WFTM];
    const RING_PATHS = [RING, USDC, WFTM];

    const tx1 = await strategy.addUsedPool(HEC_ID, HEC_PATHS);
    const tx2 = await strategy.addUsedPool(LQDR_ID, [LQDR, WFTM]);
    const tx3 = await strategy.addUsedPool(GALCX_ID, [GALCX, WFTM]);
    const tx4 = await strategy.addUsedPool(SD_ID, SD_PATHS);
    const tx5 = await strategy.addUsedPool(LUNA_ID, [LUNA, WFTM]);
    const tx6 = await strategy.addUsedPool(BEFTM_ID, [BEFTM, WFTM]);
    const tx7 = await strategy.addUsedPool(RING_ID, RING_PATHS);
    const tx8 = await strategy.addUsedPool(SOLID_ID, [SOLID, WFTM]);

    // const tx1 = await strategy.addUsedPool(WFTM_ID, [WFTM, WFTM]);
    // const tx2 = await strategy.addUsedPool(WOO_ID, [WOO, WFTM]);
    // const tx3 = await strategy.addUsedPool(TREEB_ID, [TREEB, WFTM]);
    // const tx4 = await strategy.addUsedPool(FONT_ID, [FONT, WFTM]);
    // const tx6 = await strategy.addUsedPool(YEL_ID, [YEL, WFTM]);
    // const tx7 = await strategy.addUsedPool(TUSD_ID, TUSD_PATHS);
    // const tx8 = await strategy.addUsedPool(YOSHI_ID, [YOSHI, WFTM]);
    // const tx9 = await strategy.addUsedPool(SPA_ID, SPA_PATHS);
    // const tx11 = await strategy.addUsedPool(OOE_ID, [OOE, WFTM]);
    // const tx12 = await strategy.addUsedPool(HND_ID, [HND, WFTM]);
    // const tx13 = await strategy.addUsedPool(BRUSH_ID, [BRUSH, WFTM]);

    await tx1.wait();
    await tx2.wait();
    await tx3.wait();
    await tx4.wait();
    await tx5.wait();
    await tx6.wait();
    await tx7.wait();
    await tx8.wait();

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
  });

  describe("Deploying the vault and strategy", function () {
    it("should initiate vault with a 0 balance", async function () {
      console.log(1);
      const totalBalance = await vault.balance();
      console.log(2);
      const availableBalance = await vault.available();
      console.log(i);
      const pricePerFullShare = await vault.getPricePerFullShare();
      console.log(4);
      expect(totalBalance).to.equal(0);
      console.log(5);
      expect(availableBalance).to.equal(0);
      console.log(6);
      expect(pricePerFullShare).to.equal(ethers.utils.parseEther("1"));
    });
  });
  describe("Vault Tests", function () {
    it("should allow deposits and account for them correctly", async function () {
      const userBalance = await boo.balanceOf(selfAddress);
      console.log(1);
      console.log(`userBalance: ${userBalance}`);
      const vaultBalance = await vault.balance();
      console.log("vaultBalance");
      console.log(vaultBalance);
      console.log(2);
      const depositAmount = ethers.utils.parseEther(".1");
      console.log("depositAmount");
      console.log(depositAmount);
      console.log(i);
      await vault.connect(self).deposit(depositAmount);
      console.log(4);
      const newVaultBalance = await vault.balance();
      console.log(`newVaultBalance: ${newVaultBalance}`);
      console.log(`depositAmount: ${depositAmount}`);
      const newUserBalance = await boo.balanceOf(selfAddress);

      console.log(`newUserBalance: ${newUserBalance}`);
      console.log(
        `userBalance - depositAmount: ${userBalance - depositAmount}`
      );
      console.log(
        `userBalance - newUserBalance: ${userBalance - newUserBalance}`
      );
      const deductedAmount = userBalance.sub(newUserBalance);
      console.log("deductedAmount");
      console.log(deductedAmount);
      const isSmallBalanceDifference = depositAmount.sub(newVaultBalance) < 5;
      expect(vaultBalance).to.equal(0);
      expect(isSmallBalanceDifference).to.equal(true);
      expect(deductedAmount).to.equal(depositAmount);
    });
    it("should mint user their pool share", async function () {
      console.log("---------------------------------------------");
      const userBalance = await boo.balanceOf(selfAddress);
      console.log(userBalance.toString());
      const selfDepositAmount = ethers.utils.parseEther("0.005");
      await vault.connect(self).deposit(selfDepositAmount);
      console.log((await vault.balance()).toString());

      const whaleDepositAmount = ethers.utils.parseEther("100");
      await vault.connect(booWhale).deposit(whaleDepositAmount);
      console.log((await vault.balance()).toString());
      // console.log((await boo.balanceOf(selfAddress)).toString());
      // const selfBooBalance = await vault.balanceOf(selfAddress);
      // console.log(selfBooBalance.toString());
      const ownerDepositAmount = ethers.utils.parseEther("5");
      await boo.connect(self).transfer(ownerAddress, ownerDepositAmount);
      const ownerBalance = await boo.balanceOf(ownerAddress);

      console.log(ownerBalance.toString());
      await vault.deposit(ownerDepositAmount);
      console.log((await vault.balance()).toString());
      const ownerVaultBooBalance = await vault.balanceOf(ownerAddress);
      console.log(ownerVaultBooBalance.toString());
      await vault.withdraw(ownerVaultBooBalance);
      const ownerBooBalance = await boo.balanceOf(ownerAddress);
      console.log(`ownerBooBalance: ${ownerBooBalance}`);
      const ownerVaultBooBalanceAfterWithdraw = await vault.balanceOf(
        ownerAddress
      );
      console.log(
        `ownerVaultBooBalanceAfterWithdraw: ${ownerVaultBooBalanceAfterWithdraw}`
      );
      // expect(ownerBooBalance).to.equal(ownerDepositAmount);
      // expect(selfBooBalance).to.equal(selfDepositAmount);
    });
    it("should allow withdrawals", async function () {
      const userBalance = await boo.balanceOf(selfAddress);
      console.log(`userBalance: ${userBalance}`);
      const depositAmount = ethers.BigNumber.from(ethers.utils.parseEther("1"));
      await vault.connect(self).deposit(depositAmount);
      console.log(
        `await boo.balanceOf(selfAddress): ${await boo.balanceOf(selfAddress)}`
      );
      const whaleDepositAmount = ethers.utils.parseEther("100");
      await vault.connect(booWhale).deposit(whaleDepositAmount);
      const newUserBalance = userBalance.sub(depositAmount);
      const tokenBalance = await boo.balanceOf(selfAddress);
      const balanceDifferenceIsZero = tokenBalance.sub(newUserBalance).isZero();
      expect(balanceDifferenceIsZero).to.equal(true);
      await vault.connect(self).withdraw(depositAmount);
      console.log(
        `await boo.balanceOf(selfAddress): ${await boo.balanceOf(selfAddress)}`
      );
      const newUserVaultBalance = await vault.balanceOf(selfAddress);
      console.log(`newUserVaultBalance: ${newUserVaultBalance}`);
      const userBalanceAfterWithdraw = await boo.balanceOf(selfAddress);
      const securityFee = 10;
      const percentDivisor = 10000;
      const withdrawFee = (depositAmount * securityFee) / percentDivisor;
      const expectedBalance = userBalance.sub(withdrawFee);
      const isSmallBalanceDifference =
        expectedBalance.sub(userBalanceAfterWithdraw) < 5;
      expect(isSmallBalanceDifference).to.equal(true);
    });
    it("should handle small deposit + withdraw", async function () {
      const userBalance = await boo.balanceOf(selfAddress);
      console.log(`userBalance: ${userBalance}`);
      const depositAmount = ethers.BigNumber.from(
        ethers.utils.parseEther("0.0000000000001")
      );
      await vault.connect(self).deposit(depositAmount);
      console.log(
        `await boo.balanceOf(selfAddress): ${await boo.balanceOf(selfAddress)}`
      );

      await vault.connect(self).withdraw(depositAmount);
      console.log(
        `await boo.balanceOf(selfAddress): ${await boo.balanceOf(selfAddress)}`
      );
      const newUserVaultBalance = await vault.balanceOf(selfAddress);
      console.log(`newUserVaultBalance: ${newUserVaultBalance}`);
      const userBalanceAfterWithdraw = await boo.balanceOf(selfAddress);
      const securityFee = 10;
      const percentDivisor = 10000;
      const withdrawFee = (depositAmount * securityFee) / percentDivisor;
      const expectedBalance = userBalance.sub(withdrawFee);
      const isSmallBalanceDifference =
        expectedBalance.sub(userBalanceAfterWithdraw) < 5;
      expect(isSmallBalanceDifference).to.equal(true);
    });
    it("should be able to harvest", async function () {
      await vault.connect(self).deposit(100000);
      const estimatedGas = await strategy.estimateGas.harvest();
      console.log(`estimatedGas: ${estimatedGas}`);
      await strategy.connect(self).harvest();
    });
    it("should provide yield", async function () {
      await strategy.connect(self).harvest();
      const depositAmount = ethers.utils.parseEther(".05");
      await vault.connect(self).deposit(depositAmount);
      const vaultBalance = await vault.balance();
      console.log(`vaultBalance: ${vaultBalance}`);
      console.log(`depositAmount: ${depositAmount}`);

      await strategy.connect(self).harvest();
      const newVaultBalance = await vault.balance();
      console.log(`newVaultBalance: ${newVaultBalance}`);
      const whaleDepositAmount = ethers.utils.parseEther("41826");
      await vault.connect(booWhale).deposit(whaleDepositAmount);
      const bigWhaleDepositAmount = ethers.utils.parseEther("233977");
      await vault.connect(bigBooWhale).deposit(bigWhaleDepositAmount);
      const minute = 60;
      const hour = 60 * minute;
      const day = 24 * hour;
      await moveTimeForward(10 * day);
      await updatePools(acelab);
      await strategy.connect(self).harvest();
      const newVaultBalance2 = await vault.balance();
      console.log(`newVaultBalance2: ${newVaultBalance2}`);
      const totalDepositAmount = depositAmount
        .add(whaleDepositAmount)
        .add(bigWhaleDepositAmount);
      console.log(`totalDepositAmount: ${totalDepositAmount}`);
      const hasYield = newVaultBalance2 > totalDepositAmount;
      console.log(`hasYield: ${hasYield}`);
      expect(hasYield).to.equal(true);

      const timeToSkip = 3600;
      const numHarvests = 5;
      for (let i = 0; i < numHarvests; i++) {
        await moveTimeForward(timeToSkip);
        await strategy.harvest();
      }

      const averageAPR = await strategy.averageAPRAcrossLastNHarvests(
        numHarvests
      );
      console.log(
        `Average APR across ${numHarvests} harvests is ${averageAPR} basis points.`
      );
    });
  });
  describe("Strategy", function () {
    it("should be able to remove a pool", async function () {
      await strategy.connect(self).harvest();
      const bigWhaleDepositAmount = ethers.utils.parseEther("233977");
      await vault.connect(bigBooWhale).deposit(bigWhaleDepositAmount);
      await strategy.connect(self).harvest();

      const lqdrPoolId = 11;
      const lqdrIndex = 1;
      const treebPoolBalance = await strategy.poolxTokenBalance(lqdrPoolId);
      console.log(`treebPoolBalance: ${treebPoolBalance}`);
      const vaultBalance = await vault.balance();

      const tx = await strategy.removeUsedPool(lqdrIndex);
      await tx.wait();

      const newVaultBalance = await vault.balance();
      const newTreebPoolBalance = await strategy.poolxTokenBalance(lqdrPoolId);
      console.log(`newTreebPoolBalance: ${newTreebPoolBalance}`);

      // Make sure harvest can run without error after removing
      await strategy.connect(self).harvest();
      console.log(`vaultBalance: ${vaultBalance}`);
      console.log(`newVaultBalance: ${newVaultBalance}`);

      const isSmallBalanceDifference =
        Math.abs(vaultBalance.sub(newVaultBalance)) < 5;

      expect(newTreebPoolBalance).to.equal(0);
      expect(isSmallBalanceDifference).to.equal(true);
    });
    it("should be able to pause and unpause", async function () {
      await strategy.pause();
      const depositAmount = ethers.utils.parseEther(".05");
      await expect(vault.connect(self).deposit(depositAmount)).to.be.reverted;
      await strategy.unpause();
      await expect(vault.connect(self).deposit(depositAmount)).to.not.be
        .reverted;
    });
    it("should be able to panic", async function () {
      const depositAmount = ethers.utils.parseEther(".05");
      await vault.connect(self).deposit(depositAmount);
      const vaultBalance = await vault.balance();
      const strategyBalance = await strategy.balanceOf();
      await strategy.panic();
      expect(vaultBalance).to.equal(strategyBalance);
      // Accounting is not updated when panicking so newVaultBalance is 2x expected
      await strategy.updateInternalAccounting();
      const newVaultBalance = await vault.balance();
      const newStrategyBalance = await strategy.balanceOf();
      expect(newVaultBalance).to.equal(vaultBalance);
      expect(newStrategyBalance).to.equal(0);
    });
    it("should be able to retire strategy", async function () {
      const depositAmount = ethers.utils.parseEther(".05");
      await vault.connect(self).deposit(depositAmount);
      const vaultBalance = await vault.balance();
      const strategyBalance = await strategy.balanceOf();
      expect(vaultBalance).to.equal(strategyBalance);
      // Test needs the require statement to be commented out during the test
      await expect(strategy.retireStrat()).to.not.be.reverted;
      const newVaultBalance = await vault.balance();
      const newStrategyBalance = await strategy.balanceOf();
      expect(newVaultBalance).to.gte(vaultBalance);
      expect(newStrategyBalance).to.equal(0);
    });
    it("should be able to retire strategy with no balance", async function () {
      // Test needs the require statement to be commented out during the test
      await expect(strategy.retireStrat()).to.not.be.reverted;
    });
    it("should be able to estimate harvest", async function () {
      const bigWhaleDepositAmount = ethers.utils.parseEther("233977");
      await vault.connect(bigBooWhale).deposit(bigWhaleDepositAmount);
      await strategy.harvest();
      const minute = 60;
      const hour = 60 * minute;
      const day = 24 * hour;
      await moveTimeForward(10 * day);
      await updatePools(acelab);
      const [profit, callFeeToUser] = await strategy.estimateHarvest();
      const hasProfit = profit.gt(0);
      const hasCallFee = callFeeToUser.gt(0);
      expect(hasProfit).to.equal(true);
      expect(hasCallFee).to.equal(true);
    });
    it("should include free rewards in estimate harvest", async function () {
      const bigWhaleDepositAmount = ethers.utils.parseEther("233977");
      await vault.connect(bigBooWhale).deposit(bigWhaleDepositAmount);
      await strategy.harvest();
      const minute = 60;
      const hour = 60 * minute;
      const day = 24 * hour;
      await moveTimeForward(10 * day);
      await updatePools(acelab);
      await vault.connect(bigBooWhale).withdrawAll();
      const [profit, callFeeToUser] = await strategy.estimateHarvest();
      const hasProfit = profit.gt(0);
      const hasCallFee = callFeeToUser.gt(0);
      expect(hasProfit).to.equal(true);
      expect(hasCallFee).to.equal(true);
    });
    it("should be able to check internal accounting", async function () {
      const bigWhaleDepositAmount = ethers.utils.parseEther("327171");
      await vault.connect(bigBooWhale).deposit(bigWhaleDepositAmount);
      await strategy.harvest();
      const minute = 60;
      const hour = 60 * minute;
      const day = 24 * hour;
      await moveTimeForward(10 * day);
      await updatePools(acelab);
      const isAccurate = await strategy.isInternalAccountingAccurate();
      expect(isAccurate).to.equal(true);
    });
    it("should be able to update internal accounting", async function () {
      const bigWhaleDepositAmount = ethers.utils.parseEther("327171");
      await vault.connect(bigBooWhale).deposit(bigWhaleDepositAmount);
      await strategy.harvest();
      const minute = 60;
      const hour = 60 * minute;
      const day = 24 * hour;
      await moveTimeForward(10 * day);
      await updatePools(acelab);
      await expect(strategy.updateInternalAccounting()).to.not.be.reverted;
    });
    it("cannot add pools past the max cap", async function () {
      const TFTM_ID = 0;
      const WFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";

      const maxCap = 15;
      const nrOfPoolsAdded = 14;
      for (let index = nrOfPoolsAdded - 1; index < maxCap + 1; index++) {
        console.log(index);
        if (index < maxCap) {
          await expect(strategy.addUsedPool(TFTM_ID, [WFTM, WFTM])).to.not.be
            .reverted;
        } else {
          await expect(strategy.addUsedPool(TFTM_ID, [WFTM, WFTM])).to.be
            .reverted;
          console.log("reverted");
        }
      }
    });
    xit("should include xBoo gains in yield calculation", async function () {
      const deposit = ethers.utils.parseEther("1");
      const xBoodeposit1 = ethers.utils.parseEther("10");
      const xBoodeposit2 = ethers.utils.parseEther("100");
      const xBoodeposit3 = ethers.utils.parseEther("1000");
      const xBoodeposit4 = ethers.utils.parseEther("10000");
      const xBoodeposit5 = ethers.utils.parseEther("100000");
      await vault.connect(bigBooWhale).deposit(deposit);
      await strategy.harvest();
      const minute = 60;
      const hour = 60 * minute;
      await moveTimeForward(13 * hour);
      await boo.connect(bigBooWhale).transfer(xBooAddress, xBoodeposit1);
      const [xBooProfit1] = await strategy.estimateHarvest();
      console.log(`xBooProfit1: ${xBooProfit1}`);
      await strategy.harvest();
      await moveTimeForward(13 * hour);
      await boo.connect(bigBooWhale).transfer(xBooAddress, xBoodeposit2);
      const [xBooProfit2] = await strategy.estimateHarvest();
      console.log(`xBooProfit2: ${xBooProfit2}`);
      let apr = await strategy.averageAPRAcrossLastNHarvests(6);
      console.log(`apr: ${apr}`);
      await strategy.harvest();
      await moveTimeForward(13 * hour);
      await boo.connect(bigBooWhale).transfer(xBooAddress, xBoodeposit3);
      const [xBooProfit3] = await strategy.estimateHarvest();
      console.log(`xBooProfit3: ${xBooProfit3}`);
      apr = await strategy.averageAPRAcrossLastNHarvests(6);
      console.log(`apr: ${apr}`);
      await strategy.harvest();
      await moveTimeForward(13 * hour);
      await boo.connect(bigBooWhale).transfer(xBooAddress, xBoodeposit4);
      const [xBooProfit4] = await strategy.estimateHarvest();
      console.log(`xBooProfit4: ${xBooProfit4}`);
      apr = await strategy.averageAPRAcrossLastNHarvests(6);
      console.log(`apr: ${apr}`);
      await strategy.harvest();
      await moveTimeForward(13 * hour);
      await boo.connect(bigBooWhale).transfer(xBooAddress, xBoodeposit5);
      const [xBooProfit5] = await strategy.estimateHarvest();
      console.log(`xBooProfit5: ${xBooProfit5}`);
      apr = await strategy.averageAPRAcrossLastNHarvests(6);
      console.log(`apr: ${apr}`);
      await strategy.harvest();
      apr = await strategy.averageAPRAcrossLastNHarvests(6);
      console.log(`apr: ${apr}`);
    });
    xit("should correctly calculate APR even if harvests are more frequent than log cadence", async function () {
      const deposit = ethers.utils.parseEther("1");
      const xBoodeposit = ethers.utils.parseEther("100");
      await vault.connect(bigBooWhale).deposit(deposit);
      await strategy.harvest();
      const minute = 60;
      const hour = 60 * minute;
      await strategy.updateHarvestLogCadence(6 * hour);
      await moveTimeForward(6 * hour);
      await boo.connect(bigBooWhale).transfer(xBooAddress, xBoodeposit);
      const [xBooProfit1] = await strategy.estimateHarvest();
      console.log(`xBooProfit1: ${xBooProfit1}`);
      await strategy.harvest();
      await moveTimeForward(1 * hour);
      await boo.connect(bigBooWhale).transfer(xBooAddress, xBoodeposit);
      const [xBooProfit2] = await strategy.estimateHarvest();
      console.log(`xBooProfit2: ${xBooProfit2}`);
      let apr = await strategy.averageAPRAcrossLastNHarvests(6);
      console.log(`apr: ${apr}`);
      await strategy.harvest();
      await moveTimeForward(1 * hour);
      await boo.connect(bigBooWhale).transfer(xBooAddress, xBoodeposit);
      const [xBooProfit3] = await strategy.estimateHarvest();
      console.log(`xBooProfit3: ${xBooProfit3}`);
      apr = await strategy.averageAPRAcrossLastNHarvests(6);
      console.log(`apr: ${apr}`);
      await strategy.harvest();
      await moveTimeForward(1 * hour);
      await boo.connect(bigBooWhale).transfer(xBooAddress, xBoodeposit);
      const [xBooProfit4] = await strategy.estimateHarvest();
      console.log(`xBooProfit4: ${xBooProfit4}`);
      apr = await strategy.averageAPRAcrossLastNHarvests(6);
      console.log(`apr: ${apr}`);
      await strategy.harvest();
      await moveTimeForward(8 * hour);
      await boo.connect(bigBooWhale).transfer(xBooAddress, xBoodeposit);
      const [xBooProfit5] = await strategy.estimateHarvest();
      console.log(`xBooProfit5: ${xBooProfit5}`);
      apr = await strategy.averageAPRAcrossLastNHarvests(6);
      console.log(`apr: ${apr}`);
      await strategy.harvest();
      apr = await strategy.averageAPRAcrossLastNHarvests(6);
      console.log(`apr: ${apr}`);
    });
    xit("should handle tvl drop between harvests", async function () {
      const deposit = ethers.utils.parseEther("100000");
      await vault.connect(bigBooWhale).deposit(deposit);
      await strategy.harvest();
      const minute = 60;
      const hour = 60 * minute;
      await moveTimeForward(13 * hour);
      await strategy.harvest();

      await moveTimeForward(13 * hour);
      await vault.connect(bigBooWhale).withdraw(deposit.div(2));
      await strategy.harvest();
    });
  });
});
