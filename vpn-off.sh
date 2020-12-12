#!/bin/bash

#Accesses the file made by vpn-on.sh to get the current config.
CONFIG=$(cat ~/currentvpn)

#Haha VPN go down
wg-quick down $CONFIG
