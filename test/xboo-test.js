const pools = require("../pools.json");
const hre = require("hardhat");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");
chai.use(solidity);
const { expect } = chai;

describe("Vaults", function () {
  const i = 0;
  let Vault;
  let Strategy;
  let Treasury;
  let Boo;
  let vault;
  let strategy;
  let treasury;
  let boo;
  let booAddress = "0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE";
  let self;
  let booWhale;
  let selfAddress;
  let owner;
  let addr1;
  let addr2;
  let addri;
  let addr4;
  let addrs;

  beforeEach(async function () {
    //reset network
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: "https://rpc.ftm.tools/",
          },
        },
      ],
    });
    console.log("providers");
    //get signers
    [owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners();
    const booHolder = "0x4b90f32b6a928e1f0d9e261f141b1ea90e1e9256";
    const booWhaleAddress = "0x1f0c5a9046f0db0e8b651cd9e8e23ba4efe4b86d";
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [booHolder],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [booWhaleAddress],
    });
    self = await ethers.provider.getSigner(booHolder);
    booWhale = await ethers.provider.getSigner(booWhaleAddress);
    selfAddress = await self.getAddress();
    ownerAddress = await owner.getAddress();
    console.log("addresses");

    //get artifacts
    Strategy = await ethers.getContractFactory("ReaperAutoCompoundXBoo");
    Vault = await ethers.getContractFactory("ReaperVaultv1_2");
    Treasury = await ethers.getContractFactory("ReaperTreasury");
    Boo = await ethers.getContractFactory("SpookyToken");
    Acelab = await ethers.getContractFactory("AceLab");
    console.log("artifacts");

    //deploy contracts
    treasury = await Treasury.deploy();
    console.log("treasury");
    boo = await Boo.attach(booAddress);
    console.log("boo attached");
    vault = await Vault.deploy(
      booAddress,
      "XBOO Single Stake Vault",
      "rfXBOO",
      432000,
      0
    );
    console.log("vault");

    const uniRouter = "0xF491e7B69E4244ad4002BC14e878a34207E38c29";
    const aceLab = "0x2352b745561e7e6FCD03c093cE7220e3e126ace0";
    console.log(`vault.address: ${vault.address}`);
    console.log(`treasury.address: ${treasury.address}`);

    strategy = await Strategy.deploy(
      uniRouter,
      aceLab,
      booAddress,
      vault.address,
      treasury.address
    );
    console.log("strategy");

    await vault.initialize(strategy.address);

    console.log(`Strategy deployed to ${strategy.address}`);
    console.log(`Vault deployed to ${vault.address}`);
    console.log(`Treasury deployed to ${treasury.address}`);

    //approving LP token and vault share spend
    await boo.approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvals1");
    await vault.approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvals2");
    await boo
      .connect(self)
      .approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvalsi");
    await vault
      .connect(self)
      .approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvals4");
    await boo
      .connect(booWhale)
      .approve(vault.address, ethers.utils.parseEther("1000000000"));
    console.log("approvals5");
    await vault
      .connect(booWhale)
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
      console.log(2);
      const depositAmount = ethers.utils.parseEther(".0001");
      console.log(i);
      await vault.connect(self).deposit(depositAmount);
      console.log(4);
      const newVaultBalance = await vault.balance();
      console.log(`newVaultBalance: ${newVaultBalance}`);
      const newUserBalance = await boo.balanceOf(selfAddress);
      console.log(`newUserBalance: ${newUserBalance}`);
      console.log(
        `userBalance - depositAmount: ${userBalance - depositAmount}`
      );
      console.log(
        `userBalance - newUserBalance: ${userBalance - newUserBalance}`
      );
      const deductedAmount = userBalance - newUserBalance;
      expect(vaultBalance).to.equal(0);
      expect(newVaultBalance).to.equal(depositAmount);
      expect(deductedAmount.toString()).to.equal(depositAmount.toString());
    });
    it("should mint user their pool share", async function () {
      const userBalance = await boo.balanceOf(selfAddress);
      console.log(userBalance.toString());
      const depositAmount = ethers.utils.parseEther("0.0000005");
      await vault.connect(self).deposit(depositAmount);
      console.log((await vault.balance()).toString());
      console.log((await boo.balanceOf(selfAddress)).toString());
      const selfBooBalance = await vault.balanceOf(selfAddress);
      console.log(selfBooBalance.toString());
      await boo.connect(self).transfer(ownerAddress, depositAmount);
      const ownerBalance = await boo.balanceOf(ownerAddress);
      console.log(ownerBalance.toString());
      await vault.deposit(depositAmount);
      const ownerBooBalance = await vault.balanceOf(ownerAddress);
      console.log(ownerBooBalance.toString());
      expect(ownerBooBalance).to.equal(depositAmount);
      expect(selfBooBalance).to.equal(depositAmount);
    });
    it("should allow withdrawals", async function () {});
    it("should be able to harvest", async function () {});
    it("should provide yield", async function () {});
  });
});
