#!/bin/bash

git pull
while true; do
	if [ ! -f "restart" ]; then
		echo
		echo -e "\e[42;30m START \e[0m"
		echo
	else
		rm restart
	fi
	luvit bot.lua
	exitcode=$?
	if [ -f "restart" ]; then
		echo
		echo -e "\e[46;30m RESTART \e[0m"
		echo
	else
		echo
		echo -e "\e[43;30m STOP \e[0m"
		echo
	fi
	if [ $exitcode != "0" ]; then
		echo -e "\e[41;30m ERROR \e[0m Bot didn't exit cleanly, code: \e[30;46m $exitcode \e[0m"
	fi
	echo -n $exitcode > exit_code
done

