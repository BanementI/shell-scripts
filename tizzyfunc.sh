##################################################################
# TIZZYFUNC
#
# Many functions and aliases used on my NAS, PC and laptop.
#
# R.I.P Tizzy 2008-2024 <3
#
##################################################################

# Converts a digitized MiniDV video to MP4. 
dvconv() {
    if [ -z "$1" ]; then
        echo "Usage: dvconv input.avi"
        return 1
    fi
    input_file="$1"
    output_file="${input_file%.*}.mp4"
    ffmpeg -i "$input_file" -vf "yadif" -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k "$output_file"
}

# Improved by AI, improved and fixed further by interloper.
# Downloads an entire website as a WARC. Not reccomended for huge websites. Reccomended for small blog sites.
quick-warc() {
        if [ -z "$1" ]; then
                echo "usage: quick-warc <url>"
                return 1
        fi

        user_agent="Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27"
        warc_base="$(printf '%s' "$1" | sed 's/\W/_/g')"
        warc_file="${warc_base}.warc.gz"
        dest_dir=/sym/Root/Software/WARCs
        mkdir -p "$dest_dir"

        if [ -f "${dest_dir}/${warc_base}" ]; then
                echo "$warc_file already exists in $dest_dir"
                return 1
        else
                wget --warc-file="$warc_base" \
                        --warc-cdx \
                        --mirror \
                        --page-requisites \
                        --no-check-certificate \
                        --restrict-file-names=windows \
                        -e robots=off \
                        --waitretry 5 \
                        --timeout 60 \
                        --tries 5 \
                        --wait 1 \
                        -U "$user_agent" \
                        "$1"

                # Move the generated WARC and CDX files to the designated folder
                if [ -f "$warc_file" ]; then
                        mv "$warc_file" "$dest_dir/"
                        mv "${warc_base}.cdx" "$dest_dir/"
                        test -d "$1" && rm -rf "$1"
                else
                        echo "Couldn't move ${warc_file}. Does it exist?"
                fi
                return 0
        fi
}

# watchstatus: Goes through my gallery-dl watchlist to ensure the URLs are valid. Skips Twitter, because fuck their shitty "API".
# In fact, Twitter will just reply with 200 OK even if the profile does not exist. WHY?!
watchstatus() {
    # Define the filename containing the URLs
    filename="$1"

    # Check if the file exists
    if [[ ! -f "$filename" ]]; then
        echo "File not found: $filename"
        exit 1
    fi

    # Delay between each URL check (in seconds)
    delay=2

    # Loop through each line in the file
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if the line contains "twitter.com" or "x.com"
        if [[ "$line" == *twitter.com* || "$line" == *x.com* ]]; then
            # echo "Skipping URL: $line"
            continue
        fi

        # Extract URL from the line
        url=$(echo "$line" | awk '{print $1}')

        # Ensure the URL is not empty
        if [[ -n "$url" ]]; then
            # echo "Checking $url..."

            # Perform the HTTP request and capture the status response code
            status=$(curl -s -o /dev/null -w "%{http_code}" "$url" -L)

            # Check if the status response code was retrieved
            if [[ -n "$status" ]]; then
                echo "$url: $status"
            else
                echo "Failed to retrieve status for $url."
            fi
        else
            echo "Encountered an empty line, skipping..."
        fi

        # Add a delay before checking the next URL
        sleep "$delay"
    done < "$filename"

    # Indicate completion
    echo "Finished processing URLs."
}

# Get the HTTP code of a URL. Needs HTTPie.
webstatus() {
   STATUS=$(http -hdo ./body $1 2>&1 | grep HTTP/ ); echo $STATUS
}

# Get cheat.sh manpage TLDRs.
cheat() {
  curl cheat.sh/$1
}

# Selects random VPN config
vpn-on() {
   CONFIG=$(sudo sh -c 'shuf -n1 -e /etc/wireguard/*.conf')
   wg-quick up $CONFIG
   echo $CONFIG > $HOME/.currentvpn
}

vpn-off() {
    #Accesses the file made by vpn-on.sh to get the current config.
    CONFIG=$(cat $HOME/.currentvpn)

    #Haha VPN go down
    wg-quick down $CONFIG
}

# Mounts my NAS on WSL.
alias mountnas="sudo mount -t drvfs W: /mnt/w -o metadata"
