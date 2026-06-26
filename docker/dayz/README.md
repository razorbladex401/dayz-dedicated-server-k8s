# Docker Entrypoint Reference

This directory contains the DayZ container entrypoint script used by the image:

- [entry-universal.sh](entry-universal.sh)

This script is copied into the image as `/home/steam/entry.sh` and runs as the container entrypoint.

## What the script does

At startup, [entry-universal.sh](entry-universal.sh) performs this sequence:

1. Decode Steam credentials if they were provided as base64.
2. Parse the mod list from `MODLIST` (or fallback `MODSLIST`).
3. Update DayZ server files with `steamcmd`.
4. Download workshop mods listed in `MODLIST`.
5. Rebuild mod symlinks in the game root as `@ModName`.
6. Copy mod `.bikey` files from each mod into `dayz/keys`.
7. Ensure BattlEye binaries are linked.
8. Start `DayZServer` with dynamic `-mod=` arguments.

## Script behavior by function

### `isBase64Value(value)`

Checks whether a value looks like valid printable base64 before decoding. This avoids trying to decode normal plaintext credentials.

### `normalizeSteamCredentials()`

If `STEAMACCOUNT` or `STEAMPASSWORD` look base64-encoded, decodes and exports them.

### `parseModsList()`

Reads mods from:

- `MODLIST` (primary)
- `MODSLIST` (fallback)

It accepts both separators:

- Space-separated: `1559212036 2534883520`
- Semicolon-separated: `1559212036;2534883520`

If no list is present, it returns a warning and no mods are installed.

### `getModDirName(mod_id)`

Resolves each workshop mod ID to a DayZ `@ModName` by reading:

- `${HOME}/${GAME}/steamapps/workshop/content/221100/<mod_id>/meta.cpp`

It extracts the `name = "..."` value, then normalizes spaces to hyphens (for a safe `-mod=` argument).

Examples:

- `Winter Chernarus` -> `Winter-Chernarus`
- `ZomBerry Admin Tools` -> `ZomBerry-Admin-Tools`

If `meta.cpp` is missing or parse fails, it falls back to the numeric mod ID.

### `logParsedModCount()`

Logs how many mod IDs were parsed from the environment.

### `updateGame()`

Runs `steamcmd` update for app `${APPID}` in `${HOME}/${GAME}`.

Login behavior:

- Uses anonymous login if `STEAMACCOUNT=anonymous`
- Otherwise uses `STEAMACCOUNT` + `STEAMPASSWORD`

### `installMods()`

1. Builds one `steamcmd` command with all `+workshop_download_item 221100 <modid>` entries.
2. Downloads mods.
3. Removes stale symlinks in `${HOME}/${GAME}` matching:
   - `@*`
   - `[0-9]*`
4. Recreates mod symlinks as `@<resolved_name>` pointing to each workshop folder.
5. Copies key files from both `keys/` and `Keys/` folder variants into `${HOME}/${GAME}/keys`.

### `setupBattleye()`

If BattlEye binaries are missing under `${HOME}/battleye`, creates symlinks pointing to `${HOME}/${GAME}/battleye` versions.

### `startGame()`

Builds `-mod=` dynamically from the resolved `@ModName` list and starts `DayZServer`.

- If `DISABLE_MODS=true`, mods are skipped and server starts without `-mod=`.
- Otherwise it joins resolved mod names using semicolons:
  - `-mod=@CF;@SchanaParty;@Trader`

## Environment variables

Common variables consumed by [entry-universal.sh](entry-universal.sh):

- `HOME`: Steam home path (typically `/home/steam`)
- `GAME`: Game install directory name (typically `dayz`)
- `APPID`: Steam app ID for DayZ dedicated server (`223350`)
- `STEAMACCOUNT`: Steam username or `anonymous`
- `STEAMPASSWORD`: Steam password (ignored for anonymous login)
- `PORT`: DayZ game port
- `CPUCOUNT`: Value passed to `-cpuCount`
- `MODLIST`: Primary workshop mod ID list
- `MODSLIST`: Backward-compatible fallback mod list variable
- `DISABLE_MODS`: Set to `true` to start without mods

## Notes for operators

- The script expects workshop content under app `221100` (DayZ workshop).
- Mod symlinks are rebuilt on each startup.
- If you add/remove major framework mods (for example CF) and the server crashes while loading world persistence, wipe DayZ persistence storage (`storage_1/data`) once so it can regenerate with the new mod set.
