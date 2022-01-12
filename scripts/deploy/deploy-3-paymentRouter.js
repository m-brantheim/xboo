async function main() {
  const strategyAddress = "0x0aD9E4D7ef01208fC1e67eD5C3136bEc11d00aaD";

  const PaymentRouter = await ethers.getContractFactory("PaymentRouter");
  const strategistFeeReceiver = "0x81876677843D00a7D792E1617459aC2E93202576";
  const paymentRouterAddress = "0x603e60d22af05ff77fdcf05c063f582c40e55aae";

  const paymentRouter = await PaymentRouter.attach(paymentRouterAddress);
  const options = { gasPrice: 2000000000000, gasLimit: 9000000 };
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
