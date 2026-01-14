#!/usr/bin/env bash
set -e

echo "================================"
echo "Starting postCreate script"
echo "================================"

# Define paths - YOUR repo is the workspace root
WORKSPACE_ROOT="/workspaces/LLM_FineTune_RAG_Production"
PROJECT_DIR="$WORKSPACE_ROOT/LLM-Engineers-Handbook"
REPO_URL="https://github.com/PacktPublishing/LLM-Engineers-Handbook.git"

echo "Your repo (workspace): $WORKSPACE_ROOT"
echo "Target project directory: $PROJECT_DIR"
echo "User: $(whoami)"
echo "Home: $HOME"

echo "================================"
echo "Verifying workspace exists"
echo "================================"

# Make sure we're in your repo first
if [ ! -d "$WORKSPACE_ROOT" ]; then
    echo "ERROR: Workspace directory $WORKSPACE_ROOT does not exist!"
    echo "Current location: $(pwd)"
    echo "Available directories:"
    ls -la /workspaces/
    exit 1
fi

cd "$WORKSPACE_ROOT"
echo "✓ In workspace: $(pwd)"
echo "Workspace contents:"
ls -la

echo "================================"
echo "Checking repository status"
echo "================================"

# Check if the LLM-Engineers-Handbook directory exists and has content
if [ -d "$PROJECT_DIR" ] && [ -f "$PROJECT_DIR/pyproject.toml" ]; then
    echo "✓ LLM-Engineers-Handbook repository already exists and appears valid"
    cd "$PROJECT_DIR"
    
    # Update the repository to get latest changes
    echo "Pulling latest changes..."
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || echo "Warning: Could not pull latest changes"
else
    echo "Repository not found or incomplete, cloning..."
    
    # Remove directory if it exists but is incomplete
    if [ -d "$PROJECT_DIR" ]; then
        echo "Removing incomplete repository directory..."
        rm -rf "$PROJECT_DIR"
    fi
    
    # Clone the repository into your workspace
    echo "Cloning repository from $REPO_URL into $WORKSPACE_ROOT..."
    git clone "$REPO_URL" "$PROJECT_DIR"
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to clone repository"
        exit 1
    fi
    
    echo "✓ Repository cloned successfully"
    cd "$PROJECT_DIR"
fi

# Verify we're in the right place
echo "Current directory: $(pwd)"
if [ ! -f "pyproject.toml" ]; then
    echo "ERROR: pyproject.toml not found after setup!"
    echo "Directory contents:"
    ls -la
    exit 1
fi

echo "✓ Found pyproject.toml"

echo "================================"
echo "Setting up pyenv"
echo "================================"

# Setup pyenv environment variables
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

# Initialize pyenv if it exists
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv init --path)"
    echo "✓ Pyenv version: $(pyenv --version)"
else
    echo "WARNING: pyenv not found, installing manually..."
    curl https://pyenv.run | bash
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv init --path)"
fi

# Check for .python-version file and install required Python
if [ -f ".python-version" ]; then
    REQUIRED_PYTHON=$(cat .python-version | tr -d '[:space:]')
    echo "Found .python-version: $REQUIRED_PYTHON"
    
    # Check if this Python version is already installed
    if pyenv versions 2>/dev/null | grep -q "$REQUIRED_PYTHON"; then
        echo "✓ Python $REQUIRED_PYTHON already installed"
    else
        echo "Installing Python $REQUIRED_PYTHON with pyenv..."
        pyenv install "$REQUIRED_PYTHON"
    fi
    
    # Set local Python version
    pyenv local "$REQUIRED_PYTHON"
    echo "✓ Set local Python version to: $(pyenv version)"
else
    echo "No .python-version file found"
    echo "Installing Python 3.11.8 as recommended..."
    
    if ! pyenv versions 2>/dev/null | grep -q "3.11.8"; then
        pyenv install 3.11.8
    fi
    
    pyenv local 3.11.8
fi

echo "✓ Current Python version: $(python --version)"
echo "✓ Python location: $(which python)"

echo "================================"
echo "Setting up Poetry"
echo "================================"

# Ensure Poetry is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Check if Poetry is installed
if ! command -v poetry >/dev/null 2>&1; then
    echo "Poetry not found, installing..."
    curl -sSL https://install.python-poetry.org | python3 -
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "✓ Poetry version: $(poetry --version)"
echo "✓ Poetry location: $(which poetry)"

