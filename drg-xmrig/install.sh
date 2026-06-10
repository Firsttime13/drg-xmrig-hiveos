#!/usr/bin/env bash

# DragonX XMRig (drg-xmrig) HiveOS Custom Miner Wrapper
# install.sh
# This script is called by HiveOS after extracting the wrapper tar.gz.
# It downloads the actual xmrig binary from the DragonX release page.
#
# Release source: https://git.dragonx.is/DragonX/drg-xmrig/releases/tag/v6.25.3

set -e

MINER_NAME=drg-xmrig
MINER_VERSION=6.25.3
INSTALL_DIR=/hive/miners/custom/$MINER_NAME

# DragonX release URL - update this URL when a new binary is released
# The binary should be a linux-x64 static build of xmrig
RELEASE_BASE="https://git.dragonx.is/DragonX/drg-xmrig/releases/download/v${MINER_VERSION}"

# Try common xmrig Linux release filenames from DragonX repo
BINARY_URLS=(
    "${RELEASE_BASE}/xmrig-${MINER_VERSION}-linux-static-x64.tar.gz"
    "${RELEASE_BASE}/xmrig-${MINER_VERSION}-linux-x64.tar.gz"
    "${RELEASE_BASE}/drg-xmrig-${MINER_VERSION}-linux-x64.tar.gz"
    "${RELEASE_BASE}/xmrig-linux-static-x64.tar.gz"
)

echo ">>> Installing DragonX XMRig v${MINER_VERSION} for HiveOS"
echo ">>> Install directory: $INSTALL_DIR"

mkdir -p $INSTALL_DIR
cd /tmp

DOWNLOAD_OK=false
for url in "${BINARY_URLS[@]}"; do
    echo ">>> Trying: $url"
    if wget -q --timeout=60 -O drg-xmrig-release.tar.gz "$url" 2>/dev/null; then
        DOWNLOAD_OK=true
        break
    fi
done

if [[ $DOWNLOAD_OK == false ]]; then
    echo "!!! Auto-download failed. Attempting git clone build from source..."
    echo "!!! If this also fails, manually place the xmrig binary at:"
    echo "!!!   $INSTALL_DIR/xmrig"
    echo "!!! Binary source: https://git.dragonx.is/DragonX/drg-xmrig"

    # Last resort: try the HAC fork
    HAC_URL="https://git.dragonx.is/DragonX/xmrig-hac/releases/latest/download/xmrig-linux-static-x64.tar.gz"
    echo ">>> Trying HAC fork: $HAC_URL"
    wget -q --timeout=60 -O drg-xmrig-release.tar.gz "$HAC_URL" || {
        echo "!!! All download attempts failed. Please manually install the binary."
        exit 1
    }
fi

echo ">>> Extracting release archive..."
tar -xzf drg-xmrig-release.tar.gz -C /tmp/drg-extract --strip-components=1 2>/dev/null \
    || tar -xzf drg-xmrig-release.tar.gz -C /tmp/drg-extract 2>/dev/null || true

# Find and copy the xmrig binary
BINARY=$(find /tmp/drg-extract -name "xmrig" -type f 2>/dev/null | head -1)
if [[ -z $BINARY ]]; then
    # Maybe it's in the archive root
    BINARY=$(find /tmp -maxdepth 3 -name "xmrig" -type f 2>/dev/null | head -1)
fi

if [[ -n $BINARY ]]; then
    cp "$BINARY" $INSTALL_DIR/xmrig
    chmod +x $INSTALL_DIR/xmrig
    echo ">>> Binary installed: $INSTALL_DIR/xmrig"
    $INSTALL_DIR/xmrig --version 2>/dev/null || true
else
    echo "!!! Could not find xmrig binary in extracted archive."
    echo "!!! Please manually place xmrig at: $INSTALL_DIR/xmrig"
    ls /tmp/drg-extract/ 2>/dev/null || true
fi

# Cleanup
rm -rf /tmp/drg-xmrig-release.tar.gz /tmp/drg-extract

# Create log directory
mkdir -p /var/log/miner/$MINER_NAME

echo ">>> DragonX XMRig wrapper install complete."
