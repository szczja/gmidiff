#!/bin/bash

function help() {
	echo -e "\nUsage:\n"
	echo -e "\t$(basename "$0") get domain url - get content of Geminispace address, e.g.:\n"
	echo -e "\t$(basename "$0") get geminispace.info geminispace.info/backlinks?szczezuja.flounder.online\n"
	echo -e "\t$(basename "$0") help - print this help\n"
	exit
}

# Init and print config directory
function get_dir() {
	if [ -z "$XDG_CONFIG_HOME" ];then
		configdir="$HOME/.config/gmidiff"
	else
		configdir="$XDG_CONFIG_HOME/gmidiff"
	fi
	[[ ! -d "$configdir" ]] && mkdir -p $configdir
	echo $configdir
}

# Function inspired on https://gitlab.com/uoou/dotfiles/-/blob/master/stow/bin/home/drew/.local/bin/lace
function get() {
	
	# Get config directory
	configdir=$(get_dir)

	# Prepare valid filename and file for content
	file=$(echo "."$2 | sed -e 's/[^A-Za-z0-9._-]/_/g')
	file="${configdir}/${file}.gmidiff"
	if [ ! -f $file ] 
	then
		touch "$file"
	fi

	# Get and process a new content
	content=$(timeout 5 openssl s_client -crlf -quiet -connect "$1:1965" <<< "gemini://$2/" 2>/dev/null)
	content=$(echo "$content" | grep -E "(#)|(=>)")
	hash=$(echo -n "$content" | sha256sum)

	# Read a previous hash and content from file
	last_hash=$(sed '1!d' "$file")
	last_content=$(sed '1d' "$file")
	
	if test "$last_hash" = "$hash"; then
		echo "Nothing is changed."
	else
		echo "New hash of content is $hash"
		# Print a new hash and content to file
		echo "$hash" > $file		
		echo "$content" >> $file
	fi
	exit
}

if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-help" ]] || [[ "$1" == "-h" ]];then
	help
elif [[ "$1" == "get" ]];then
	get "$2" "$3"
else
	help
fi
