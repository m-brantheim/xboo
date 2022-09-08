async function main() {
  const vaultAddress = "0xA8a4A91cC7432D3700384728C2C72ead77Eb8d9e";
  const strategyAddress = "0xE970Dd7F7dcDbB5C5167C85DDBD8d9E1b44cF1fd";

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
