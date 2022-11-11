async function main() {
  const vaultAddress = '0x1F7BCFF7710529c3d7876375962A42c5D3B545B6';
  const strategyAddress = '0x459a10d6d4Fb3034C9AFC4150be15ABcb0052b4A';

  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');
  const vault = Vault.attach(vaultAddress);

  //const options = { gasPrice: 2000000000000, gasLimit: 9000000 };
  await vault.initialize(strategyAddress);
  console.log('Vault initialized');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
