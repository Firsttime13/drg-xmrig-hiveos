#!/usr/bin/env bash

# DragonX XMRig (drg-xmrig) HiveOS Custom Miner Wrapper
# h-run.sh - Launches the miner binary

[[ -z $MINER_DIR ]] && MINER_DIR=/hive/miners/custom

MINER_NAME=drg-xmrig
MINER_PATH=$MINER_DIR/$MINER_NAME
MINER_BINARY=$MINER_PATH/xmrig

# Ensure log directory exists
mkdir -p /var/log/miner/$MINER_NAME

# Make binary executable (in case permissions were lost)
chmod +x $MINER_BINARY 2>/dev/null

# Parse any raw EXTRA_ARGS from user config
eval "$CUSTOM_USER_CONFIG" 2>/dev/null
EXTRA="${EXTRA_ARGS:-}"

cd $MINER_PATH

echo ">>> Starting drg-xmrig v6.25.3"
echo ">>> Binary: $MINER_BINARY"
echo ">>> Config: $MINER_PATH/config.json"

# Launch xmrig
# --no-color keeps logs clean in HiveOS log view
exec $MINER_BINARY \
    --config=$MINER_PATH/config.json \
    --no-color \
    $EXTRA \
    2>&1 | tee /var/log/miner/$MINER_NAME/$MINER_NAME.log
