const hre = require("hardhat");

async function main() {
  const vaultAddress = "0xFC550BAD3c14160CBA7bc05ee263b3F060149AFF";
  const Boo = await ethers.getContractFactory("SpookyToken");
  const booAddress = "0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE";
  const boo = await Boo.attach(booAddress);
  await boo.approve(vaultAddress, ethers.utils.parseEther("100"));
  console.log("Boo approved");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
