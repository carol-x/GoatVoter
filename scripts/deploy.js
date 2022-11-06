const hre = require("hardhat");

async function main() {

  const GoatVoter = await hre.ethers.getContractFactory("GoatVoter");
  const goatVoter = await GoatVoter.deploy();

  await goatVoter.deployed();

  console.log(
    `GoatVoter is deployed to ${lock.address}! Go vote! `
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
