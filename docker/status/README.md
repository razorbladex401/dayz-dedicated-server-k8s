# dayz-status

A lightweight status sidecar for the DayZ dedicated server. It exposes a web
status page, JSON/metrics endpoints, and optional Discord webhook notifications
for player join/leave activity.

The app is a single Python file ([app.py](app.py)) built on the Python standard
library `http.server` — no third-party Python dependencies. The container image
bundles [`bercon-cli`](https://github.com/WoozyMasta/bercon-cli) as a BattlEye
RCON fallback.

## What it does

- Serves an HTML status dashboard with server hostname, mission, loaded mods,
  logged-in players, recent player sessions, BattlEye readiness, and log tails.
- Queries logged-in players over BattlEye RCON (raw UDP protocol first, then
  `bercon-cli`), with a best-effort fallback to parsing profile logs.
- Verifies loaded mod symlinks against an expected mod ID list (`MODLIST`).
- Sends Discord notifications when players join or leave.
- Exposes Prometheus metrics at `/metrics`.

A background poller thread periodically rebuilds status (default every 30s) so
player-change webhooks fire even when nobody is viewing the dashboard.

## Endpoints

All endpoints are served on `0.0.0.0:8090`.

| Path | Description |
| --- | --- |
| `/` | HTML status dashboard (with client-side auto-refresh + theme toggle). |
| `/api/status` | Full status payload as JSON. |
| `/api/logs?limit=N` | Recent log tails as JSON (`limit` optional). |
| `/metrics` | Prometheus exposition format metrics. |
| `/healthz` | Liveness probe — returns `ok`. |
| `/debug` | Detailed RCON / bercon / log-fallback diagnostics as JSON. |

## Environment variables

### RCON / player discovery

| Variable | Default | Description |
| --- | --- | --- |
| `RCON_HOST` | `127.0.0.1` | Primary RCON host to query. |
| `RCON_PORT` | `2310` | BattlEye RCON UDP port. |
| `RCON_PASSWORD` | _(empty)_ | BattlEye RCON password. Required for live player queries. |
| `RCON_TIMEOUT` | `1.5` | Per-request RCON timeout (seconds). |
| `RCON_TRANSPORT` | `auto` | `udp`, `tcp`, or `auto` (auto uses UDP). |
| `POD_IP` | _(empty)_ | Extra host candidate (e.g. the pod IP). |
| `BERCON_ENABLE` | `true` | Enable the `bercon-cli` fallback. |
| `BERCON_BIN` | `/usr/local/bin/bercon-cli` | Path to the `bercon-cli` binary. |

### Status page

| Variable | Default | Description |
| --- | --- | --- |
| `STATUS_LOG_LEVEL` | `INFO` | Python log level (`DEBUG`, `INFO`, `WARNING`, ...). |
| `AUTO_REFRESH_SECONDS` | `30` | Default dashboard auto-refresh interval (client-side). |
| `LOG_TAIL_LINES` | `40` | Number of log lines included in tails. |
| `RECENT_SESSION_LIMIT` | `15` | Max completed player sessions retained/displayed. |
| `STATUS_POLL_SECONDS` | `30` | Background poll interval for webhook detection. `0` disables the poller. |
| `MODLIST` / `MODSLIST` | _(empty)_ | Expected Workshop mod IDs (separated by space, comma, or semicolon) used for mod verification. |

### Discord webhook

| Variable | Default | Description |
| --- | --- | --- |
| `DISCORD_WEBHOOK_URL` | _(empty)_ | Discord webhook URL. Notifications are disabled when empty. |
| `STATUS_WEBHOOK_URL` | _(empty)_ | Alternate webhook URL (used if `DISCORD_WEBHOOK_URL` is unset). |
| `STATUS_WEBHOOK_TIMEOUT` | `3.0` | Webhook HTTP request timeout (seconds). |

## Mounts

The app reads from these paths inside the container:

| Path | Purpose |
| --- | --- |
| `/config/serverDZ.cfg` | Server config (hostname, mission template). |
| `/srv/dayz` | DayZ data root — used to enumerate `@mod` symlinks. |
| `/srv/profile` | Profile dir — used for log tails and the log-based player fallback. |
| `/battleye` | BattlEye config (`beserver_x64*.cfg`) for readiness checks. |

> Note: the game container mounts the DayZ data at `/home/steam/dayz`, while this
> sidecar mounts the same volume at `/srv/dayz`. The app remaps absolute symlink
> targets (`/home/steam/dayz` → `/srv/dayz`, `/home/steam/profile` → `/srv/profile`)
> so mod symlinks are not falsely reported as broken.

## Run (standalone)

```sh
docker run --rm -p 8090:8090 \
  -e RCON_PASSWORD=changeme \
  -e DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/... \
  -v /path/to/serverDZ.cfg:/config/serverDZ.cfg:ro \
  -v /path/to/dayz:/srv/dayz:ro \
  -v /path/to/profile:/srv/profile:ro \
  razorbladex401/dayz-status:latest
```

Then open <http://localhost:8090/>.

In Kubernetes this image runs as the `dayz-status` sidecar in the server pod —
see [k8s/deployment.yaml](../../k8s/deployment.yaml).

## Notes

- Discord is fronted by Cloudflare, which rejects the default
  `Python-urllib` User-Agent with `403 Forbidden`. The webhook request therefore
  sends an explicit `User-Agent` header.
- The first status build seeds the player snapshot silently (no notification);
  subsequent changes are reported.
- Join/leave notifications and session tracking only use authoritative RCON /
  `bercon-cli` data. The log-based fallback (which parses logs that persist
  across restarts and can list stale players) is never used to seed the snapshot
  or emit webhooks, preventing phantom "left" notifications after a restart.
- Player-change detection granularity equals `STATUS_POLL_SECONDS`. After a
  container restart the in-memory snapshot resets and is re-seeded on the first
  authoritative poll.
