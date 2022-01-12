const hre = require("hardhat");

async function main() {
  const vaultAddress = "0x5b41b141B2eC1C20f4d8186654a60D07b7711E14";
  const Vault = await ethers.getContractFactory("ReaperVaultv1_3");
  const vault = Vault.attach(vaultAddress);
  const options = { gasPrice: 1000000000000, gasLimit: 9000000 };
  await vault.deposit(ethers.utils.parseEther("0.01"), options);
  console.log("deposited!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
