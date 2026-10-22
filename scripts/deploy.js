const hre = require("hardhat");
async function main() {
  const ArbitrationFactory = await hre.ethers.getContractFactory("NexusArbitrationHub");
  const arbitration = await ArbitrationFactory.deploy();
  await arbitration.deployed();
  console.log("-> Nexus Arbitration Protocol live at:", arbitration.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
