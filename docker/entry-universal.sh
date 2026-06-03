#!/bin/bash

function isBase64Value() {
    local value="$1"
    local decoded

    if [ -z "${value}" ]; then
        return 1
    fi

    # Fast fail for strings that cannot be base64.
    if [[ ! "${value}" =~ ^[A-Za-z0-9+/=]+$ ]]; then
        return 1
    fi

    decoded=$(printf '%s' "${value}" | base64 --decode 2>/dev/null) || return 1

    # Avoid decoding opaque binary data into credentials.
    if printf '%s' "${decoded}" | LC_ALL=C grep -q '[^[:print:][:space:]]'; then
        return 1
    fi

    return 0
}

function normalizeSteamCredentials() {
    if isBase64Value "${STEAMACCOUNT}"; then
        STEAMACCOUNT=$(printf '%s' "${STEAMACCOUNT}" | base64 --decode)
        export STEAMACCOUNT
        echo "Detected base64-encoded STEAMACCOUNT; decoded value."
    fi

    if isBase64Value "${STEAMPASSWORD}"; then
        STEAMPASSWORD=$(printf '%s' "${STEAMPASSWORD}" | base64 --decode)
        export STEAMPASSWORD
        echo "Detected base64-encoded STEAMPASSWORD; decoded value."
    fi
}

function parseModsList() {
    # Parse MODLIST (or MODSLIST fallback) as space/semicolon-separated IDs.
    local raw_modslist="${MODLIST:-${MODSLIST}}"
    local modslist

    if [ -z "${raw_modslist}" ]; then
        echo "Warning: MODLIST/MODSLIST environment variable is not set. No mods will be installed." >&2
        return 1
    fi

    # Replace semicolons with spaces for consistent parsing
    modslist="${raw_modslist//;/ }"

    # Output normalized content for array splitting in callers.
    echo "${modslist}"
}

function getModDirName() {
    # Extract the short 'name' value from a mod's meta.cpp file.
    # This is the identifier used for @ModName symlinks and the -mod= parameter.
    # Usage: getModDirName <mod_id>
    local mod_id="$1"
    local meta_file="${HOME}/${GAME}/steamapps/workshop/content/221100/${mod_id}/meta.cpp"

    if [ ! -f "${meta_file}" ]; then
        echo "Warning: meta.cpp not found for mod ${mod_id}, falling back to ID." >&2
        echo "${mod_id}"
        return
    fi

    local dir_name
    dir_name=$(grep -i '^name[[:space:]]*=' "${meta_file}" | head -1 | sed 's/^name[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/')

    if [ -z "${dir_name}" ]; then
        echo "Warning: Could not parse name from meta.cpp for mod ${mod_id}, falling back to ID." >&2
        echo "${mod_id}"
    else
        # Replace spaces with hyphens so mod names are safe in the -mod= parameter
        echo "${dir_name// /-}"
    fi
}

function logParsedModCount() {
    local mods=($(parseModsList))
    echo "Parsed ${#mods[@]} mods from MODLIST/MODSLIST."
}

function updateGame() {
    if [ "${STEAMACCOUNT}" = "anonymous" ]; then
        steamcmd \
            +force_install_dir ${HOME}/${GAME} \
            +login ${STEAMACCOUNT} \
            +app_update ${APPID} \
            +quit
    else
        steamcmd \
            +force_install_dir ${HOME}/${GAME} \
            +login ${STEAMACCOUNT} ${STEAMPASSWORD} \
            +app_update ${APPID} \
            +quit
    fi
}

