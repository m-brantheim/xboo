const hre = require("hardhat");

async function main() {
  const vaultAddress = "0x0F5A4F4B82e6A717869Df5D08DEc600CE7B311b6";
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
