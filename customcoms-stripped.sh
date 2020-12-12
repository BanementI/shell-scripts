#!/bin/bash
# Count the amount of file types.
function files() {
   find . -type f | sed -e 's/.*\.//' | sed -e 's/.*\///' | sort | uniq -c | sort -rn
}

# Get HTTP status. Could type it manually but mate I'm lazy and this is another option.
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

#Get status code of any website, and ONLY the status code.
function webstatus() {
   STATUS=$(http -hdo ./body $1 2>&1 | grep HTTP/ ); echo $STATUS
}

