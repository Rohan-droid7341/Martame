FROM ubuntu:22.04

# Install required dependencies
RUN apt-get update && apt-get install -y curl git make build-essential

# Install Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Setup App
WORKDIR /app

# Setup a clean workspace for foundry code injection
RUN mkdir evaluate
WORKDIR /app/evaluate
RUN forge init --no-git
# We'll map the actual code at runtime

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY server.js .

EXPOSE 3000
CMD ["node", "server.js"]
