const getVault = async () => {
  const vaultAddress = "0x5b41b141B2eC1C20f4d8186654a60D07b7711E14";
  const Vault = await ethers.getContractFactory("ReaperVaultv1_3");
  const vault = Vault.attach(vaultAddress);
  return vault;
};

module.exports = { getVault };
