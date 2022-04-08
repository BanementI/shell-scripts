#!/bin/bash
# Count the amount of file types.
function files() {
   find . -type f | sed -e 's/.*\.//' | sed -e 's/.*\///' | sort | uniq -c | sort -rn
}

# Shittier version of webstatus that remains for some reason.
function httpstatus() {
   http httpbin.org/status/$1
}

#Simple IP lookup.
function ipinfo() {
   curl "ipinfo.io/$1?token={YOUR KEY HERE}"
}

#Detailed IP lookup with extended threat detection.
function ipdata() {
   curl "https://api.ipdata.co/?api-key={YOUR KEY HERE}"
}

#Fully removes a package, thanks to u/nickelodeandiesel on r/archlinux.
function yeet() {
   yay -Rsnd $1
}

#Get status code of any website.
function webstatus() {
   STATUS=$(http -hdo ./body $1 2>&1 | grep HTTP/ ); echo $STATUS
}

#List some commands I keep forgetting about.
function commands() {
   if [ -z "$1" ]
   then
      printf "Choose a catagory:\n"
      printf "${CYAN}OSINT${NC}\n"
      printf "${PISS}(search)ing${NC}\n"
      printf "${GAY}OpenDirectory(opend)${NC}\n"
      printf "${TERRY}nmap${NC}\n"
		printf "${LBLU}dorking${NC}\n"
      printf "bspwm"
      printf "brightnesctl set 10000"
      printf "usbdeath\n"
      printf "custom\n"
    fi

   if [ "$1" = "osint" ]
   then
      printf "h8mail - Email info and password lookup tool.\n"
      printf "phoneinfoga - Phone info lookup tool.\n"
      printf "infoga - Email info lookup tool.\n"
      printf "raccoon - Offensive tool for reconnaissance and vulnerability scanning.\n"
      printf "nmap - You know what this does.\n"
      printf "nikto - Powerful webserver vulnerablity tool. Takes hours.\n"
      printf "ghunt - Tool to extract info from gmail accounts.\n"
   fi

   if [ "$1" = "yay" ]
   then
      printf "Searching for packages:\n"
      printf "pacman -Ql - List where a program is.\n"
      printf "yay -Ss - Search packages.\n"
      printf "pacman -Qi - Check package info.\n"
      printf "yay -Pw - Check Arch news.\n"
      printf "yay -Ps - Package manager information.\n"
      printf "yay -Sc - Clean cached AUR packages.\n"
      printf "yay -Pc - Complete list of all AUR packages, you shouldn't use this.\n"
      printf "pacman -R $(pacman -Qsq .query.) - Remove all packages containing a word.\n"
      printf ""
      printf "\n" 
      printf "Searching for files:\n"
      printf "fzf - Fuzzy finder.\n"
   fi

   if [ "$1" = "opend" ]
   then
      printf "later\n"
   fi

   if [ "$1" = "nmap" ]
   then
      printf "nmap -sn 192.168.1.0/24 - Scan for local devices, no port scanning.\n"
      printf "--script /usr/lib/python3.8/site-packages/raccoon_src/utils/misc/vulners.nse - Vulners script.\n"
      printf 'nmap -T2 -sn -Pn -v -oN "~/Desktop/nmap results/[FILE]" [inet].0.0/16" - Scan all devices on subnet\n'
      printf "nmap -v -F -sC -sV -O {target} - The full sauce.\n"
   fi

	if [ "$1" = "dorking" ]
	then
		printf 'Scanner results: intitle:"report" ("qualys" | "acunetix" | "nessus" | "netsparker" | "nmap") filetype:pdf\n'
		printf 'Logs: allintext:username filetype:log\n'
		printf 'FTP: intitle:"index of" inurl:ftp\n'
		printf 'Webcams: intitle:"webcamxp 5"\n'
		printf 'DB passwords: db_password filetype:env\n'
		printf 'Github thingies: filetype:inc php -site:github.com -site:sourceforge.net\n'
		printf 'Expose PHP variables: filetype:php "Notice: Undefined variable: data in" -forum\n'
		printf 'WAMPServers: intitle:"WAMPSERVER homepage" "Server Configuration" "Apache Version"\n'
      printf 'intitle:"SecureWEB"'
   fi

	if [ "$1" = "programs" ]
	then
		printf 'hexyl - Hex viewer, it has colours too!\n'
		printf 'yy-chr - Sprite editor, needs Wine to run it.\n'
	fi 

   if [ "$1" = "bspwm" ]
   then
      printf "You'll be here a lot :)\n"
      printf "Move windows to another workspace: Super Shift Num\n"
      printf "Launchbar: Super Space\n"
      printf "Enlargen width: Super Alt HJKL\n"
      printf "Smaller width: Super Alt SHift JHKL"
      printf "Close highlihted window: Super W\n"
      printf "Change window position: Super Shift HJKL\n"
      printf "Determine where the next window will go: Ctrl SUper HJKL\n"
      printf "Toggle window flags:\n"
      printf "Super T - Tiled\n"
      printf "Super Shift T - Psuedo Tiled\n"
      printf "Super S - Floating\n"
      printf "Super F - Fullscreen\n"
      printf "Moving floating windows: Super Arrows\n"
   fi
   
   if [ "$1" = "usbdeath" ]
   then
      printf "usbdeath show - Check connected USB devices\n"
      printf "usbdeath on - Generate whitelist of connected devices\n"
      printf "usbdeath eject - Add event on ejection of specific device\n"
      printf "usbdeath off - Turn off usbdeath (to insert a new trusted device)\n"
      printf "usbdeath gen - Permanently add new trusted device\n"
      printf "usbdeath edit - Edit udev rules manually\n"
      printf "usbdeath del - Delete the udev rules files and start over\n"
   fi

  if [ "$1" = "custom" ]
  then
     printf "files - List unique files in a directory.\n"
     printf "ipinfo - Simple IP lookup + token.\n"
     printf "ipdata - Advanced IP lookup + token.\n"
     printf "yeet - Fully removes a package (Arch).\n"
     printf "nmaplocal - Local nmap scan with some options.\n"
     printf "webstatus - Get the status code of any website (httpie).\n"
     printf "untar/maketar - Untar, make a tar.\n"
     printf "best - Best yt-dlp format. Out of date.\n"
     printf "weblookup - Get the IP info from a domain.\n"
     printf "nmapscripts - List the nmap script categories.\n"
     printf "0x0 - Uploads a file to 0x0. Bash only.\n"
     printf "spoofmac - Spoofs MAC address. Depends on wlo1 and needs macchanger.\n"
     printf "rudeScan - the loudar u are the less u here. (Extremely aggressive nmap scan)\n"
   fi
}

#nmap script categories.
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

#Restart + status.
function restat() {
   systemctl restart $1
   systemctl status $1
}

function xxr() {
   find . -type f -exec xxhsum {} + | tee xxhsum
}
