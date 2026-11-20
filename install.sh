#!/usr/bin/env bash
# ==============================================================================
# SETENV REMOTE BOOTSTRAPPER (1-LINE INSTALLER)
# Usage: curl -fsSL https://raw.githubusercontent.com/fathurrach/setenv/main/install.sh | bash
# Repo: https://github.com/fathurrach/setenv
# ==============================================================================
set -e

REPO_URL="https://github.com/fathurrach/setenv.git"
TARGET_DIR="${HOME}/.setenv"

echo "=========================================================="
echo "  🚀 Installing setenv (Tmux & Starship Configuration)"
echo "  Target: $TARGET_DIR"
echo "=========================================================="

# 1. Check required tools (curl, git)
for cmd in curl git; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' is not installed."
        if [ "$(id -u)" -eq 0 ]; then
            echo "Attempting to install $cmd..."
            if command -v apt-get >/dev/null 2>&1; then
                apt-get update && apt-get install -y "$cmd"
            elif command -v yum >/dev/null 2>&1; then
                yum install -y "$cmd"
            elif command -v apk >/dev/null 2>&1; then
                apk add "$cmd"
            elif command -v pacman >/dev/null 2>&1; then
                pacman -Sy --noconfirm "$cmd"
            fi
        else
            echo "Please install '$cmd' first or run with sudo."
            exit 1
        fi
    fi
done

# 2. Check Tmux
if ! command -v tmux >/dev/null 2>&1; then
    echo "Notice: 'tmux' is not currently installed."
    if [ "$(id -u)" -eq 0 ]; then
        echo "Installing tmux..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update && apt-get install -y tmux
        elif command -v yum >/dev/null 2>&1; then
            yum install -y tmux
        elif command -v apk >/dev/null 2>&1; then
            apk add tmux
        elif command -v pacman >/dev/null 2>&1; then
            pacman -Sy --noconfirm tmux
        fi
    else
        echo "You can install tmux later using your system package manager."
    fi
fi

# 3. Check / Install Starship
if ! command -v starship >/dev/null 2>&1 && [ ! -f "$HOME/.local/bin/starship" ]; then
    echo "==> Installing Starship prompt..."
    mkdir -p "$HOME/.local/bin"
    if curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin" >/dev/null 2>&1; then
        echo "  [OK] Starship installed to $HOME/.local/bin/starship"
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "  [WARN] Automatic starship install failed. You can install it manually from https://starship.rs"
    fi
fi

# 4. Clone or Pull setenv repository
if [ -d "$TARGET_DIR/.git" ]; then
    echo "==> Updating existing setenv repository..."
    git -C "$TARGET_DIR" pull --rebase || git -C "$TARGET_DIR" pull
else
    echo "==> Cloning setenv repository from GitHub..."
    rm -rf "$TARGET_DIR"
    git clone --depth 1 "$REPO_URL" "$TARGET_DIR"
fi

# 5. Run Setup
chmod +x "$TARGET_DIR/setup.sh"
bash "$TARGET_DIR/setup.sh"

echo ""
echo "=========================================================="
echo "  🎉 setenv successfully installed & configured!"
echo "=========================================================="
echo "  Untuk mulai menikmati shell baru Anda:"
echo "  1. Jalankan: source ~/.bashrc (atau source ~/.zshrc)"
echo "  2. Masuk ke tmux: tmux"
echo "  3. Untuk update di masa depan cukup jalankan: setenv-update"
echo "=========================================================="
