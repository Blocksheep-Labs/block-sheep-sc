import "@nomicfoundation/hardhat-foundry"
import "@nomicfoundation/hardhat-toolbox"
import * as dotenv from "dotenv"
import "hardhat-contract-sizer"
import "hardhat-deploy"
import "hardhat-deploy-ethers"
import { HardhatUserConfig } from "hardhat/config"

dotenv.config()

const ARBITRUM_SEPOLIA_ALCHEMY_URL =
    process.env.ARBITRUM_SEPOLIA_ALCHEMY_URL || ""

const DEPLOYER = process.env.PRIVATE_KEY || ""

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: "0.8.20",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 20_000, // use size-contracts to determine best value
                    },
                },
            },
        ],
    },
    defaultNetwork: "hardhat",
    networks: {
        "hardhat":{
        },
        "arbitrum-sepolia": {
            url: ARBITRUM_SEPOLIA_ALCHEMY_URL,
            accounts: [DEPLOYER],
        },
    },
    namedAccounts: {
        deployer: 0,
    },
    contractSizer: {
        alphaSort: false,
        disambiguatePaths: false,
        runOnCompile: true,
        strict: false,
    },
}

export default config
