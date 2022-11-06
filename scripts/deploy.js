const hre = require("hardhat");

async function main() {

  const GoatVoter = await hre.ethers.getContractFactory("GoatVoter");
  const goatVoter = await GoatVoter.deploy();

  await goatVoter.deployed();
  // await goatVoter.deployTransaction.wait();

  console.log(
    `GoatVoter is deployed to ${goatVoter.address} on ${hre.network.name} with transaction ${goatVoter.deployTransaction.hash}! Go vote! `
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
