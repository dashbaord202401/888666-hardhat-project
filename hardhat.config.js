// require('@nomiclabs/hardhat-etherscan');
require('@nomicfoundation/hardhat-toolbox');
require('hardhat-gas-reporter');
const myCon = require('./mysetting').config;
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  networks: {
    hardhat: {},
    main: {
      url: myCon.url.main,
      accounts: myCon.accounts.main,
    },
    goerli: {
      url: myCon.url.goerli,
      accounts: myCon.accounts.test,
    },
    sepolia: {
      url: myCon.url.sepolia,
      accounts: myCon.accounts.test,
    },
    ganache: {
      url: `http://127.0.0.1:9545`,
      accounts: [
        '0x' +
          'f8fe568921865fdc6c5fda7b1414f3c646902d5ed24ae3f74294083cfbf197bc',
      ],
    },
  },
  solidity: {
    version: '0.8.18',
    settings: {
      optimizer: {
        enabled: true,
        runs: 300,
      },
    },
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    gasPrice: 21,
    coinmarketcap: process.env.COIN_MARKET_API_KEY,
    token: 'ETH',
  },
};
