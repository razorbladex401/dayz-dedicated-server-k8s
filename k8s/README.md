# k8s

This directory contains Kubernetes manifests for running a DayZ dedicated server with filebrowser and status-page sidecars.

Tested against:
- Kubernetes `v1.29.4`
- Cilium `v1.15.4` (kube-proxy replacement)

## Current Deployment State

The `dayz` Deployment currently runs 3 containers in one Pod:

1. DayZ server container (`razorbladex401/dayz:latest`)
2. Filebrowser sidecar (`filebrowser/filebrowser:latest`)
3. Status page sidecar (`razorbladex401/dayz-status:latest`)

Notes:
- Filebrowser is currently started with `--noauth`.
- Filebrowser mounts DayZ data and profile volumes at `/srv/dayz` and `/srv/profile`.
- Filebrowser stores its DB at `/config/filebrowser.db` on `filebrowser-config-pvc`.
- Status page reads hostname from `serverDZ.cfg`, discovers loaded mods from `@` links under DayZ data, and exposes JSON at `/api/status`.
- There is no SSH container in the current deployment.

## Manifest Overview

### `namespace.yaml`
Creates namespace `dayz`.

### `configmap.yaml`
Contains:
- `serverDZ.cfg`
- `BEServer_x64.cfg`

Edit this file for your server and BattlEye configuration.

### `secrets.yaml`
Contains Kubernetes Secrets for the Deployment, including:
- `steamaccount` in `data:` form with base64-encoded values
- `dayz-rcon` in `stringData:` form for the BattlEye RCon password

Only `steamaccount` and `dayz-rcon` are required by the current `deployment.yaml`.

The BattlEye config is templated from `configmap.yaml` and the `RCON_PASSWORD` value is injected from `dayz-rcon` at pod startup.

### `pvc.yaml`
Creates these PVCs:
- `dayz-data-pvc` (`100Gi`) for game/server files
- `dayz-profile-pvc` (`50Gi`) for profile, logs, and runtime data
- `filebrowser-config-pvc` (`1Gi`) for filebrowser DB/config

### `deployment.yaml`
Deploys the DayZ server, filebrowser sidecar, and status page sidecar.

### `svc.yaml`
Creates `dayz` Service as `LoadBalancer` for game, Steam, and RCON ports.

### `admin-svc.yaml`
Creates `dayz-admin` Service as `LoadBalancer` with:
- `8080` for filebrowser
- `8090` for status page

### `serviceaccount.yaml`, `rbac.yaml`, `cronjob.yaml`
Creates the service account, RBAC, and scheduled rollout restart job for DayZ.

## How To Deploy

1. Set your Steam credentials in `secrets.yaml` under `steamaccount`.
2. Base64-encode the values because this file uses `data:`.

Example:

```bash
echo -n "your_steam_username" | base64
echo -n "your_steam_password" | base64
```

3. Update server settings in `configmap.yaml` (`serverDZ.cfg` and `BEServer_x64.cfg`).
4. Apply manifests:

```bash
kubectl apply -f k8s/
```

5. Check rollout:

```bash
kubectl -n dayz get pods
kubectl -n dayz rollout status deployment/dayz
```

6. Get external addresses:

```bash
kubectl -n dayz get svc dayz dayz-admin
```

## Accessing Filebrowser

Use the external IP/hostname of `dayz-admin` on port `8080`.

Because `--noauth` is enabled, anyone who can reach the service can browse and modify files. Keep this Service private to trusted networks.

## Accessing Status Page

Use the external IP/hostname of `dayz-admin` on port `8090`.

Endpoints:
- `/` HTML status page
- `/api/status` JSON payload with hostname, mods, and uptime
- `/api/logs?limit=N` JSON log tail output from mounted profile logs
- `/healthz` basic health check
- `/metrics` Prometheus-compatible metrics

Optional status container environment variables:
- `AUTO_REFRESH_SECONDS` default page refresh interval for the web UI
- `LOG_TAIL_LINES` number of log lines returned per tailed log file
- `RECENT_SESSION_LIMIT` number of completed player sessions kept in memory
- `MODLIST` (or fallback `MODSLIST`) expected workshop IDs used by loaded-mod verification
- `DISCORD_WEBHOOK_URL` or `STATUS_WEBHOOK_URL` to post player join/leave notifications
- `STATUS_WEBHOOK_TIMEOUT` webhook POST timeout in seconds
- `STATUS_LOG_LEVEL` logging level for the status app (`DEBUG`, `INFO`, `WARNING`, `ERROR`)
