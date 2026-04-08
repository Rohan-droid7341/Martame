# Level 2: The Plasma Vault

## 📜 Mission Brief
Welcome to the Plasma Vault, the central staking core of the ship's energy distribution network. Crew members deposit raw Plasma (Ethereum) into the vault and withdraw it when needed.

However, telemetry indicates that malicious engineers could theoretically trick the vault into dispensing more Plasma than they deposited, draining the entire ship!

## 🎯 Objectives
1. Read the `PlasmaVault` code carefully.
2. Identify a critical vulnerability that allows a hacker to drain funds recursively.
3. Secure the `withdraw()` function natively.
4. **DO NOT** use OpenZeppelin or external libraries. Use raw Solidity logic!

*Hint*: Ensure state updates happen in the correct sequence...
