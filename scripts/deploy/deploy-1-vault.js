async function main() {
  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');

  const booAddress = '0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE';
  const tokenName = 'XBOO Single Stake Vault';
  const tokenSymbol = 'rfXBOO';
  const approvalDelay = 86400;
  const depositFee = 0;
  const tvlCap = ethers.utils.parseEther('2500');

  const vault = await Vault.deploy(booAddress, tokenName, tokenSymbol, approvalDelay, depositFee, tvlCap);

  await vault.deployed();
  console.log('Vault deployed to:', vault.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
