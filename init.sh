#!/bin/bash

# =============================================================================
# init.sh — Project scaffolding script for my-app
# Run this ONCE when starting a brand new project from scratch.
# Usage: bash init.sh
# Requirements: Node.js, npm, git must be installed
# =============================================================================

set -e  # stop immediately if any command fails

# -----------------------------------------------------------------------------
# CONFIG — change these two values before running
# -----------------------------------------------------------------------------
GITHUB_USERNAME="DevOps-engineer-dev"     # e.g. "johnsmith"
REPO_NAME="new-project"                         # must match your GitHub repo name

echo "================================================"
echo " Scaffolding project: $REPO_NAME"
echo "================================================"

# -----------------------------------------------------------------------------
# Step 1: Create directory structure
# -----------------------------------------------------------------------------
echo ""
echo "[1/7] Creating folder structure..."
mkdir -p src/routes src/controllers
mkdir -p k8s
mkdir -p .github/workflows

echo "      Folders created."

# -----------------------------------------------------------------------------
# Step 2: Write all source files
# -----------------------------------------------------------------------------
echo ""
echo "[2/7] Writing source files..."

# --- package.json ---
cat > package.json << 'EOF'
{
  "name": "my-app",
  "version": "1.0.0",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev":   "nodemon src/server.js",
    "test":  "echo \"No tests yet\" && exit 0"
  },
  "dependencies": {
    "express": "^4.18.2",
    "dotenv":  "^16.0.3"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

# --- src/server.js ---
cat > src/server.js << 'EOF'
require('dotenv').config();
const app  = require('./app');
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
EOF

# --- src/app.js ---
cat > src/app.js << 'EOF'
const express    = require('express');
const todoRoutes = require('./routes/todos');

const app = express();
app.use(express.json());
app.use('/api/todos', todoRoutes);

module.exports = app;
EOF

# --- src/routes/todos.js ---
cat > src/routes/todos.js << 'EOF'
const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/todoController');

router.get('/',      ctrl.getAll);
router.post('/',     ctrl.create);
router.delete('/:id', ctrl.remove);

module.exports = router;
EOF

# --- src/controllers/todoController.js ---
cat > src/controllers/todoController.js << 'EOF'
let todos  = [];
let nextId = 1;

exports.getAll = (req, res) => res.json(todos);

exports.create = (req, res) => {
  const todo = { id: nextId++, text: req.body.text, done: false };
  todos.push(todo);
  res.status(201).json(todo);
};

exports.remove = (req, res) => {
  todos = todos.filter(t => t.id !== +req.params.id);
  res.status(204).send();
};
EOF

# --- .env ---
cat > .env << 'EOF'
PORT=3000
EOF

# --- .gitignore ---
cat > .gitignore << 'EOF'
node_modules/
setup-secrets.sh/
.env
EOF

# --- .dockerignore ---
cat > .dockerignore << 'EOF'
node_modules
.env
.git
EOF

echo "      Source files written."

# -----------------------------------------------------------------------------
# Step 3: Write Docker files
# -----------------------------------------------------------------------------
echo ""
echo "[3/7] Writing Docker files..."

# --- Dockerfile ---
cat > Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["node", "src/server.js"]
EOF

# --- docker-compose.yaml ---
cat > docker-compose.yaml << 'EOF'
version: '3.9'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
    volumes:
      - .:/app
      - /app/node_modules
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
EOF

echo "      Docker files written."

# -----------------------------------------------------------------------------
# Step 4: Write Kubernetes manifests
# -----------------------------------------------------------------------------
echo ""
echo "[4/7] Writing Kubernetes manifests..."

# --- k8s/deployment.yaml ---
cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: my-app:latest
          imagePullPolicy: Never
          ports:
            - containerPort: 3000
          env:
            - name: PORT
              value: "3000"
EOF

# --- k8s/service.yaml ---
cat > k8s/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 3000
EOF

echo "      Kubernetes manifests written."

# -----------------------------------------------------------------------------
# Step 5: Write GitHub Actions CI pipeline
# -----------------------------------------------------------------------------
echo ""
echo "[5/7] Writing GitHub Actions CI pipeline..."

cat > .github/workflows/ci.yaml << 'EOF'
name: CI Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test --if-present

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest
EOF

echo "      CI pipeline written."

# -----------------------------------------------------------------------------
# Step 6: Install Node dependencies
# -----------------------------------------------------------------------------
echo ""
echo "[6/7] Installing npm dependencies..."
npm install
echo "      npm install complete."

# -----------------------------------------------------------------------------
# Step 7: Initialise Git, commit everything, push to GitHub
# -----------------------------------------------------------------------------
echo ""
echo "[7/7] Initialising Git and pushing to GitHub..."

git init                                      # initialise a local git repo
git add .                                     # stage all files
git commit -m "Initial project scaffold"      # first commit

# Set the branch name to 'main' (GitHub default)
git branch -M main

# Link this local folder to your GitHub repository
git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

# Push to GitHub (-u sets upstream so future pushes just need 'git push')
git push -u origin main

echo ""
echo "================================================"
echo " Done! Project scaffolded and pushed to:"
echo " https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo ""
echo " Next steps:"
echo "   1. Open VS Code: code ."
echo "   2. Start dev server: npm run dev"
echo "   3. Add DOCKERHUB_USERNAME and DOCKERHUB_TOKEN"
echo "      secrets in your GitHub repo settings."
echo "================================================"
