const hre = require("hardhat");

async function main() {
  const vaultAddress = "0x65bbD82baF32aAF96d82081b2eB332f8A76F5058";
  const Vault = await ethers.getContractFactory("ReaperVaultv1_3");
  const vault = Vault.attach(vaultAddress);
  //const options = { gasPrice: 1000000000000, gasLimit: 9000000 };
  await vault.withdrawAll();
  console.log("withdrew!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
