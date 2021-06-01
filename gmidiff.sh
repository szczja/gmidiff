#!/bin/bash

function help() {
	echo -e "\nUsage:\n"
	echo -e "\t$(basename "$0") get domain url - get content of Geminispace address, e.g.:\n"
	echo -e "\t$(basename "$0") get geminispace.info geminispace.info/backlinks?szczezuja.flounder.online\n"
	echo -e "\t$(basename "$0") help - print this help\n"
	exit
}

# Function inspired on https://gitlab.com/uoou/dotfiles/-/blob/master/stow/bin/home/drew/.local/bin/lace
function get() {
	content=$(timeout 5 openssl s_client -crlf -quiet -connect "$1:1965" <<< "gemini://$2/" 2>/dev/null)
	content=$(echo "$content" | grep "#")
	hash=$(echo -n "$content" | sha256sum)
	echo "$content"
	echo "$hash" 		
	exit
}

if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-help" ]] || [[ "$1" == "-h" ]];then
	help
elif [[ "$1" == "get" ]];then
	get "$2" "$3"
else
	help
fi