function installMods() {
    # Read mod IDs from MODSLIST environment variable
    local mods=($(parseModsList))
    
    if [ ${#mods[@]} -eq 0 ]; then
        echo "No mods to install"
        return 0
    fi
    
    # Build steamcmd command dynamically
    local steamcmd_args="+force_install_dir ${HOME}/${GAME}"

    if [ "${STEAMACCOUNT}" = "anonymous" ]; then
        steamcmd_args="${steamcmd_args} +login ${STEAMACCOUNT}"
    else
        steamcmd_args="${steamcmd_args} +login ${STEAMACCOUNT} ${STEAMPASSWORD}"
    fi

    steamcmd_args="${steamcmd_args} +app_update ${APPID}"
    
    for mod_id in "${mods[@]}"; do
        steamcmd_args="${steamcmd_args} +workshop_download_item 221100 ${mod_id}"
    done
    
    steamcmd_args="${steamcmd_args} +quit"
    
    # Execute steamcmd with dynamic arguments
    steamcmd ${steamcmd_args}

    # Remove stale symlinks (numeric IDs and old @numeric-ID format) left from previous runs
    echo "Cleaning up stale mod symlinks..."
    for link in "${HOME}/${GAME}/"@* "${HOME}/${GAME}/"[0-9]*; do
        if [ -L "${link}" ]; then
            rm -f "${link}"
            echo "Removed stale symlink: ${link}"
        fi
    done

    # Create @DirName symlinks for the mods
    for mod_id in "${mods[@]}"; do
        local mod_src="${HOME}/${GAME}/steamapps/workshop/content/221100/${mod_id}"

        if [ -d "${mod_src}" ]; then
            local dir_name
            dir_name=$(getModDirName "${mod_id}")
            local mod_link="${HOME}/${GAME}/@${dir_name}"

            if [ ! -L "${mod_link}" ]; then
                ln -s "${mod_src}" "${mod_link}"
                echo "Created symlink @${dir_name} -> ${mod_src}"
            else
                echo "Symlink @${dir_name} already exists, skipping."
            fi
        else
            echo "Warning: Mod directory not found at ${mod_src}" >&2
        fi
    done
    
    # Copy mod keys
    if [ ! -d ${HOME}/${GAME}/keys ]; then
        mkdir -p ${HOME}/${GAME}/keys
    fi
    
    for mod_id in "${mods[@]}"; do
        local mod_keys_dir="${HOME}/${GAME}/steamapps/workshop/content/221100/${mod_id}"
        
        # Try both "keys" and "Keys" directory names
        if [ -d "${mod_keys_dir}/keys" ]; then
            cp -f "${mod_keys_dir}/keys/"* "${HOME}/${GAME}/keys/" 2>/dev/null || true
            echo "Copied keys from ${mod_id}/keys"
        fi
        
        if [ -d "${mod_keys_dir}/Keys" ]; then
            cp -f "${mod_keys_dir}/Keys/"* "${HOME}/${GAME}/keys/" 2>/dev/null || true
            echo "Copied keys from ${mod_id}/Keys"
        fi
    done
}


function setupBattleye() {
        if [ ! -f ${HOME}/battleye/beserver_x64.dll ] || [ ! -f ${HOME}/battleye/beserver_x64.so ];then
                if [ -f ${HOME}/${GAME}/battleye/beserver_x64.dll ] || [ -f ${HOME}/${GAME}/battleye/beserver_x64.so ];then
                        cd ${HOME}/battleye
                        ln -s ${HOME}/${GAME}/battleye/beserver_x64.dll
                        ln -s ${HOME}/${GAME}/battleye/beserver_x64.so
                fi
        fi
}

function startGame() {
        # Build mod parameter dynamically as a semicolon-separated list.
        local mods=($(parseModsList))
        local mod_param=""

        if [ "${DISABLE_MODS}" = "true" ]; then
            echo "DISABLE_MODS=true set; starting without mods."
            mods=()
        fi
        
        if [ ${#mods[@]} -gt 0 ]; then
            local mod_names=()
            for mod_id in "${mods[@]}"; do
                local dir_name
                dir_name=$(getModDirName "${mod_id}")
                mod_names+=("@${dir_name}")
            done
            mod_param=$(IFS=';'; echo "${mod_names[*]}")
        fi

        if [ -n "${mod_param}" ]; then
            echo "Launching DayZServer with -mod=${mod_param}"
        else
            echo "Launching DayZServer without mods"
        fi
        
        cd ${HOME}/${GAME}
        if [ -n "${mod_param}" ]; then
            ${HOME}/${GAME}/DayZServer \
                -config="${HOME}/serverDZ.cfg" \
                -port=${PORT} \
                "-mod=${mod_param}" \
                -adminlog \
                -netlog \
                -dologs \
                -freezeCheck \
                -cpuCount=${CPUCOUNT} \
                -profiles=${HOME}/profile \
                -BEpath=${HOME}/battleye
        else
            ${HOME}/${GAME}/DayZServer \
                -config="${HOME}/serverDZ.cfg" \
                -port=${PORT} \
                -adminlog \
                -netlog \
                -dologs \
                -freezeCheck \
                -cpuCount=${CPUCOUNT} \
                -profiles=${HOME}/profile \
                -BEpath=${HOME}/battleye
        fi
}

normalizeSteamCredentials
logParsedModCount
updateGame
installMods
setupBattleye
startGame
