const hre = require("hardhat");

async function main() {
  const vaultAddress = "0x5b41b141B2eC1C20f4d8186654a60D07b7711E14";
  const Vault = await ethers.getContractFactory("ReaperVaultv1_3");
  const strategyAddress = "0x60E646e4a56bB7aeAF96A1d7CF3869Cb32829C7a";
  const vault = Vault.attach(vaultAddress);

  const options = { gasPrice: 1000000000000, gasLimit: 9000000 };
  await vault.initialize(strategyAddress, options);
  console.log("Vault initialized");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
