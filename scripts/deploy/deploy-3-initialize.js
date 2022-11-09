async function main() {
  const vaultAddress = '0x9A6a9d4173e66d3d1C696839358B2A8Ae6bc548d';
  const strategyAddress = '0xeC46D0B76A4D9c80Ae70bD19674F2F44278C08ae';

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
