async function main() {
  const vaultAddress = "0x9363f618D4d1dF2aA706886D657A82D46d880998";
  const strategyAddress = "0x978139C143E8D82C1e92e17169A14793126ABe49";

  const Vault = await ethers.getContractFactory("ReaperVaultv1_3");
  const vault = Vault.attach(vaultAddress);

  //const options = { gasPrice: 2000000000000, gasLimit: 9000000 };
  await vault.initialize(strategyAddress);
  console.log("Vault initialized");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
