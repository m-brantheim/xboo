async function main() {
  const strategyAddress = "0xe3D115671cD4100dbD018aeE78C19CFa18055476";

  const Strategy = await ethers.getContractFactory("ReaperAutoCompoundXBoo");
  const strategy = Strategy.attach(strategyAddress);

  const YOSHI_ID = 18;
  const WFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";
  const YOSHI = "0x3dc57B391262e3aAe37a08D91241f9bA9d58b570";

  const tx1 = await strategy.addUsedPool(YOSHI_ID, [YOSHI, WFTM]);
  await tx1.wait();
  console.log("Pools added to strategy");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
