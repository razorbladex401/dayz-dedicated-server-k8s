#!/bin/bash

function parseModsList() {
    # Parse MODSLIST environment variable (space or semicolon-separated)
    # Output: array of mod IDs
    local modslist="${MODLIST}"
    
    if [ -z "${MODLIST}" ]; then
        echo "Warning: MODSLIST environment variable is not set. No mods will be installed." >&2
        return 1
    fi
    
    # Replace semicolons with spaces for consistent parsing
    modslist="${modslist//;/ }"
    
    # Output as newline-separated for easy iteration
    echo "${MODLIST}"
}

function updateGame() {
    steamcmd \
        +force_install_dir ${HOME}/${GAME} \
        +login ${STEAMACCOUNT} "${STEAMPASSWORD}" \
        +app_update ${APPID} \
        +quit
}

function installMods() {
    # Read mod IDs from MODSLIST environment variable
    local mods=($(parseModsList))
    
    if [ ${#mods[@]} -eq 0 ]; then
        echo "No mods to install"
        return 0
    fi
    
    # Build steamcmd command dynamically
    local steamcmd_args="+force_install_dir ${HOME}/${GAME} +login ${STEAMACCOUNT} ${STEAMPASSWORD} +app_update ${APPID}"
    
    for mod_id in "${mods[@]}"; do
        steamcmd_args="${steamcmd_args} +workshop_download_item 221100 ${mod_id}"
    done
    
    steamcmd_args="${steamcmd_args} +quit"
    
    # Execute steamcmd with dynamic arguments
    steamcmd ${steamcmd_args}
    
    # Create symlinks for the mods
    for mod_id in "${mods[@]}"; do
        local mod_src="${HOME}/${GAME}/steamapps/workshop/content/221100/${mod_id}"
        local mod_link="${HOME}/${GAME}/${mod_id}"
        
        if [ -d "${mod_src}" ]; then
            if [ ! -L "${mod_link}" ]; then
                ln -s "${mod_src}" "${mod_link}"
                echo "Created symlink for mod ${mod_id}"
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
        # Build mod parameter dynamically from MODSLIST
        local mods=($(parseModsList))
        local mod_param=""
        
        if [ ${#mods[@]} -gt 0 ]; then
            mod_param=$(IFS=';' echo "${mods[*]}")
            mod_param="-mod=${mod_param}"
        fi
        
        cd ${HOME}/${GAME}
        ${HOME}/${GAME}/DayZServer \
            -config="${HOME}/serverDZ.cfg" \
            -adminlog \
            -netlog \
            --dologs \
            --freezeCheck \
            -cpuCount=${CPUCOUNT} \
            -port=${PORT} \
            ${mod_param} \
            -profiles=${HOME}/profile \
            -BEpath=${HOME}/battleye
}

updateGame
installMods
setupBattleye
startGame
