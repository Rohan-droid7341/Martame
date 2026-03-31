const express = require('express');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

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
    execSync(`curl -sL "${SECRET_TEST_URL}" > ${WORKSPACE_DIR}/test/Level1Secret.t.sol`);
} else {
    console.warn("WARNING: LEVEL_1_SECRET_URL not set! Tests might fail if not mounted.");
}

app.post('/submit', async (req, res) => {
    const { username, code, repoOwner, repoName } = req.body;
    
    if (!username || !code) {
        return res.status(400).send("STATUS=FAILURE\nMESSAGE=Missing username or code");
    }

    // Write the player's code to the internal foundry source folder
    const playerCodePath = path.join(WORKSPACE_DIR, 'src', 'Level1.sol');
    fs.writeFileSync(playerCodePath, code);

    console.log(`Evaluating submission from Pilot: ${username} ...`);

    try {
        // Run forge test explicitly pointing to the downloaded secret test
        const output = execSync('forge test --match-path "test/Level1Secret.t.sol" -vv', {
            cwd: WORKSPACE_DIR,
            encoding: 'utf-8',
            stdio: 'pipe'
        });
        
        if (output.includes("No tests found to run") || output.includes("Ran 0 test suites")) {
             throw new Error("Central Judge Misconfiguration: Secret tests didn't run. Please verify your Render environment variables.");
        }
        
        console.log(`[PASS] ${username} successfully cleared Level 1!`);

        // Update Github if token and repo is provided (Leaderboard & Drop file push)
        const GITHUB_TOKEN = process.env.MASTER_PAT;
        if (GITHUB_TOKEN && repoOwner && repoName) {
             console.log("Updating Main Repository...");
             try {
                 // Push the success file to GitHub
                 const dropPayload = Buffer.from(LEVEL2_PAYLOAD).toString('base64');
                 
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
                 
                 await fetch(`https://api.github.com/repos/${repoOwner}/${repoName}/contents/success/${username}-L1.sol`, {
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

                 // Update Leaderboard in README.md
                 try {
                     const readmeResp = await fetch(`https://api.github.com/repos/${repoOwner}/${repoName}/contents/README.md`, {
                         headers: { 'Authorization': `token ${GITHUB_TOKEN}` }
                     });
                     
                     if (readmeResp.ok) {
                         const readmeData = await readmeResp.json();
                         let readmeContent = Buffer.from(readmeData.content, 'base64').toString('utf8');
                         
                         const newEntry = `- 🚀 **${username}** has successfully infiltrated Level 1!`;
                         // Insert right after the START marker
                         if (readmeContent.includes('<!-- LEADERBOARD_START -->') && !readmeContent.includes(newEntry)) {
                             readmeContent = readmeContent.replace(
                                 '<!-- LEADERBOARD_START -->', 
                                 `<!-- LEADERBOARD_START -->\n${newEntry}`
                             );
                             
                             await fetch(`https://api.github.com/repos/${repoOwner}/${repoName}/contents/README.md`, {
                                 method: 'PUT',
                                 headers: { 
                                     'Authorization': `token ${GITHUB_TOKEN}`, 
                                     'Content-Type': 'application/json'
                                 },
                                 body: JSON.stringify({
                                     message: `🏆 Update leaderboard for ${username}`,
                                     content: Buffer.from(readmeContent).toString('base64'),
                                     sha: readmeData.sha
                                 })
                             });
                             console.log("Leaderboard updated!");
                         }
                     }
                 } catch (lErr) {
                     console.error("Leaderboard update failed", lErr);
                 }
             } catch (gitErr) {
                 console.error("Github Publish failed", gitErr);
             }
        }
        
        // Return simple text directly
        return res.status(200).send(`STATUS=SUCCESS\nMESSAGE=ACCESS GRANTED! You have passed the hidden evaluation.\nLEVEL2=${Buffer.from(LEVEL2_PAYLOAD).toString('base64')}`);

    } catch (error) {
        console.log(`[FAIL] ${username} failed the secret tests.`);
        console.log(error.stdout || error.message);
        return res.status(400).send("STATUS=FAILURE\nMESSAGE=ACCESS DENIED: Your submission failed the secret tests!");
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Central Judge Server blasting off on port ${PORT}...`);
});
