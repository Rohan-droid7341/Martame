const express = require('express');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());

// Set up the internal workspace path
const WORKSPACE_DIR = '/app/evaluate';

// Level 2 Code Payload
let LEVEL2_PAYLOAD = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract Level2 {
    mapping(address => uint256) public balances;
    function deposit() external payable { balances[msg.sender] += msg.value; }
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient Balance");
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer Failed");
    }
}`;

try {
    LEVEL2_PAYLOAD = fs.readFileSync(path.join(__dirname, 'Level2.sol'), 'utf8');
} catch (e) {
    // fallback to default above
}

// On boot, fetch the secret tests if env var is provided
const SECRET_TEST_URL = process.env.LEVEL_1_SECRET_URL;
if (SECRET_TEST_URL) {
    console.log("Downloading secret tests...");
    execSync(`mkdir -p ${WORKSPACE_DIR}/test-secrets && curl -sL "${SECRET_TEST_URL}" > ${WORKSPACE_DIR}/test-secrets/Level1Secret.t.sol`);
} else {
    console.warn("WARNING: LEVEL_1_SECRET_URL not set! Tests might fail if not mounted.");
}

app.post('/submit', async (req, res) => {
    const { username, code, repoOwner, repoName } = req.body;
    
    if (!username || !code) {
        return res.status(400).json({ status: "error", message: 'Missing username or code' });
    }

    // Write the player's code to the internal foundry source folder
    const playerCodePath = path.join(WORKSPACE_DIR, 'src', 'Level1.sol');
    fs.writeFileSync(playerCodePath, code);

    console.log(`Evaluating submission from Pilot: ${username} ...`);

    try {
        // Run forge test via shell sync
        const output = execSync('forge test --match-path "test-secrets/*.t.sol" -vv', {
            cwd: WORKSPACE_DIR,
            encoding: 'utf-8',
            stdio: 'pipe'
        });
        
        console.log(`[PASS] ${username} successfully cleared Level 1!`);

        // Update Github if token and repo is provided (Leaderboard & Drop file push)
        const GITHUB_TOKEN = process.env.MASTER_PAT;
        if (GITHUB_TOKEN && repoOwner && repoName) {
             console.log("Updating Main Repository...");
             try {
                 // Push the success file to GitHub
                 const dropPayload = Buffer.from(LEVEL2_PAYLOAD).toString('base64');
                 
                 // Get the file if it exists, otherwise create
                 let sha = undefined;
                 try {
                     const existingResp = await fetch(`https://api.github.com/repos/${repoOwner}/${repoName}/contents/success/${username}-L1.sol`, {
                         headers: { 'Authorization': `token ${GITHUB_TOKEN}`, 'Accept': 'application/vnd.github.v3+json' }
                     });
                     if (existingResp.ok) {
                         const existBody = await existingResp.json();
                         sha = existBody.sha;
                     }
                 } catch (e) {}
                 
                 const resPut = await fetch(`https://api.github.com/repos/${repoOwner}/${repoName}/contents/success/${username}-L1.sol`, {
                     method: 'PUT',
                     headers: { 
                         'Authorization': `token ${GITHUB_TOKEN}`, 
                         'Accept': 'application/vnd.github.v3+json',
                         'Content-Type': 'application/json'
                     },
                     body: JSON.stringify({
                         message: `🏆 ${username} beat Level 1!`,
                         content: dropPayload,
                         sha: sha
                     })
                 });
             } catch (gitErr) {
                 console.error("Github Publish failed", gitErr);
             }
        }
        
        // Return JSON immediately
        return res.status(200).json({ 
            status: "success", 
            message: "ACCESS GRANTED! You have passed the hidden evaluation.",
            level2_base64: Buffer.from(LEVEL2_PAYLOAD).toString('base64')
        });

    } catch (error) {
        console.log(`[FAIL] ${username} failed the secret tests.`);
        console.log(error.stdout || error.message);
        return res.status(400).json({ 
            status: "failure", 
            message: "ACCESS DENIED: Your submission failed the secret tests!" 
        });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Central Judge Server blasting off on port ${PORT}...`);
});
