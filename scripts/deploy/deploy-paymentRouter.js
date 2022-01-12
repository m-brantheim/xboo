const hre = require("hardhat");

async function main() {
  const strategyAddress = "0x60E646e4a56bB7aeAF96A1d7CF3869Cb32829C7a";
  const PaymentRouter = await ethers.getContractFactory("PaymentRouter");
  const strategistFeeReceiver = "0x81876677843D00a7D792E1617459aC2E93202576";
  const paymentRouterAddress = "0x603e60d22af05ff77fdcf05c063f582c40e55aae";

  const paymentRouter = await PaymentRouter.attach(paymentRouterAddress);
  const options = { gasPrice: 1000000000000, gasLimit: 9000000 };
  await paymentRouter.addStrategy(
    strategyAddress,
    [strategistFeeReceiver],
    [10000],
    options
  );
  console.log("Strategy added to payment router");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
