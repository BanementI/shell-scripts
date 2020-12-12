#!/bin/bash
#Randomly picks a configuration.
CONFIG=$(shuf -n1 -e /etc/wireguard/*.conf)

printf "$CONFIG\n"

#Haha VPN go up
wg-quick up $CONFIG

#Stores the randomly chosen config as a file for use in any other script later on.
echo $CONFIG > ~/currentvpn

