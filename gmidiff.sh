#!/bin/bash

OPENSSL_TIMEOUT=30

function help() {
	echo -e "\nUsage:\n"
	echo -e "\t$(basename "$0") add url - add a new Geminispace address, e.g.:\n"
	echo -e "\t$(basename "$0") add geminispace.info/backlinks?szczezuja.space\n"
	echo -e "\t$(basename "$0") configure - set configuration information\n"
	echo -e "\t$(basename "$0") help - print this help\n"
	echo -e "\t$(basename "$0") reset - remove all previously added adresses\n"
	echo -e "\t$(basename "$0") update - update previously added adresses\n"
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

# Mail $1 subject, $2 content to $USER@localhost
function send_mail() {
	mail="Subject: ${1} \n\n${2}\n"
	mail_address=$(get_config_email)

	# Check if mail address is not empty, for example script running from crontab
	if [[ $mail_address =~ ^.+@.+$ ]]; then 
		echo -e "$mail" | /usr/sbin/sendmail -i -- "$mail_address"	# Full path to sendmail for crontab
	else
		echo "Content is printed because script isn't configured."
		echo -e "$2" 
	fi
}

# Add a new site 
# Function inspired on https://gitlab.com/uoou/dotfiles/-/blob/master/stow/bin/home/drew/.local/bin/lace
function add() {

	echo "Get: ${1}"
	
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
	content=$(timeout $OPENSSL_TIMEOUT openssl s_client -crlf -quiet -connect "$domain:1965" <<< "gemini://$address/" 2>/dev/null)
	
	if [ -z "$content" ]; then
		echo " -> Timeout or empty response."
	else
		content=$(echo "$content" | grep -E "(#)|(##)|(###)|(=>)")
		hash=$(echo -n "$content" | sha256sum)

		# Read a previous hash and content from file
		last_hash=$(sed '1!d' "$file")		# first line only
		last_content=$(sed '1,2d' "$file")	# third+ lines only

		if test "$last_hash" = "$hash"; then
			echo " -> Nothing is changed."
		else
			echo " -> New hash of content is $hash and it's saved to $file."
			mail_content=$(diff <(echo "$last_content") <(echo "$content"))
			send_mail "New content at ${address}" "$mail_content"
			# Print a new hash and content to file
			echo "$hash" > $file		
			echo "$address" >> $file
			echo "$content" >> $file
		fi
	fi 
}

# Update previously added sites
function update() {

	echo "Updating:"

	# Get config directory
	configdir=$(get_dir)

	contentfiles="${configdir}/.*.gmidiff"

	# Iteration by sites previously processed by command add
	for f in $contentfiles
	do
		if [[ ! -e "$f" ]]; then continue; fi 
		address=$(sed '2!d' "$f")
		domain=$(get_domain_name "$address")
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
		echo "Are you sure to remove ${n} saved sites? [yes/NO]"
		read response
	else
		response="NO"
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

# Get email address which is set by configure command or $USER@localhost
function get_config_email() {

	# Get config directory
	configdir=$(get_dir)
	configfile="${configdir}/.email.gmidiff_config"

	if [[ -e "$configfile" ]]; then 
		cat "$configfile"
	else
		# No e-mail, when user didn't configure script
		echo ""
	fi 
}

# Set configuration information used by other commands
function configure() {

	# Get config directory
	configdir=$(get_dir)

	for (( ; ; ))
	do
		echo "What is your e-mail address?"
		read config_email
		echo "Is \"${config_email}\" is correct [yes/NO]?"
		read config_email_correct
		if [[ "$config_email_correct" == "yes" ]];then
			break
		fi
	done

	echo "$config_email" > "${configdir}/.email.gmidiff_config"
}	

if [[ "$1" == "add" ]];then
	add "$2" 
elif [[ "$1" == "update" ]];then
	update
elif [[ "$1" == "reset" ]];then
	reset
elif [[ "$1" == "configure" ]];then
	configure
else
	help
fi
