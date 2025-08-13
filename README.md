# EcoFlow

A blockchain-powered platform for peer-to-peer renewable energy trading and transparent carbon credit management, enabling households and businesses to trade surplus renewable energy, earn tokenized carbon credits, and support a decentralized energy economy.

---

## Overview

EcoFlow leverages the Stacks blockchain and Clarity smart contracts to create a decentralized energy market and carbon credit system. The platform allows users to trade renewable energy directly, earn verifiable carbon credits, and participate in a transparent ecosystem that incentivizes sustainability. It consists of four main smart contracts:

1. **Energy Trading Contract** – Facilitates peer-to-peer energy trading with tokenized payments.
2. **Carbon Credit Token Contract** – Issues and manages tokenized carbon credits for renewable energy production.
3. **Verification Oracle Contract** – Integrates off-chain energy production and emissions data for transparency.
4. **Rewards Distribution Contract** – Automates distribution of incentives to users for renewable energy contributions.

---

## Features

- **Peer-to-Peer Energy Trading**: Households with solar panels or other renewable sources can sell surplus energy directly to neighbors or businesses, with payments settled in tokens via smart contracts.
- **Tokenized Carbon Credits**: Users earn carbon credits for verified renewable energy production, which can be traded or sold in a transparent marketplace.
- **Data Transparency**: Off-chain energy production and emissions data are verified via oracles, ensuring trust in carbon credit issuance.
- **Incentive System**: Users are rewarded with tokens for contributing to renewable energy adoption, encouraging sustainable practices.

---

## Smart Contracts

### Energy Trading Contract
- Facilitates energy trading between producers and consumers.
- Uses smart contracts to automate token payments based on energy delivered.
- Tracks trade history transparently on-chain.

### Carbon Credit Token Contract
- Mints and manages tokenized carbon credits based on verified renewable energy production.
- Enables transfer, trading, or redemption of credits.
- Ensures credits are issued only for verified emissions reductions.

### Verification Oracle Contract
- Integrates with off-chain IoT devices or APIs to verify energy production and emissions data.
- Provides secure, tamper-proof data feeds for smart contracts.
- Supports validation of renewable energy contributions.

### Rewards Distribution Contract
- Distributes token rewards to users based on their renewable energy contributions.
- Automates payouts using predefined rules (e.g., energy produced or credits earned).
- Tracks reward history for transparency.

---

## Installation

1. Install [Clarinet CLI](https://docs.hiro.so/clarinet/getting-started).
2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/ecoflow.git
   ```
3. Run tests:
   ```bash
   npm test
   ```
4. Deploy contracts:
   ```bash
   clarinet deploy
   ```

## Usage

Each smart contract operates independently but integrates with others to create a cohesive energy trading and carbon credit ecosystem. Refer to individual contract documentation for function calls, parameters, and usage examples.

## License

MIT License
