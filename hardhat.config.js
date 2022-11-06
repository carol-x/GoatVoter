require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    // for mainnet
    'optimism': {
      url: "https://mainnet.optimism.io",
      accounts: [process.env.PRIVKEY]
    },
    // for testnet
    'optimism-goerli': {
      url: "https://goerli.optimism.io",
      chainId: 420,
      blockConfirmation: 6,
      accounts: [process.env.PRIVKEY]
    },
  }
};
