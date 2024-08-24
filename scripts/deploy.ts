import { ethers } from 'hardhat';

async function main() {

    const CrowdFunding = await ethers.deployContract('CrowdFunding');

    await CrowdFunding.waitForDeployment();

    console.log('CrowdFunding Contract Deployed at ' + CrowdFunding.target);
}

// this pattern is recommended to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});