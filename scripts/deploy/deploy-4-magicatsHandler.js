async function main() {
  const vaultAddress = "TODO";
  const strategyAddress = "TODO";

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
