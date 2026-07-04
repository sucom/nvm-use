#!/usr/bin/env bash

NVM_USE_VERSION="1.0.0"

# =====================================================================
# Sourced Script Guardrail
# =====================================================================
# Since this script MUST be sourced to alter the active terminal memory,
# using 'exit' would kill the entire window. We use 'return' instead.
if [ "$0" = "$BASH_SOURCE" ]; then
    echo "[Error] This script must be sourced, not executed directly."
    echo "Use: source $0 [version]"
    exit 1
fi

# =====================================================================
# Phase 1: Dynamic Environment & Path Normalization
# =====================================================================
NVM_WIN=""

# Map variables based on OS: Windows (Git-Bash) uses NVM_HOME, Mac/Linux uses NVM_DIR
if [ -n "$NVM_HOME" ]; then
    # Windows (Git-Bash) environment path conversion
    NVM_WIN="1"
    if command -v cygpath >/dev/null 2>&1 && [[ "$NVM_HOME" == *'\'* ]]; then
        NODE_VERSIONS_DIR=$(cygpath -u "$NVM_HOME")
    else
        NODE_VERSIONS_DIR="$NVM_HOME"
    fi
elif [ -n "$NVM_DIR" ] || [ -d "$HOME/.nvm" ]; then
    # Mac/Linux standard NVM installation footprint
    RESOLVED_NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    NODE_VERSIONS_DIR="$RESOLVED_NVM_DIR/versions/node"
else
    echo "[nvm-use] Error: Neither NVM_HOME nor NVM_DIR could be resolved. Configure nvm first."
    echo "[nvm-use] Go to the NVM Site(s) and follow the installation instructions for your operating system."
    echo "[nvm-use] - NVM Documentation - nvmnode.com (https://www.nvmnode.com/)"
    echo "[nvm-use] - nvm-windows - GitHub (https://github.com/coreybutler/nvm-windows) - for Windows"
    echo "[nvm-use] - nvm - GitHub (https://github.com/nvm-sh/nvm) - for Mac/Linux"
    return 1
fi

# Anti-Pollution Guard: Lock in the pristine PATH on the first initialization
if [ -z "$USER_BASE_PATH" ]; then
    export USER_BASE_PATH="$PATH"
fi

# =====================================================================
# Phase 2: Target Version Resolution
# =====================================================================
REQ_VER="$1"
REQ_ACTION="$2"

# Portable case-insensitive mapping helpers using standard standard 'tr'
REQ_VER_LOWER=$(echo "$REQ_VER" | tr '[:upper:]' '[:lower:]')
REQ_ACTION_LOWER=$(echo "$REQ_ACTION" | tr '[:upper:]' '[:lower:]')

# Smart Argument Flipper: If user types 'nvm-use default 22', swap them
# so the rest of the script processes it as version '22' with action 'default'
if [ "$REQ_VER_LOWER" = "default" ] && [ -n "$REQ_ACTION" ] && [ "$REQ_ACTION_LOWER" != "default" ]; then
    TEMP_VER="$REQ_VER"
    REQ_VER="$REQ_ACTION"
    REQ_ACTION="$TEMP_VER"

    # Re-sync lowercase helpers for downstream matching
    REQ_VER_LOWER=$(echo "$REQ_VER" | tr '[:upper:]' '[:lower:]')
    REQ_ACTION_LOWER=$(echo "$REQ_ACTION" | tr '[:upper:]' '[:lower:]')
fi

# =====================================================================
# Smart Info & Help Flag Interceptor
# =====================================================================
case "$REQ_VER_LOWER" in
    v|ver|version|-v|--v|-ver|--ver|-version|--version)
        echo "[nvm-use] version v$NVM_USE_VERSION"
        return 0
        ;;
    -|--|h|-h|--h|help|-help|--help|[?]|"/?")
        echo "Usage: nvm-use [version] [default]"
        echo ""
        echo "Examples:"
        echo "  nvm-use               - Use the version specified in .node-version or .nvmrc, or stay on current/global-default if none found."
        echo "  nvm-use 22            - Use the highest installed version matching 22.*"
        echo "  nvm-use v22.23.1      - Precise version matching"
        echo "  nvm-use 22 default    - Set the default version to the highest installed version matching 22.*"
        echo "  nvm-use default 22    - Set the default version to the highest installed version matching 22.*"
        echo "  nvm-use --help        - Displays command usage interface (also accepts -h, ?, /?)"
        echo "  nvm-use --version     - Displays the version of nvm-use (also accepts -v)"
        return 0
        ;;
    *)
        ;;
