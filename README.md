# Central Judge Docker

## How to use

1. Install Docker Desktop and ensure it is running.
2. Build the Docker image:
   ```bash
   docker build -t central-judge .
   ```
3. Run the Docker container, passing in your GitHub PAT (so it can push Level 2 to the player's repo) and the URL to your secret tests:
   ```bash
   docker run -p 3000:3000 \
     -e MASTER_PAT="ghp_your_github_token" \
     -e LEVEL_1_SECRET_URL="https://raw.githubusercontent.com/.../Level1Secret.t.sol" \
     central-judge
   ```
4. Have your players run `./submit.sh` when this container is running. It connects directly to `localhost:3000` (update `JUDGE_URL` in `submit.sh` if hosting this online).
