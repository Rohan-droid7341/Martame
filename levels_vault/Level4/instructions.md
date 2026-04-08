# Level 4: The Quantum Bridge

## 📜 Mission Brief
The Quantum Bridge transfers raw cargo (Ether) across long-range coordinates. It also features a highly secure `emergencyOverride` mechanism that allows the Bridge Commander to drain all bridge fluids if the ship is compromised.

However, security drones intercepted a phishing signal indicating that hackers are trying to trick the Bridge Commander into initiating the override remotely via a proxy module. They also noticed that sometimes, cargo gets completely lost in the fast lanes if a destination system rejects the transfer.

## 🎯 Objectives
1. Read the `QuantumBridge` code carefully.
2. Identify why a malicious smart contract could bypass the Commander's authorization.
3. Identify why standard cargo falls into the void and disappears forever when a transfer silently fails.
4. Secure both functions completely!
