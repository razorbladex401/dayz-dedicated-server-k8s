#!/bin/bash


function updateGame() {
    steamcmd \
        +login anonymous \
        +force_install_dir /home/steam/dayz \
        +app_update 1042420 \
        +quit 2>&1 /home/steam/steam.log
}

function setupBattleye() {
	if [ ! -f /home/steam/battleye/beserver_x64.dll ] || [ ! -f /home/steam/battleye/beserver_x64.so ];then
		if [ -f /home/steam/dayz/battleye/beserver_x64.dll ] || [ -f /home/steam/dayz/battleye/beserver_x64.so ];then
			cd /home/steam/battleye
			ln -s /home/steam/dayz/battleye/beserver_x64.dll
			ln -s /home/steam/dayz/battleye/beserver_x64.so
		fi
	fi
}

function startGame() {
	cd /home/steam/dayz
	/home/steam/dayz/DayZServer -config="/home/steam/serverDZ.cfg" -adminlog -netlog --dologs --freezeCheck -profiles=/home/steam/profile -BEpath=/home/steam/battleye
}

updateGame
setupBattleye
startGame
