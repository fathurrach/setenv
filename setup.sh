#!/usr/bin/env bash
# ==============================================================================
# SETENV SETUP SCRIPT (SYMLINKS, PLUGINS & CONFIGURATION)
# Managed by setenv (https://github.com/fathurrach/setenv)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="$(date +%Y%m%d_%H%M%S).bak"

echo "=========================================================="
echo "  Setting up Environment via setenv"
echo "  Source: $SCRIPT_DIR"
echo "=========================================================="

# 1. Helper function for safe symlinking with backup
link_file() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"

    if [ -L "$dest" ]; then
        local current_target
        current_target=$(readlink "$dest" || true)
        if [ "$current_target" = "$src" ]; then
            echo "  [OK] Already linked: $dest"
            return
        fi
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        echo "  [BACKUP] Backing up existing $dest to ${dest}.${BACKUP_SUFFIX}"
        mv "$dest" "${dest}.${BACKUP_SUFFIX}"
    fi

    ln -s "$src" "$dest"
    echo "  [LINKED] $dest -> $src"
}

# 2. Symlink Tmux configs
echo "==> Configuring Tmux..."
chmod +x "$SCRIPT_DIR/tmux/scripts/resource_info.sh"
link_file "$SCRIPT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$SCRIPT_DIR/tmux/scripts/resource_info.sh" "$HOME/.tmux/scripts/resource_info.sh"

# 3. Setup Tmux Plugin Manager (TPM)
echo "==> Checking Tmux Plugin Manager (TPM)..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "  [INSTALL] Cloning TPM..."
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
    echo "  [OK] TPM already installed."
fi

# Run TPM headless installer
if [ -f "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    echo "  [PLUGINS] Installing / updating tmux plugins..."
    bash "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
fi

# 4. Symlink Starship config
echo "==> Configuring Starship..."
link_file "$SCRIPT_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# 5. Inject shell integrations (bash & zsh)
echo "==> Configuring Shell integrations..."
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [ -f "$rc" ]; then
        # Starship init
        if ! grep -q "starship init" "$rc"; then
            shell_type="bash"
            [[ "$rc" == *".zshrc"* ]] && shell_type="zsh"
            echo "eval \"\$(starship init $shell_type)\"" >> "$rc"
            echo "  [SHELL] Injected starship init into $rc"
        fi

        # setenv shell env & helper
        if ! grep -q "setenv/shell/env.sh" "$rc"; then
            echo "" >> "$rc"
            echo "# setenv environment helper" >> "$rc"
            echo "export SETENV_DIR=\"$SCRIPT_DIR\"" >> "$rc"
            echo "[ -f \"\$SETENV_DIR/shell/env.sh\" ] && source \"\$SETENV_DIR/shell/env.sh\"" >> "$rc"
            echo "  [SHELL] Sourced setenv/shell/env.sh in $rc"
        fi
    fi
done

# 6. Reload tmux if running
if command -v tmux >/dev/null 2>&1 && [ -n "$TMUX" ]; then
    echo "==> Reloading active tmux session..."
    tmux source-file "$HOME/.tmux.conf" 2>/dev/null && tmux refresh-client -S 2>/dev/null || true
fi

echo "=========================================================="
echo "  ✓ Setup completed successfully!"
echo "=========================================================="
