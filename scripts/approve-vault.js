const hre = require("hardhat");

async function main() {
  const vaultAddress = "0x0F5A4F4B82e6A717869Df5D08DEc600CE7B311b6";
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
