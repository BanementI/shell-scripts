#!/bin/bash

function 0x0() {

PS3='Select null pointer instance: '
options=("0x0.st - 512MiB" "envs.sh - 512MiB" "ttm.sh - 256MiB" "Quit")
file=($1)
select opt in "${options[@]}"
do
    case $opt in
        "0x0.st - 512MiB")
            url=(https://0x0.st)
            break
            ;;
        "envs.sh - 512MiB")
            url=(https://envs.sh)
            break
            ;;
        "ttm.sh - 256MiB")
            url=(https://ttm.sh)
	    break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

curl -F"file=@$file" $url
#echo $file $url

}
