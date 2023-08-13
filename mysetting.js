require('dotenv').config();

const config = {
  accounts: {
    main: [process.env.MAIN_PRIVATE_KEY],
    test: [process.env.TEST_PRIVATE_KEY],
  },
  url: {
    main: `https://mainnet.infura.io/v3/${process.env.INFRA_PROVIDER_TOKEN}`,
    sepolia: `https://sepolia.infura.io/v3/${process.env.INFRA_PROVIDER_TOKEN}`,
    goerli: `https://goerli.infura.io/v3/${process.env.INFRA_PROVIDER_TOKEN}`,
  },
};

exports.config = config;
