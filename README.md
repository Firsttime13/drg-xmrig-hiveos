# drg-xmrig-hiveos

HiveOS custom miner wrapper for **DragonX XMRig v6.25.3**  
Source repos: [xmrig-hac](https://git.dragonx.is/DragonX/xmrig-hac) | [drg-xmrig release](https://git.dragonx.is/DragonX/drg-xmrig/releases/tag/v6.25.3)

---

## HiveOS Flight Sheet Setup

| Field | Value |
|---|---|
| **Miner Name** | `drg-xmrig` |
| **Installation URL** | `https://github.com/Firsttime13/drg-xmrig-hiveos/raw/main/drg-xmrig-6.25.3.tar.gz` |
| **Hash Algorithm** | `rx/0` (or your algo) |
| **Wallet and worker template** | `%WAL%` |
| **Pool URL** | `stratum+tcp://your.pool.here:3333` |
| **Pass** | `x` or `%WORKER_NAME%` |

### Extra Config Arguments (Optional)

You can pass these key=value pairs in the Extra Config Arguments box:

```
ALGO=rx/0
DONATE=1
NICEHASH=false
TLS=false
EXTRA_ARGS="--threads 4"
```

---

## Files in this wrapper

| File | Purpose |
|---|---|
| `h-manifest.conf` | Tells HiveOS the miner name, version, config path, log path |
| `h-config.sh` | Generates `config.json` from flight sheet variables |
| `h-run.sh` | Launches the xmrig binary |
| `h-stats.sh` | Reads xmrig HTTP API and feeds stats back to HiveOS dashboard |
| `install.sh` | Downloads the xmrig binary from the DragonX release page |

---

## Supported Algorithms

All algorithms supported by XMRig 6.25.x, including:

- `rx/0` — RandomX (XMR)
- `rx/wow` — RandomWOW
- `cn/r` — CryptoNight-R  
- `cn-lite/1` — CryptoNight-Lite
- `argon2/chukwa` — Chukwa
- and more — see [XMRig algo list](https://xmrig.com/docs/algorithms)

---

## Notes

- This is a **CPU miner** wrapper. GPU mining is not supported by XMRig in this build.
- The HTTP API runs on port `44444` internally for HiveOS stats polling.
- Log file: `/var/log/miner/drg-xmrig/drg-xmrig.log`
- Binary installs to: `/hive/miners/custom/drg-xmrig/xmrig`