# Configure Poetry as per project instructions
echo "Configuring Poetry..."
poetry env use 3.11
poetry config virtualenvs.in-project true
poetry config virtualenvs.create true
poetry config virtualenvs.prefer-active-python true

echo "Poetry configuration:"
poetry config --list

echo "================================"
echo "Installing project dependencies"
echo "================================"

# Install dependencies (excluding AWS packages as per instructions)
echo "Running: poetry install --without aws"
poetry install --without aws --no-interaction --no-ansi

echo "================================"
echo "Setting up pre-commit hooks"
echo "================================"

# Install pre-commit hooks
poetry run pre-commit install || echo "Warning: pre-commit install failed (non-critical)"

echo "================================"
echo "Setting up .env file"
echo "================================"

# Create .env file from example if it doesn't exist
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "✓ .env file created. Please fill in your credentials!"
    echo "  Edit the .env file at: $PROJECT_DIR/.env"
else
    if [ -f ".env" ]; then
        echo "✓ .env file already exists"
    else
        echo "⚠ Warning: No .env.example file found to create .env from"
    fi
fi

echo "================================"
echo "Poetry environment info"
echo "================================"

poetry env info

echo "================================"
echo "Configuring shell environment"
echo "================================"

# Create/update .bashrc with all necessary configurations
cat >> ~/.bashrc << 'EOF'

# ===== LLM Engineers Handbook Project Setup =====

# Poetry PATH
export PATH="$HOME/.local/bin:$PATH"

# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

# Initialize pyenv
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv init --path)"
fi

# Auto-cd to project directory on new terminal
if [ "$PWD" = "/workspaces/LLM_FineTune_RAG_Production" ]; then
    if [ -d "LLM-Engineers-Handbook" ]; then
        cd LLM-Engineers-Handbook 2>/dev/null || true
    fi
fi

# Project-specific aliases
alias poe='poetry run poe'
alias poetry-shell='poetry shell'
alias project='cd /workspaces/LLM_FineTune_RAG_Production/LLM-Engineers-Handbook'

# Show helpful info when entering project
if [ "$PWD" = "/workspaces/LLM_FineTune_RAG_Production/LLM-Engineers-Handbook" ]; then
    echo ""
    echo "📚 LLM Engineers Handbook Project"
    echo "   Python: $(python --version 2>&1 | cut -d' ' -f2)"
    echo "   Poetry: $(poetry --version 2>&1 | cut -d' ' -f3)"
    if [ -f ".env" ]; then
        echo "   ✓ .env file exists"
    else
        echo "   ⚠ .env file missing - create from .env.example"
    fi
    echo ""
fi

# ===== End LLM Project Environment Setup =====
EOF

# Also add to .bash_profile for login shells
cat >> ~/.bash_profile << 'EOF'
# Source bashrc for interactive shells
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF

echo "================================"
echo "✅ Setup Complete!"
echo "================================"
echo ""
echo "📂 Directory Structure:"
echo "   Your repo: /workspaces/LLM_FineTune_RAG_Production/"
echo "   Project:   /workspaces/LLM_FineTune_RAG_Production/LLM-Engineers-Handbook/"
echo ""
echo "🐍 Python Environment:"
echo "   Python: $(python --version 2>&1)"
echo "   Pyenv: $(pyenv --version 2>&1)"
echo "   Poetry: $(poetry --version 2>&1)"
echo ""
echo "📦 Virtual Environment:"
poetry env info | grep "Path:" || true
echo ""
echo "⚙️  Next Steps:"
echo "   1. Edit .env file with your credentials"
echo "      Location: $PROJECT_DIR/.env"
echo "   2. Run 'poetry shell' to activate the virtual environment"
echo "   3. Use 'poetry poe <command>' to run project tasks"
echo ""
echo "📚 Common Commands:"
echo "   project                # Quick cd to project directory"
echo "   poetry shell           # Activate virtual environment"
echo "   poetry poe --help      # See available Poe tasks"
echo "   poetry install         # Install/update dependencies"
echo "   poetry show            # List installed packages"
echo "   pyenv versions         # List Python versions"
echo "   python --version       # Check current Python version"
echo ""
echo "💡 Tip: New terminals will automatically start in the project directory!"
echo ""
