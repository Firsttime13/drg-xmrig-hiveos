#!/usr/bin/env bash

# DragonX XMRig (drg-xmrig) HiveOS Custom Miner Wrapper
# h-stats.sh - Reads xmrig HTTP API on port 44444 and exports HiveOS stats
#
# This script is SOURCED (not executed) by HiveOS agent.
# It MUST set two variables:
#   $khs    - total hashrate in KH/s (numeric)
#   $stats  - JSON stats blob

MINER_NAME=drg-xmrig
API_PORT=44444
API_URL="http://127.0.0.1:${API_PORT}"

# Query xmrig summary endpoint
SUMMARY=$(curl -s --connect-timeout 5 --max-time 10 \
    "${API_URL}/2/summary" 2>/dev/null)

if [[ -z $SUMMARY ]]; then
    # Miner not responding yet – return zeros so HiveOS doesn't error out
    khs=0
    stats='{"hs":[],"temp":[],"fan":[],"uptime":0,"ar":[0,0],"ver":"drg-xmrig-6.25.3"}'
    return 2>/dev/null; exit
fi

# ------------------------------------------------------------------
# Parse summary JSON fields using python3 (always available on HiveOS)
# ------------------------------------------------------------------
PARSE=$(python3 - <<'PYEOF'
import sys, json, os

raw = os.environ.get("SUMMARY", "")
if not raw:
    sys.exit(1)

try:
    d = json.loads(raw)
except Exception:
    sys.exit(1)

# Hashrate
hr = d.get("hashrate", {})
total = hr.get("total", [0])[0] or 0          # 10-sec avg
khs = round(total / 1000, 3)

# Accepted / Rejected
results = d.get("results", {})
accepted = results.get("shares_good", 0)
rejected = results.get("shares_total", 0) - accepted
if rejected < 0:
    rejected = 0

# Uptime
uptime = d.get("uptime", 0)

# Version
ver = d.get("version", "drg-xmrig-6.25.3")

# Per-thread hashrates (used as per-device breakdown in HiveOS)
threads = hr.get("threads", [])
hs_arr = [round((t[0] or 0) / 1000, 3) for t in threads]

print(f"{khs}|{accepted}|{rejected}|{uptime}|{ver}|{json.dumps(hs_arr)}")
PYEOF
export SUMMARY="$SUMMARY"
PARSE=$(python3 -c "
import sys, json, os

raw = '''$SUMMARY'''

try:
    d = json.loads(raw)
except Exception as e:
    print('0|0|0|0|drg-xmrig-6.25.3|[]')
    sys.exit(0)

hr = d.get('hashrate', {})
total = hr.get('total', [0])
if isinstance(total, list):
    total = total[0] or 0
else:
    total = 0
khs_val = round(total / 1000, 3)

results = d.get('results', {})
accepted = results.get('shares_good', 0)
total_shares = results.get('shares_total', 0)
rejected = max(0, total_shares - accepted)

uptime = d.get('uptime', 0)
ver = d.get('version', 'drg-xmrig-6.25.3')

threads = hr.get('threads', [])
hs_arr = [round((t[0] if isinstance(t, list) and t else 0) / 1000, 3) for t in threads]

print(str(khs_val) + '|' + str(accepted) + '|' + str(rejected) + '|' + str(uptime) + '|' + ver + '|' + json.dumps(hs_arr))
" 2>/dev/null)

if [[ -z $PARSE ]]; then
    khs=0
    stats='{"hs":[],"temp":[],"fan":[],"uptime":0,"ar":[0,0],"ver":"drg-xmrig-6.25.3"}'
    return 2>/dev/null; exit
fi

IFS='|' read -r khs_val accepted rejected uptime ver hs_json <<< "$PARSE"

khs=${khs_val:-0}

# ------------------------------------------------------------------
# Temperature and fan: CPU miners don't expose GPU data through xmrig
# Pull system CPU temp from HiveOS agent helpers when available
# ------------------------------------------------------------------
cpu_temp=0
if command -v cpu-temp &>/dev/null; then
    cpu_temp=$(cpu-temp 2>/dev/null | awk '{print int($1)}')
fi
[[ -z $cpu_temp ]] && cpu_temp=0

stats=$(cat <<STATS_EOF
{
    "hs": ${hs_json:-[]},
    "hs_units": "khs",
    "temp": [$cpu_temp],
    "fan": [],
    "uptime": ${uptime:-0},
    "ver": "${ver:-drg-xmrig-6.25.3}",
    "ar": [${accepted:-0}, ${rejected:-0}],
    "algo": "rx/0"
}
STATS_EOF
)
