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
| `VBITEAirdrop.sol`      | Airdrop contract                                                             |
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
| `VBITE`             | Polygon Mainnet | [0x6f196235b9d68b04da51e747abdf00e6f944b332](https://polygonscan.com/address/0x6f196235b9d68b04da51e747abdf00e6f944b332) |
| `VBITECrowdsale`    | Polygon Mainnet | [0x49da49d6981fb9ec6ee7368d93ccaced8d220458](https://polygonscan.com/address/0x49da49d6981fb9ec6ee7368d93ccaced8d220458) |
| `VBITEAirdrop`      | Polygon Mainnet | [0xc507e163e3e65d448679193d1b8490e656e2374e](https://polygonscan.com/address/0xc507e163e3e65d448679193d1b8490e656e2374e) |
| `VBITELifetimeNFT`  | Polygon Mainnet | [0x1895ffc4b00dbe93fd6fc6b59bc08c6825dadf60](https://polygonscan.com/address/0x1895ffc4b00dbe93fd6fc6b59bc08c6825dadf60) |
| `VBITEVestingVault` | Polygon Mainnet | [0x1524cd755fb3b11a99b85b9340243c9909bb8a8e](https://polygonscan.com/address/0x1524cd755fb3b11a99b85b9340243c9909bb8a8e) |

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
