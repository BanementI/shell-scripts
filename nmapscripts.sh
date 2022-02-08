#!/bin/bash
RED='\033[0;31m'
LRED='\033[1;31m'
GREEN='\033[0;32m'
LGREEN='\033[1;32m'
ORANGE='\033[0;33m'
PISS='\033[1;33m'
BLU='\033[0;34m'
LBLU='\033[1;34m'
CYAN='\033[0;36m'
LCYAN='033[1;36m'
PURP='\033[0;35m'
PINK='\033[1;35m'
GRAY='\033[1;30m'
LGRAY='033[0;37m'
NC='\033[0m'

function nmapscripts() {
	printf "${LGRAY}default - Scripts that are ran when using -sC or -A.\n"
	printf "${LGREEN}safe - Scripts that aren't designed to crash services, use large amounts of bandwidth or exploits. A bit more sysadmin friendly. Almost.\n"
	printf "${LRED}auth - Authentication credentials (and bypassing them). No bruteforce.\n"
	printf "${ORANGE}broadcast - Scripts that broadcast on the local network.\n"
	printf "${RED}brute - Automate bruteforce attacks to guess the auth creds of a target.\n"
	printf "${ORANGE}discovery - Tries to actively discover more about the network by querying third parties.\n"
	printf "${RED}dos - Scripts that may cause a denial of service. May also crash the target system.\n"
	printf "${RED}exploit - Actively exploit some vulnerability\n."
	printf "${ORANGE}external - May send data to third-party databases.\n"
	printf "${RED}fuzzer - Scripts which are designed to send unexpected or randomized fields in each packet. It's slow, bandwidth intensive and may cause a DoS or crash the target.\n"
	printf "${RED}intrusive - High chance of harming the target system.\n"
	printf "${LRED}malware - Checks whether the target is infected with malware or backdoors.\n"
	printf "${RED}vuln - Check for specific known vulnerabilities.\n"
}
