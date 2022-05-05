#!/bin/bash


function updateGame() {
    steamcmd \
        +login anonymous \
        +force_install_dir /home/steam/dayz \
        +app_update 1042420 \
        +quit 2>&1 /home/steam/steam.log
}

function startGame() {
	cd /home/steam/dayz
	/home/steam/dayz/DayZServer -config="/home/steam/serverDZ.cfg" -adminlog -netlog --dologs --freezeCheck -profiles=/home/steam/profile
}

updateGame
startGame
