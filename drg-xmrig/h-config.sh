#!/usr/bin/env bash

# DragonX XMRig (drg-xmrig) HiveOS Custom Miner Wrapper
# h-config.sh - Generates config.json from HiveOS flight sheet parameters
# Compatible with xmrig v6.25.3 (drg-xmrig fork)

[[ -z $MINER_DIR ]] && MINER_DIR=/hive/miners/custom

MINER_NAME=drg-xmrig
MINER_PATH=$MINER_DIR/$MINER_NAME

# ------------------------------------------------------------------
# Defaults / fallbacks
# ------------------------------------------------------------------
WALLET="${CUSTOM_TEMPLATE:-${CUSTOM_USER_CONFIG_WALLET}}"
POOL_URL="${CUSTOM_URL:-stratum+tcp://pool.supportxmr.com:3333}"
WORKER="${WORKER_NAME:-rig0}"
PASS="${CUSTOM_PASS:-x}"
ALGO="${CUSTOM_ALGO:-rx/0}"

# Allow override from Extra Config Arguments field
# Supported extra args:
#   ALGO=rx/0          - set mining algorithm
#   DONATE=1           - set donate-level (default 1)
#   CPU_THREADS=auto   - number of CPU threads (default: auto)
#   NICEHASH=true      - enable nicehash mode
#   TLS=true           - force TLS on pool connection
#   EXTRA_ARGS="..."   - pass raw xmrig CLI args (appended to run)

eval "$CUSTOM_USER_CONFIG" 2>/dev/null

[[ -z $ALGO ]]         && ALGO="rx/0"
[[ -z $DONATE ]]       && DONATE=1
[[ -z $CPU_THREADS ]]  && CPU_THREADS=-1     # -1 = xmrig auto-detect
[[ -z $NICEHASH ]]     && NICEHASH=false
[[ -z $TLS ]]          && TLS=false

# Determine rig-id / worker
RIG_ID="${WORKER_NAME:-${RIG_NAME:-worker}}"

# Log dir
mkdir -p /var/log/miner/$MINER_NAME

# ------------------------------------------------------------------
# Build pools array
# Multiple pools can be passed as semicolon-separated list in POOL_URL
# e.g.  stratum+tcp://pool1:3333;stratum+tcp://pool2:3333
# ------------------------------------------------------------------
IFS=';' read -ra POOL_LIST <<< "$POOL_URL"

pools_json=""
for url in "${POOL_LIST[@]}"; do
    [[ -z $url ]] && continue
    [[ $pools_json != "" ]] && pools_json+=","
    pools_json+="{
            \"url\": \"$url\",
            \"user\": \"$WALLET\",
            \"pass\": \"$PASS\",
            \"rig-id\": \"$RIG_ID\",
            \"nicehash\": $NICEHASH,
            \"tls\": $TLS,
            \"keepalive\": true,
            \"enabled\": true
        }"
done

# ------------------------------------------------------------------
# Thread count for cpu block
# ------------------------------------------------------------------
if [[ $CPU_THREADS == "-1" || $CPU_THREADS == "auto" ]]; then
    CPU_MAX_THREADS_HINT=100
    cpu_threads_key=""   # let xmrig auto-configure
else
    CPU_MAX_THREADS_HINT=$((CPU_THREADS * 10))
fi

# ------------------------------------------------------------------
# Write config.json
# ------------------------------------------------------------------
cat > $MINER_PATH/config.json <<EOF
{
    "api": {
        "id": null,
        "worker-id": "$RIG_ID",
        "port": 44444,
        "access-token": null,
        "restricted": true
    },
    "http": {
        "enabled": true,
        "host": "127.0.0.1",
        "port": 44444,
        "access-token": null,
        "restricted": true
    },
    "autosave": false,
    "background": false,
    "colors": true,
    "title": true,
    "algo": "$ALGO",
    "cpu": {
        "enabled": true,
        "huge-pages": true,
        "huge-pages-jit": false,
        "hw-aes": null,
        "priority": null,
        "memory-pool": false,
        "yield": true,
        "max-threads-hint": $CPU_MAX_THREADS_HINT,
        "asm": true,
        "argon2-impl": null,
        "cn/0": false,
        "cn-lite/0": false
    },
    "donate-level": $DONATE,
    "donate-over-proxy": 1,
    "log-file": "/var/log/miner/$MINER_NAME/$MINER_NAME.log",
    "pools": [
        $pools_json
    ],
    "print-time": 60,
    "health-print-time": 60,
    "retries": 5,
    "retry-pause": 5,
    "syslog": false,
    "tls": {
        "enabled": false,
        "protocols": null,
        "cert": null,
        "cert-key": null,
        "ciphers": null,
        "ciphersuites": null,
        "dhparam": null
    },
    "dns": {
        "ipv6": false,
        "ttl": 30
    },
    "user-agent": null,
    "verbose": 0,
    "watch": false
}
EOF

echo ">>> drg-xmrig config.json written"
echo ">>> Pool : $POOL_URL"
echo ">>> Wallet: $WALLET"
echo ">>> Algo  : $ALGO"
echo ">>> Worker: $RIG_ID"
