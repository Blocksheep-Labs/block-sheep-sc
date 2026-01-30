# 🐑 Blocksheep smart contracts

## 📃 Default Contracts

📁 Located at: `./src/*`

🐑 `BlockSheep.sol` - Main contract that implements all registration and withdrawals logic, should run at testnet by default.

🐑 `BlockSheepPayments.sol` - Contract that is responsible for controlling mainnet USDC payments (required in register into race process), emits events that confirms user send USDC (registered at race) or withdrawed USDC, this events MUST BE handled by the backend.

💵 `MockUSDC` - Not required at deployed (final) version, used in testing purposes only (basic ERC20 USDC implementation)

## 🎮 Game Contracts

📁 Located at: `./src/*`

`IGameInterface.sol` - Interface that all game-contracts must implement to gracefully extend main contract logic without any required steps of updating the `BlockSheep.sol` logic.

🐂 `GameBullrun.sol` - The "BULLRUN" game logic.

🐰 `GameRabbitHole.sol` - The "RABBITHOLE" game logic.

🐳 `GameWhaleteeth.sol` - The "WHALETEETH" game logic.

🐶 `GameUnderdog.sol` - The "UNDERDOG" game logic.

## 🔑 Environment Variables (pre-deploy step)

To run scripts, you will need to add the following environment variables to your .env file

🔑 `PRIVATE_KEY` - the deployer smart wallet private key

## 🚀 How to deploy / run scripts

📁 All the required scripts are located at `./script/*`

⚙️ `DeployAll.s.sol` - Used to "fresh"-deploy all the required contracts.
```bash
  forge script ./script/DeployAll.s.sol \
  --rpc-url [YOUR_RPC_URL] \
  --broadcast
```

`DeployBlockSheep.s.sol` - Used to deploy the main contract.
```bash
  forge script ./script/DeployBlockSheep.s.sol \
  --rpc-url [YOUR_RPC_URL] \
  --broadcast
```

⚙️ `DeployGames.s.sol` - Used to deploy all games separately from the main contract.
```bash
  forge script ./script/DeployGames.s.sol \
  --rpc-url [YOUR_RPC_URL] \
  --broadcast
```

⚙️ `AddAdmin.s.sol` - Used to add admin access to user by address.
```bash
  forge script ./script/AddAdmin.s.sol \
  --rpc-url [YOUR_RPC_URL] \
  --broadcast \
  --sig "run(address,address)" [DEPLOYED_BLOCKSHEEP] [NEW_ADMIN_ADDRESS]
```

⚙️ `AddGamesToBlockSheep.s.sol` - Used to deploy all games from the `Game Contracts` section and add them into main BlockSheep contract.
```bash
  forge script ./script/AddGamesToBlockSheep.s.sol \
  --rpc-url [YOUR_RPC_URL] \
  --broadcast \
  --sig "run(address,address,address,address,address)" [DEPLOYED_BLOCKSHEEP] [BULLRUN_ADDRESS] [RABBITHOLE_ADDRESS] [UNDERDOG_ADDRESS] [WHALETEETH_ADDRESS]
```

⚙️ `DeployMockUSDC.s.sol` - Deploys the `MockUSDC` contract, used ONLY in testing purposes.
```bash
  forge script ./script/DeployMockUSDC.s.sol \
  --rpc-url [YOUR_RPC_URL] \
  --broadcast
```





