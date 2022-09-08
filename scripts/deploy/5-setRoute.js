async function main() {
  const strategyAddress = "0xE970Dd7F7dcDbB5C5167C85DDBD8d9E1b44cF1fd";

  const Strategy = await ethers.getContractFactory("ReaperAutoCompoundXBoov2");
  const strategy = Strategy.attach(strategyAddress);

  const ORBS_ID = 5;
  const ORBS = "0x3E01B7E242D5AF8064cB9A8F9468aC0f8683617c";
  const USDC = "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75";
  const WFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";

  const tx1 = await strategy.setRoute(ORBS_ID, [ORBS, USDC, WFTM]);
  await tx1.wait();
  console.log("Route added to strategy");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
