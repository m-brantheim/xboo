async function main() {
  const vaultAddress = "0xFC550BAD3c14160CBA7bc05ee263b3F060149AFF";
  const strategyAddress = "0xe3D115671cD4100dbD018aeE78C19CFa18055476";

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