esac

# If no argument is passed, check for local configuration files
if [ -z "$REQ_VER" ]; then
    if [ -f .node-version ]; then
        REQ_VER=$(cat .node-version)
    elif [ -f .nvmrc ]; then
        REQ_VER=$(cat .nvmrc)
    fi
fi

# If still empty, evaluate against the global default path
if [ -z "$REQ_VER" ]; then
    echo "[nvm-use] No version specified and no .node-version/.nvmrc found."
    echo "[nvm-use] Staying on current/global-default."
    node -v
    return 0
fi

# Sanitization: Strip quotes, leading 'v', spaces, and trailing Windows CR (\r) characters
REQ_VER=$(echo "$REQ_VER" | tr -d '"' | sed 's/^v//' | tr -d '\r' | xargs)
REQ_VER_LOWER=$(echo "$REQ_VER" | tr '[:upper:]' '[:lower:]')

# =====================================================================
# Phase 3: Smart Directory Matching (Auto-pick Highest Match)
# =====================================================================
TARGET_PATH=""
TARGET_NAME=""
MATCH_COUNT=0

if [ "$REQ_VER_LOWER" = "default" ]; then
    TARGET_NAME="default"
else
    # Iterate through matching directories. Alphabetical ordering naturally
    # processes higher dot-versions last (overwriting previous matches).
    for dir in "$NODE_VERSIONS_DIR/v$REQ_VER"*; do
        # Guard against empty glob matches
        if [ -d "$dir" ]; then
            # Windows target check (binary directly inside version directory)
            if [ -f "$dir/node.exe" ]; then
                MATCH_COUNT=$((MATCH_COUNT + 1))
                TARGET_PATH="$dir"
                TARGET_NAME=$(basename "$dir")
            # Mac/Linux target check (binary nested within /bin directory)
            elif [ -f "$dir/bin/node" ]; then
                MATCH_COUNT=$((MATCH_COUNT + 1))
                TARGET_PATH="$dir/bin"
                TARGET_NAME=$(basename "$dir")
            fi
        fi
    done
fi

# =====================================================================
# Phase 4: Lazy-Loading / Installation Prompt
# =====================================================================
# Guard prompt against execution if the user requested the 'default' profile shortcut
if [ -z "$TARGET_PATH" ] && [ "$REQ_VER_LOWER" != "default" ]; then
    echo "[nvm-use] Version 'v$REQ_VER' is not installed locally."
    read -p "Would you like to download it now via nvm? [y/n]: " CHOICE
    if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
        # Check fallback availability for runtime installations
        if command -v nvm >/dev/null 2>&1 || [ "$(type -t nvm)" = "function" ]; then
            nvm install "$1"
            source "$BASH_SOURCE" "$1" "$2"
            return $?
        else
            echo "[nvm-use] Error: Native 'nvm' core engine must be loaded to install new runtimes."
            return 1
        fi
    fi
    return 1
fi

# =====================================================================
# Phase 5: Environment Execution & Verification
# =====================================================================
if [ "$MATCH_COUNT" -gt 1 ]; then
    echo "[nvm-use] Found $MATCH_COUNT matches. Auto-selecting highest version: $TARGET_NAME"
elif [ "$REQ_ACTION_LOWER" != "default" ]; then
    echo "[nvm-use] Mounting runtime version: $TARGET_NAME"
fi

# Lightning Fast Cross-Platform Process Isolation Swapping
if [ -n "$TARGET_PATH" ]; then
    export PATH="$TARGET_PATH:$USER_BASE_PATH"
else
    export PATH="$USER_BASE_PATH"
fi

# Execute Persistent System-Wide Defaults Only When explicitly Requested
if [ "$REQ_ACTION_LOWER" = "default" ]; then
    echo "[nvm-use] Setting $TARGET_NAME as default."
    if [ -n "$NVM_WIN" ]; then
        # Windows global symlink resolution update
        if command -v nvm >/dev/null 2>&1; then
            nvm use "$TARGET_NAME" >/dev/null 2>&1
        fi
    else
        # Mac/Linux: Native configuration write bypasses slow function sourcing constraints entirely
        if [ "$TARGET_NAME" = "default" ]; then
            echo "[nvm-use] Target is already the default profile."
        else
            mkdir -p "$RESOLVED_NVM_DIR/alias"
            echo "$TARGET_NAME" > "$RESOLVED_NVM_DIR/alias/default"
        fi
    fi
fi

node -v