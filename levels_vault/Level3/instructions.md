# Level 3: Warp Governance

## 📜 Mission Brief
The ship's crew votes on all major navigational decisions using the `WarpGovernance` smart contract. A new proposal is created to modify the Warp Speed, and crew members cast their votes. 

However, engineers have noticed that once a crew member votes on a proposal, their voting module completely short circuits, permanently preventing them from ever participating in any future proposals!

## 🎯 Objectives
1. Read the `WarpGovernance` code carefully.
2. Identify why a user is permanently locked out of voting after their first vote.
3. Modify the contract's data structures and logic to allow a user to vote exactly **once per proposal**, but remain eligible for entirely **new proposals**.
4. **DO NOT** use OpenZeppelin or external libraries. 
