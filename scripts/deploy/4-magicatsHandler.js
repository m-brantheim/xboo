async function main() {
  const vaultAddress = "0xA8a4A91cC7432D3700384728C2C72ead77Eb8d9e";
  const strategyAddress = "0xE970Dd7F7dcDbB5C5167C85DDBD8d9E1b44cF1fd";

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
