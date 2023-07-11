function hmap() {
   if [ -z "$1" ]
   then
     printf "a : all\n"
     printf "aa : all, aggressive"\n
     printf "s : stealth\n"
   fi

	if [ "$1" = "a" ]
	then
		nmap -A -v $2
	fi

 	if [ "$1" = "aa" ]
	then
		nmap -A -v -T4 $2
	fi
 
	if [ "$1" = "s" ]
	then
		nmap -v -sS $2
	fi
 
}
