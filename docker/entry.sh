#!/bin/bash

function updateGame() {
    steamcmd \
        +login ${STEAMACCOUNT} ${STEAMPASSWORD} \
        +force_install_dir ${HOME}/${GAME} \
        +app_update ${APPID} \
        +quit
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
	cd ${HOME}/${GAME}
	${HOME}/${GAME}/DayZServer -config="${HOME}/serverDZ.cfg" -adminlog -netlog --dologs --freezeCheck -cpuCount=${CPUCOUNT} -port=${PORT} -profiles=${HOME}/profile -BEpath=${HOME}/battleye
}

updateGame
setupBattleye
startGame
