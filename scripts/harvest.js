const hre = require("hardhat");

async function main() {
  const strategyAddress = "0x0aD9E4D7ef01208fC1e67eD5C3136bEc11d00aaD";
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
