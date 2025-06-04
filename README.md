# VBITE dApps

Smart contracts and utility tools for the **VivaBite** platform — a decentralized service for multilingual restaurant menus and tokenized access

This repository is the main development monorepo for all EVM-based components of VivaBite, including:

- 🪙 `VBITE` ERC20 token ("Кусь" — a playful nickname meaning "bite" in Russian)
- 💰 Crowdsale contract with multi-token support
- 🏆 Lifetime access NFT (Silver, Gold, Platinum)
- 🧩 Scripts for deployment, simulation, and local testnets

---

## 📁 Structure

```text
contracts/       # Core Solidity contracts
flat/            # Flattened contracts for Ploygonscan checks
local/           # Local development & config files
mocks/           # Internal test/mock contracts
scripts/         # Foundry/Node deploy & automation scripts
```

---

## 📦 Tooling

This project uses:

- [Foundry](https://book.getfoundry.sh/) for Solidity development
- [Solhint](https://protofire.github.io/solhint/) + [Prettier](https://prettier.io/) for linting/formatting
- `remappings.txt` and `soldeer` for dependency resolution

---

## 📜 Contracts

All core contracts are located in `contracts/` and are published via submodule in [`vbite-dapps`](https://github.com/VivaBite/vbite-dapps).

| Contract                | Purpose                                                                      |
|-------------------------|------------------------------------------------------------------------------|
| `VBITE.sol`             | ERC20 token contract                                                         |
| `VBITECrowdsale.sol`    | Crowdsale with multiple payment tokens, Chainlink price feeds, and NFT logic |
| `VBITELifetimeNFT.sol`  | Lifetime non-transferable NFT contract (Silver, Gold, Platinum tiers)        |
| `VBITEAccessTypes.sol`  | Enum declarations for NFT types and internal access control                  |
| `VBITEVestingVault.sol` | Token vault with linear vesting logic for deferred team and project rewards  |

---

## 🚀 Deployment

Deployment scripts are located in `scripts/`. You can deploy to:

- Local testnet (Anvil)
- Polygon mainnet/testnet

---

## 📍 Deployed Addresses

Below are the on-chain addresses of the deployed contracts. These will be updated as deployment progresses:

| Contract            | Network         | Address                                                                                                                  |
|---------------------|-----------------|--------------------------------------------------------------------------------------------------------------------------|
| `VBITE`             | Polygon Mainnet | [0x6f196235b9d68B04DA51e747AbDF00e6f944b332](https://polygonscan.com/address/0x6f196235b9d68B04DA51e747AbDF00e6f944b332) |
| `VBITECrowdsale`    | Polygon Mainnet | [0x49da49d6981fb9eC6ee7368D93CcACed8d220458](https://polygonscan.com/address/0x49da49d6981fb9eC6ee7368D93CcACed8d220458) |
| `VBITELifetimeNFT`  | Polygon Mainnet | [0x1895fFc4b00DBe93fd6FC6B59bc08C6825Dadf60](https://polygonscan.com/address/0x1895fFc4b00DBe93fd6FC6B59bc08C6825Dadf60) |
| `VBITEVestingVault` | Polygon Mainnet | [0x1524CD755FB3B11a99B85B9340243C9909bB8A8E](https://polygonscan.com/address/0x1524CD755FB3B11a99B85B9340243C9909bB8A8E) |

> These addresses will be published after deployment and verification. Please refer to official sources for up-to-date data

---

## 📖 Usage in Other Projects

If you only need the core contracts, use [`vbite-dapps`](https://github.com/VivaBite/vbite-dapps) as a submodule or source package:

```bash
git submodule add https://github.com/VivaBite/vbite-dapps.git dapps
```

---

## 📄 License

MIT © VivaBite
