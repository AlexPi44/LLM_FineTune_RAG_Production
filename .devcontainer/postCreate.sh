#!/usr/bin/env bash
set -ex

echo "================================"
echo "Starting postCreate script"
echo "================================"

# Navigate to project directory
cd /workspaces/LLM_FineTune_RAG_Production/LLM-Engineers-Handbook

echo "Current directory: $(pwd)"
echo "User: $(whoami)"
echo "Home: $HOME"

# Verify directory structure
if [ ! -f "pyproject.toml" ]; then
    echo "ERROR: pyproject.toml not found!"
    echo "Directory contents:"
    ls -la
    exit 1
fi

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
    echo "Pyenv initialized successfully"
    pyenv --version
else
    echo "WARNING: pyenv not found, installing manually..."
    curl https://pyenv.run | bash
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv init --path)"
fi

# Check if .python-version file exists
if [ -f ".python-version" ]; then
    REQUIRED_PYTHON=$(cat .python-version)
    echo "Found .python-version: $REQUIRED_PYTHON"
    
    # Install the required Python version if not already installed
    if ! pyenv versions | grep -q "$REQUIRED_PYTHON"; then
        echo "Installing Python $REQUIRED_PYTHON with pyenv..."
        pyenv install "$REQUIRED_PYTHON"
    fi
    
    # Set local Python version
    pyenv local "$REQUIRED_PYTHON"
    echo "Set Python version to: $(pyenv version)"
else
    echo "No .python-version file found, using system Python"
fi

echo "================================"
echo "Current Python version:"
python --version
which python

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

echo "Poetry version:"
poetry --version
which poetry

# Configure Poetry
echo "Configuring Poetry..."
poetry config virtualenvs.in-project true
poetry config virtualenvs.create true
poetry config virtualenvs.prefer-active-python true

echo "Poetry configuration:"
poetry config --list

echo "================================"
echo "Installing project dependencies"
echo "================================"

# Install dependencies
poetry install --without aws --no-interaction --no-ansi

# Verify virtual environment
echo "Poetry environment info:"
poetry env info

# Show installed packages
echo "Installed packages:"
poetry show --tree || true

echo "================================"
echo "Setting up pre-commit hooks"
echo "================================"

# Install pre-commit hooks
poetry run pre-commit install || echo "Warning: pre-commit install failed (non-critical)"

echo "================================"
echo "Configuring shell environment"
echo "================================"

# Create/update .bashrc with all necessary configurations
cat >> ~/.bashrc << 'EOF'

# ===== LLM Project Environment Setup =====

# Poetry PATH
export PATH="$HOME/.local/bin:$PATH"

# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Initialize pyenv
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv init --path)"
fi

# Auto-cd to project directory on new terminal
if [ "$PWD" = "/workspaces/LLM_FineTune_RAG_Production" ]; then
    cd LLM-Engineers-Handbook 2>/dev/null || true
fi

# Activate poetry virtual environment if it exists
if [ -f "/workspaces/LLM_FineTune_RAG_Production/LLM-Engineers-Handbook/pyproject.toml" ]; then
    cd /workspaces/LLM_FineTune_RAG_Production/LLM-Engineers-Handbook 2>/dev/null || true
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
echo "Setup Complete!"
echo "================================"
echo ""
echo "Available tools:"
echo "  Python: $(python --version 2>&1)"
echo "  Poetry: $(poetry --version 2>&1)"
echo "  Pyenv: $(pyenv --version 2>&1)"
echo ""
echo "Project location: /workspaces/LLM_FineTune_RAG_Production/LLM-Engineers-Handbook"
echo ""
echo "To activate the environment in a new terminal:"
echo "  source ~/.bashrc"
echo ""
echo "Common commands:"
echo "  poetry --version       # Check poetry"
echo "  poetry env info        # Virtual environment info"
echo "  poetry install         # Install dependencies"
echo "  poetry run python      # Run Python in venv"
echo "  poetry shell           # Activate venv shell"
echo "  pyenv versions         # List Python versions"
echo "  pyenv global X.X.X     # Set global Python version"
echo ""
