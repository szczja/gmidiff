#!/bin/bash

function help() {
	echo -e "\nUsage:\n"
	echo -e "\t$(basename "$0") add url - add a new Geminispace address, e.g.:\n"
	echo -e "\t$(basename "$0") add geminispace.info/backlinks?szczezuja.flounder.online\n"
	echo -e "\t$(basename "$0") update - update previously added adresses\n"
	echo -e "\t$(basename "$0") reset - remove all previously added adresses\n"
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

# Get domain name from full address
function get_domain_name() {
	echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||'
}

# Add a new site 
# Function inspired on https://gitlab.com/uoou/dotfiles/-/blob/master/stow/bin/home/drew/.local/bin/lace
function add() {
	
	# Get config directory
	configdir=$(get_dir)

	address=$1
	domain=$(get_domain_name "$address")

	# Prepare valid filename and file for content
	file=$(echo "."$address | sed -e 's/[^A-Za-z0-9._-]/_/g')
	file="${configdir}/${file}.gmidiff"
	if [ ! -f $file ] 
	then
		touch "$file"
	fi

	# Get and process a new content
	content=$(timeout 5 openssl s_client -crlf -quiet -connect "$domain:1965" <<< "gemini://$address/" 2>/dev/null)
	content=$(echo "$content" | grep -E "(#)|(=>)")
	hash=$(echo -n "$content" | sha256sum)

	# Read a previous hash and content from file
	last_hash=$(sed '1!d' "$file")

	if test "$last_hash" = "$hash"; then
		echo "Nothing is changed."
	else
		echo "New hash of content is $hash"
		# Print a new hash and content to file
		echo "$hash" > $file		
		echo "$address" >> $file
		echo "$content" >> $file
	fi
}

# Update previously added sites
function update() {

	# Get config directory
	configdir=$(get_dir)

	contentfiles="${configdir}/.*.gmidiff"

	# Iteration by sites previously processed by command add
	for f in $contentfiles
	do
		if [[ ! -e "$f" ]]; then continue; fi 
		address=$(sed '2!d' "$f")
		domain=$(get_domain_name "$address")
		
		echo "Updating ${address}"
		add "$address"
	done

}

# Removing previously added sites
function reset() {

	# Get config directory
	configdir=$(get_dir)

	contentfiles="${configdir}/.*.gmidiff"
	n=0

	# Iteration by sites previously processed by command add
	for f in $contentfiles
	do
		if [[ ! -e "$f" ]]; then continue; fi 
		n=$((n+1))
		echo "${n} - ${f}"
	done
	if ((n > 0)); then
		echo "Are you sure to remove ${n} saved sites? [yes/no]"
		read response
	else
		response="no"
	fi 
	if [[ "$response" == "yes" ]];then
		for f in $contentfiles
		do
			if [[ ! -e "$f" ]]; then continue; fi 
			rm -v "$f"
		done
	else
		echo "Nothing is removed."
	fi

}

if [[ "$1" == "add" ]];then
	add "$2" 
elif [[ "$1" == "update" ]];then
	update
elif [[ "$1" == "reset" ]];then
	reset
else
	help
fi
