async function main() {
  const vaultAddress = "0x0F5A4F4B82e6A717869Df5D08DEc600CE7B311b6";
  const strategyAddress = "0x0aD9E4D7ef01208fC1e67eD5C3136bEc11d00aaD";

  const Vault = await ethers.getContractFactory("ReaperVaultv1_3");
  const vault = Vault.attach(vaultAddress);

  const options = { gasPrice: 2000000000000, gasLimit: 9000000 };
  await vault.initialize(strategyAddress, options);
  console.log("Vault initialized");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
