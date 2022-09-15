async function main() {
  const vaultAddress = "0x9363f618D4d1dF2aA706886D657A82D46d880998";
  const strategyAddress = "0x978139C143E8D82C1e92e17169A14793126ABe49";

  const MagicatHandler = await ethers.getContractFactory("magicatsHandler");

  // const options = { gasPrice: 2000000000000, gasLimit: 9000000 };
  const magicatHandler = await MagicatHandler.deploy(
    strategyAddress,
    vaultAddress
  );

  await magicatHandler.deployed();
  console.log("MagicatHandler deployed to:", magicatHandler.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
