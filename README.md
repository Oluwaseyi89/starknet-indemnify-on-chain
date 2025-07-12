# StarkInsure On-Chain

The **StarkInsure On-Chain** repository contains the core smart contracts powering StarkInsure's DeFi insurance platform, written in **Cairo 2.9.2** for StarkNet. This implements the blockchain logic for policy underwriting, claims processing, and risk pool management.

---

## 🔗 Contract Documentation  
[StarkNet Insurance Standards](https://docs.starknet.io/insurance-standards/) | [Cairo Book](https://book.cairo-lang.org/)

---

## ✨ On-Chain Features  
- **Insurance Core Contracts**:  
  - 📜 ERC-721 compatible policy tokens  
  - 🏦 Multi-signature claim approval  
  - 📊 Dynamic premium calculation  
- **Risk Pool System**:  
  - 💧 Liquidity provider staking  
  - 🛡️ Reinsurance layer contracts  
  - 📈 APY calculation logic  
- **Oracle Integration**:  
  - 🔗 Pragma Oracle triggers  
  - ⚖️ Parametric claim validation  
- **Upgradeability**:  
  - 🛠️ Proxy patterns for protocol updates  
  - 🔄 Emergency pause mechanisms  

---

## 🛠️ Tech Stack  
| Component           | Technology                                                                 |
|---------------------|---------------------------------------------------------------------------|
| Language           | [Cairo 2.3.0](https://www.cairo-lang.org/)                              |
| Development Kit    | [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/)       |
| Testing            | [Starknet.js](https://www.starknetjs.com/) + [Snforge](https://github.com/foundry-rs/starknet-foundry) |
| Deployment         | [Starkli](https://github.com/xJonathanLEI/starkli)                       |

---

## 🚀 Quick Start  

### Prerequisites  
- Rust 1.75+  
- Starknet Foundry (`snforge`, `starkli`)  
- Python 3.10+ (for testing)  
- ArgentX/Braavos wallet  

### Installation  
1. **Clone the repo**:  
   ```bash
   git clone https://github.com/CRYPTOInsured-Foundation/starkinsure-on-chain.git
   cd starkinsure-on-chain
   ```
2. Setup environment:
   ```bash
   cp .env.example .env
   ```
3. Install dependencies:
   ```bash
   scarb build  # Cairo package manager
   ```
4. Run tests:
   ```bash
   snforge test
   ```
## 🤝 Contributing

1. Fork the repository
2. Create your feature branch:
```bash
git checkout -b feat/your-feature
```
3. Commit changes following Conventional Commits
4. Push to the branch
5. Open a Pull Request
