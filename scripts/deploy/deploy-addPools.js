const hre = require("hardhat");

async function main() {
  const Strategy = await ethers.getContractFactory("ReaperAutoCompoundXBoo");
  const strategyAddress = "0x60E646e4a56bB7aeAF96A1d7CF3869Cb32829C7a";
  const strategy = Strategy.attach(strategyAddress);

  const WFTM_ID = 2;
  const FOO_ID = 3;
  const WFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";
  const FOO = "0xFbc3c04845162F067A0B6F8934383E63899c3524";

  const tx1 = await strategy.addUsedPool(WFTM_ID, [WFTM, WFTM]);
  const tx2 = await strategy.addUsedPool(FOO_ID, [FOO, WFTM]);
  await tx1.wait();
  await tx2.wait();
  console.log("Pools added to strategy");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
