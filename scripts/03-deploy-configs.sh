#!/usr/bin/env bash
# 03-deploy-configs.sh  Deploy Caelestia configuration files to ~/.config

BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"
SRC_DIR="$BUNDLE_DIR/src"
DOTS_DIR="$SRC_DIR/dots"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde"
BACKUP_DIR_FILE="$CACHE_DIR/backup-dir.txt"
BACKUP_DIR=""

if [[ -f "$BACKUP_DIR_FILE" ]]; then
    BACKUP_DIR="$(cat "$BACKUP_DIR_FILE" 2>/dev/null || true)"
fi

if [[ -z "$BACKUP_DIR" ]]; then
    BACKUP_DIR="$BUNDLE_DIR/backups/$(date +%Y%m%d_%H%M%S)"
fi

echo
echo ""
echo "  Step 3/11  Config Deployment"
echo ""

mkdir -p "$BACKUP_DIR"

if [[ ! -d "$DOTS_DIR/fish" && ! -d "$DOTS_DIR/hypr" ]]; then
    echo "  [ERR] Missing src/dots content. Run: git submodule update --init --recursive src/dots"
    exit 1
fi

echo "  Recording previous login shell..."
getent passwd "$USER" | cut -d: -f7 > "$BACKUP_DIR/previous_shell.txt"

echo "  Backing up shell rc files..."
mkdir -p "$BACKUP_DIR/shellrc"

backup_shell_rc() {
    local src="$1"
    local key="$2"
    if [[ -f "$src" ]]; then
        cp "$src" "$BACKUP_DIR/shellrc/$key"
        printf 'present\n' > "$BACKUP_DIR/shellrc/$key.state"
    else
        printf 'missing\n' > "$BACKUP_DIR/shellrc/$key.state"
    fi
}

backup_shell_rc "$HOME/.bashrc" "bashrc"
backup_shell_rc "$HOME/.zshrc" "zshrc"
backup_shell_rc "$HOME/.config/fish/config.fish" "fish_config"

echo "  Deploying Caelestia configs..."
for config in btop fastfetch fish foot hypr kitty micro thunar; do
    if [[ -d "$DOTS_DIR/$config" ]]; then
        # Remove ((COMMENTED OUT FOR SOME REASON))
        rm -rf "$HOME/.config/$config"
        # Deploy
        cp -r "$DOTS_DIR/$config" "$HOME/.config/$config"
        echo "    Deployed: $config"
    fi
done

# Deploy starship.toml
if [[ -f "$DOTS_DIR/starship.toml" ]]; then
    cp "$DOTS_DIR/starship.toml" "$HOME/.config/starship.toml"
    echo "    Deployed: starship.toml"
fi

#  Deploy Bridge Files 
echo "  Deploying bridge files (bin, applications, systemd, kwin script)..."
mkdir -p \
    "$HOME/.local/bin" \
    "$HOME/.local/share/applications" \
    "$HOME/.config/systemd/user" \
    "$HOME/.local/share/kwin/scripts"

# bin scripts
if [[ -d "$SRC_DIR/bin" ]]; then
    # Copy scripts, but skip C++ source files and build files
    for file in "$SRC_DIR/bin/"*; do
        if [[ ! "$file" == *.cpp && ! "$file" == *CMakeLists.txt && ! -d "$file" ]]; then
            cp "$file" "$HOME/.local/bin/" 2>/dev/null || true
        fi
    done
    
    chmod +x "$HOME/.local/bin/kcolorpicker" \
              "$HOME/.local/bin/qs-kwin-bridge.py" 2>/dev/null || true
fi

# systemd user service
if [[ -f "$SRC_DIR/systemd/qs-kwin-bridge.service" ]] && \
   [[ -s "$SRC_DIR/systemd/qs-kwin-bridge.service" ]]; then
    cp "$SRC_DIR/systemd/qs-kwin-bridge.service" \
       "$HOME/.config/systemd/user/"
fi

# KWin script
if [[ -d "$SRC_DIR/kwin/quickshell-kde-bridge" ]]; then
    cp -r "$SRC_DIR/kwin/quickshell-kde-bridge" \
          "$HOME/.local/share/kwin/scripts/"
fi

# Update desktop database
update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
echo "  [OK]  Bridge files deployed."

echo "[OK]  Config deployment complete."
