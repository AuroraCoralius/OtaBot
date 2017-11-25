#!/bin/bash

git pull
while true; do
	luvit bot.lua
	if [ $? != "0" ]; then
		echo -e "\e[41;30m ERROR \e[0m Bot didn't exit cleanly, code: \e[30;46m$?\e[0m"
	fi
	echo
	echo -e "\e[46;30m RESTART \e[0m"
	echo
	touch exit_code
	echo -n $? > exit_code
done

