async function main() {
  const vaultAddress = '0x1F7BCFF7710529c3d7876375962A42c5D3B545B6';
  const strategyAddress = '0x459a10d6d4Fb3034C9AFC4150be15ABcb0052b4A';
  const strategist1 = '0x1E71AEE6081f62053123140aacC7a06021D77348';
  const strategist2 = '0x81876677843D00a7D792E1617459aC2E93202576';
  const strategist3 = '0x1A20D7A31e5B3Bc5f02c8A146EF6f394502a10c4';
  const strategist4 = '0x60BC5E0440C867eEb4CbcE84bB1123fad2b262B1';
  const superAdmin = '0x04C710a1E8a738CDf7cAD3a52Ba77A784C35d8CE';
  const admin = '0x539eF36C804e4D735d8cAb69e8e441c12d4B88E0';

  // get artifacts
  const MagicatsHandlerUpgradeable = await ethers.getContractFactory('MagicatsHandlerUpgradeable');

  const magicatsHandlerUpgradeable = await hre.upgrades.deployProxy(
    MagicatsHandlerUpgradeable,
    [
      strategyAddress,
      vaultAddress,
      [strategist1, strategist2, strategist3, strategist4], //strategists
      [superAdmin, admin], //multisigRoles
    ],
    {kind: 'uups'},
  );

  await magicatsHandlerUpgradeable.deployed();

  console.log('MagicatsHandlerUpgradeable deployed to:', magicatsHandlerUpgradeable.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
