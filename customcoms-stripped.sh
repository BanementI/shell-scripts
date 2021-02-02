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
}
