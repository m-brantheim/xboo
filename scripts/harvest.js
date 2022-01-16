const hre = require("hardhat");

async function main() {
  const strategyAddress = "0x3d64A3cAC844cB19a4E34f20FCFCaDEf79aB7e24";
  const Strategy = await ethers.getContractFactory("ReaperAutoCompoundXBoo");
  const strategy = Strategy.attach(strategyAddress);
  const options = { gasPrice: 1000000000000, gasLimit: 9000000 };
  await strategy.harvest(options);
  console.log("harvested!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
