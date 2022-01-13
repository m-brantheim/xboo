const { getVault } = require("./vault");

async function main() {
  const vaultAddress = "0x5b41b141B2eC1C20f4d8186654a60D07b7711E14";
  const Vault = await ethers.getContractFactory("ReaperVaultv1_3");
  contract = new ethers.Contract(vaultAddress, Contract.interface, ethers.getDefaultProvider());
  const vault = Vault.attach(vaultAddress);
  const options = { gasPrice: 1000000000000, gasLimit: 9000000 };
  const balance = await vault.balance(options);
  console.log(`balance: ${balance}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
