# Nexus Arbitration Hub

A decentralized escrow and dispute resolution protocol deployed on the Base L2 network. Nexus provides a trustless environment for B2B and P2P transactions by locking buyer funds in a mathematically secure vault until goods or services are delivered, utilizing verified third-party arbiters for conflict resolution.

## System Mechanics
* **Cryptographic Escrow:** Funds are strictly locked within the contract state and bound to a specific `caseId`. Neither the buyer nor the seller can unilaterally withdraw the capital while the dispute remains active.
* **Independent Arbitration:** When initiating a transaction, the buyer designates a verified arbiter (a trusted wallet or decentralized autonomous organization). This arbiter holds the exclusive cryptographic right to route the locked funds based on off-chain evidence (anchored via `evidenceHash`).
* **Automated Fee Routing:** Upon case resolution, the smart contract automatically deducts a pre-configured platform fee (in basis points) before routing the remaining settlement directly to the winning party.

## Architecture
Developed using Solidity `0.8.37`. The protocol heavily enforces the Checks-Effects-Interactions pattern during the `resolveDisputeBuyer` and `resolveDisputeSeller` functions to eliminate any possibility of reentrancy attacks during settlement payouts.
