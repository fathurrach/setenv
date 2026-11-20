#!/usr/bin/env bash
# ==============================================================================
# SETENV SHELL INTEGRATION & HELPER ALIASES
# Managed by setenv (https://github.com/fathurrach/setenv)
# ==============================================================================

# Ensure ~/.local/bin is in PATH
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Convenient alias to update dotfiles from GitHub across any server
setenv-update() {
    local repo_dir="${SETENV_DIR:-$HOME/.setenv}"
    if [ ! -d "$repo_dir" ]; then
        if [ -d "$HOME/Developments/tools/setenv" ]; then
            repo_dir="$HOME/Developments/tools/setenv"
        fi
    fi

    if [ -d "$repo_dir/.git" ]; then
        echo "==> Updating setenv from GitHub..."
        git -C "$repo_dir" pull --rebase || git -C "$repo_dir" pull
        if [ -f "$repo_dir/setup.sh" ]; then
            bash "$repo_dir/setup.sh" --no-pause
        fi
        if command -v tmux >/dev/null 2>&1 && [ -n "$TMUX" ]; then
            tmux source-file ~/.tmux.conf 2>/dev/null && tmux display-message "✓ setenv & tmux reloaded!"
        fi
        echo "✓ setenv successfully updated!"
    else
        echo "Error: setenv repository not found at $repo_dir"
        return 1
    fi
}
