#WiFi goes down!
ip link set dev wlo1 down
sleep 5

#Change MAC address.
macchanger -r wlo1
sleep 5

#WiFi goes up!
ip link set dev wlo1 up
sleep 5
