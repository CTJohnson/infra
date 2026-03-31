#!/usr/bin/env bash
# migrate-from-yadm.sh
# ─────────────────────────────────────────────────────────────────────────────
# Targeted migration from yadm (git clone) to chezmoi.
#
# Reads files from a git clone of your yadm dotfiles repo (since yadm itself
# may be broken). Copies the useful files into $HOME, then runs chezmoi add.
#
# Prerequisites:
#   - chezmoi is installed and initialized (chezmoi init already run)
#   - Your yadm repo is cloned somewhere (default: /tmp/dotfiles-yadm)
#
# Usage:
#   bash migrate-from-yadm.sh [--dry-run]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

YADM_CLONE="${YADM_CLONE:-/tmp/dotfiles-yadm}"
PRIMARY_BRANCH="${PRIMARY_BRANCH:-mbp_m4pro}"

if [[ ! -d "$YADM_CLONE/.git" ]]; then
    echo "ERROR: No git repo found at $YADM_CLONE"
    echo "Clone it first: git clone https://gitlab.com/CTJohnson/dotfiles.git $YADM_CLONE"
    exit 1
fi

CHEZMOI_SOURCE="$(chezmoi source-path 2>/dev/null || echo "")"
if [[ -z "$CHEZMOI_SOURCE" ]]; then
    echo "ERROR: chezmoi not initialized. Run 'chezmoi init' first."
    exit 1
fi

echo "==> yadm clone: $YADM_CLONE"
echo "==> primary branch: $PRIMARY_BRANCH"
echo "==> chezmoi source: $CHEZMOI_SOURCE"
echo ""

# ─── Files worth migrating (curated from branch analysis) ────────────────────
# These are the files that contain real, intentional configuration.
# Everything else (caches, generated files, plugin dirs, secrets) is excluded.

MIGRATE_FILES=(
    # Shell
    .zshrc

    # Terminal
    .config/ghostty/config
    .config/ghostty/themes/gruvbox-material-hard-dark

    # Editor (LazyVim)
    .config/nvim/init.lua
    .config/nvim/lazyvim.json
    .config/nvim/stylua.toml
    .config/nvim/ftdetect/ipynb.lua
    .config/nvim/lua/config/autocmds.lua
    .config/nvim/lua/config/keymaps.lua
    .config/nvim/lua/config/lazy.lua
    .config/nvim/lua/config/options.lua
    .config/nvim/lua/plugins/blink.lua
    .config/nvim/lua/plugins/colorscheme.lua
    .config/nvim/lua/plugins/completion.lua
    .config/nvim/lua/plugins/conform.lua
    .config/nvim/lua/plugins/jupytext.lua
    .config/nvim/lua/plugins/lsp.lua
    .config/nvim/lua/plugins/notebook.lua
    .config/nvim/lua/plugins/nvim-devcontainer-cli.lua
    .config/nvim/lua/plugins/oil.lua
    .config/nvim/lua/plugins/snacks.lua
    .config/nvim/lua/plugins/toggleterm.lua
    .config/nvim/lua/plugins/tools.lua
    .config/nvim/lua/plugins/treesitter.lua
    .config/nvim/lua/plugins/ui.lua
    .config/nvim/lua/plugins/venv-selector.lua

    # Prompt
    .config/starship/starship.toml

    # Tmux
    .tmux.conf
    .tmux/update-plugins-daily.sh

    # Zsh plugin list (antidote/antibody style)
    .zsh_plugins.txt
)

# ─── Files to pull from bigMac branch (shared config not on mbp_m4pro) ───────
BIGMAC_FILES=(
    .gitconfig
    .config/bat/config
    .ssh/config
)

cd "$YADM_CLONE"

# ─── Checkout and copy from primary branch ────────────────────────────────────
echo "==> Checking out $PRIMARY_BRANCH..."
git checkout "origin/$PRIMARY_BRANCH" --quiet 2>/dev/null || git checkout "$PRIMARY_BRANCH" --quiet

declare -a ADDED=()
declare -a SKIPPED=()

copy_and_add() {
    local file="$1"
    local source_path="$YADM_CLONE/$file"
    local dest_path="$HOME/$file"

    if [[ ! -e "$source_path" ]]; then
        SKIPPED+=("$file (not in branch)")
        return
    fi

    if $DRY_RUN; then
        echo "  [dry-run] copy $file -> $dest_path -> chezmoi add"
        ADDED+=("$file")
        return
    fi

    # Ensure parent directory exists
    mkdir -p "$(dirname "$dest_path")"

    # Copy from clone to $HOME (if not already there or different)
    if [[ ! -e "$dest_path" ]] || ! diff -q "$source_path" "$dest_path" &>/dev/null; then
        cp "$source_path" "$dest_path"
        echo "  Copied: $file"
    else
        echo "  Same:   $file (already in \$HOME)"
    fi

    # Add to chezmoi
    chezmoi add "$dest_path" 2>/dev/null && ADDED+=("$file") || {
        echo "  WARN: chezmoi add failed for $file"
        SKIPPED+=("$file (chezmoi add failed)")
    }
}

echo ""
echo "── From $PRIMARY_BRANCH ──"
for file in "${MIGRATE_FILES[@]}"; do
    copy_and_add "$file"
done

# ─── Checkout and copy from bigMac branch ─────────────────────────────────────
echo ""
echo "── From bigMac (shared configs) ──"
git checkout "origin/bigMac" --quiet 2>/dev/null || git checkout "bigMac" --quiet

for file in "${BIGMAC_FILES[@]}"; do
    copy_and_add "$file"
done

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════"
echo " Migration summary"
echo "════════════════════════════════════════════════════════"
echo "  Added to chezmoi : ${#ADDED[@]}"
echo "  Skipped          : ${#SKIPPED[@]}"
echo ""

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo "── Skipped files ──"
    for f in "${SKIPPED[@]}"; do
        echo "    $f"
    done
    echo ""
fi

if ! $DRY_RUN && [[ ${#ADDED[@]} -gt 0 ]]; then
    echo "── Next steps ──"
    echo ""
    echo "  1. Review what chezmoi captured:"
    echo "     chezmoi diff"
    echo ""
    echo "  2. Some files may need to become templates (.tmpl) if they"
    echo "     should vary per machine. Candidates:"
    echo "       .zshrc          (already templated in chezmoi — merge manually)"
    echo "       .gitconfig      (already templated — merge with config.tmpl)"
    echo "       .ssh/config     (host entries may vary per machine)"
    echo ""
    echo "  3. Commit the chezmoi source:"
    echo "     chezmoi cd"
    echo "     git add -A && git commit -m 'feat: migrate dotfiles from yadm'"
    echo ""
    echo "  4. Nuke yadm (dotfiles stay in place, just removing yadm state):"
    echo "     rm -rf ~/.local/share/yadm ~/.config/yadm"
fi
