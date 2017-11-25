#!/bin/bash

git pull
while true; do
	echo
	echo -e "\e[42;30m START \e[0m"
	echo
	luvit bot.lua
	if [ -f "restart" ]; then
		echo
		echo -e "\e[46;30m RESTART \e[0m"
		echo
		rm restart
	else
		echo
		echo -e "\e[43;30m STOP \e[0m"
		echo
	fi
	if [ $? != "0" ]; then
		echo -e "\e[41;30m ERROR \e[0m Bot didn't exit cleanly, code: \e[30;46m$?\e[0m"
	fi
	touch exit_code
	echo -n $? > exit_code
done

