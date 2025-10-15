#!/bin/sh
##################################################################
# ARCFUNC - PUBLIC - NOT POSIX COMPLIANT
#
# Scripts to help maintain my archives. Some were mostly AI-assisted, they have been noted.
#
# REQUIREMENTS: yt-dlp, gallery-dl, ripgrep
# 
##################################################################

ERROR='\033[0;31mERROR:\033[0m'
WARN='\033[1;33mWARN:\033[0m'
NOTE='\033[0;36mNOTE:\033[0m'

arcfunc() {
    printf "arcfunc by banement\n"
    printf "arc | etc | help\n"

    if [ "$1" = "arc" ]; then
        printf "$WARN checkdel - Compares live Twitter metadata to the images we have downloaded, and sorts deleted images.\n"
        printf "cdxback <website> - Makes a CDX from inputted site.\n"
        printf "cdxmake <website> - Generates a list of URLs from a CDX. Use after cdxback.\n" 
        printf "$WARN da-search <username> - Searches a LOCAL CDX DB and grabs its IA URLs.\n"
        printf "dvconv <file> - Converts a minidv file to MP4.\n"
        printf "idgen - Generates a list of video IDs as output.txt.\n"
        printf "pixivcheck - Checks if pixiv images are still online or not.\n"
        printf "pixivnum - Displays the detected amount of pixiv images.\n"
        printf "quick-warc - WARC a website."
        printf "twtarc-neo - The improved and fixed version of twtarc. Attempts to recover images from deleted twitter accounts via IA API.\n"
        # printf "twthelp - Shows the other twtarc commands.\n" outdated
        printf "unlistedhunter - Goes through the current folder of downloaded YouTube videos, and verifies their status online. May require cookies.\n"
        printf "$NOTE wixmp-search <uuid> - Searches IA API for URLs.\n"
        printf "zipback - Get all archives (and other files) from a specified wayback website.\n"
    elif [ "$1" = "etc" ]; then
        printf "apk-size - On Alpine, gives a list of all the packages and their sizes.\n"
    elif [ "$1" = "help" ]; then
        printf "yellow = NAS-specific setup | blue = read the README\n"
    fi
}

# Scans the current folder for pixiv images and checks if they are still online.
pixivcheck() {
    pixCount=$(find . -maxdepth 1 -type f -print | sed -n 's#./\([0-9]\+\)_p.*#\1#p' | wc -l)
    echo "There are $pixCount matching files."
    pixBase="https://www.pixiv.net/en/artworks/"
    find . -maxdepth 1 -type f -print | while read -r file; do
        pixID=$(echo "$file" | sed -n 's#./\([0-9]\+\)_p.*#\1#p')
        
        if [ -n "$pixID" ]; then  
            #echo "Checking PixID: $pixID"

            # Debugging: Print the full URL being checked
            pixURL="$pixBase$pixID"
            #echo "URL: $pixURL"

            # Use curl to follow redirects, capture final status code
            pixStat=$(curl -s -L -o /dev/null -w "%{http_code}" "$pixURL")
            
            # Debugging: Show the final response status
            #echo "Response Code for $url: $pixStat"

            if [ "$pixStat" = "404" ]; then
                echo "$pixID is lost media!"
            elif [ "$pixStat" = "200" ]; then
                :
            else
                echo "Unknown!"
                echo "Status Code: $pixStat"
            fi

            sleep 2
        fi
    done
}

pixivnum() {
    find . -maxdepth 1 -type f -print | sed -n 's#./\([0-9]\+\)_p.*#\1#p'
}

idgen() {
  (find . -regex '.*\.\(mkv\|mp4\|webm\)' | sed -En '/.*-[A-Za-z0-9_-]{11}\.[^.]+$/ s/.*-([A-Za-z0-9_-]{11})\.[^.]+$/\1/p'; \
  find . -regex '.*\.\(mkv\|mp4\|webm\)' | grep '\[[^]]\{11\}\]' | sed -E 's/.*\[([^]]{11})\].*/\1/' | uniq) >> output.txt
}

# Checks your
unlistedhunter() {
    # Video list file
    videoList="localIDs.txt"
    cCount=0
    aCount=0
    pCount=0
    tCount=0
    pubCount=0
    unCount=0
    dCount=0

    stats() {
        printf "%s\nunlistedhunter stats"
        echo "C A P T . U D"
        echo "$cCount $aCount $pCount $tCount $pubCount $unCount $dCount"
    }

   if [ "$1" = "old" ]; then
        # Extract video IDs from filenames in the old format
        find . -maxdepth 1 -regex '.*\.\(mkv\|mp4\|webm\)' | sed -E 's/.*-([A-Za-z0-9_-]{11})\.[^.]+$/\1/' > "$videoList"
   else
        # Extract video IDs from filenames with square brackets
        find . -maxdepth 1 -regex '.*\.\(mkv\|mp4\|webm\)' | sed -E 's/.*\[([^]]{11})\].*/\1/' > "$videoList"
   fi

    # Base URL for YouTube videos
    baseUrl="https://www.youtube.com/watch?v="
    echo "unlistedhunter: C = Copyright, A = 18+, P = Private, T = Terminated, . = Public, D = Deleted" 

    # Loop through each line in the video list
    while read -r videoId; do
        # Skip empty lines
        if [ -z "$videoId" ]; then
            echo "Skipping empty line."
            continue
        fi

        # Construct the full video URL
        videoUrl="${baseUrl}${videoId}"

        # Run yt-dlp to simulate fetching video info (without actually downloading it)
        output=$(yt-dlp --simulate --print-json --cookies ~/ai/cookies.txt "$videoUrl" 2>&1) # Add  <loc> to see adult video statuses

        # Check for specific strings in the output
        if echo "$output" | grep -q "copyright claim"; then # Copyright claimed
            printf "C"
            cCount=$((cCount + 1))
        elif echo "$output" | grep -q "inappropriate"; then # 18+
            printf "A"
            aCount=$((aCount + 1))
        elif echo "$output" | grep -q "private"; then # Private video
            printf "P"
            pCount=$((pCount + 1))
        elif echo "$output" | grep -q "terminated"; then # Terminated YT account
            printf "T"
            tCount=$((tCount + 1))
        elif echo "$output" | grep -q "Video unavailable"; then
            printf "D"
            dCount=$((dCount + 1))
        else 
            if echo "$output" | grep -q "unlisted"; then # What we want
				printf "\nUNLISTED: %s\n" "$videoUrl"
				echo "$output" | jq '.title'
                unCount=$((unCount + 1))
            else # Public videos
                printf "."
                pubCount=$((pubCount + 1))
            fi
        fi
    done < "$videoList"

    stats

}

twtcdx() {

    if [ -z "$1" ]; then
        echo "Gets the cdx file for a Twitter user."
        echo "Usage: twtcdx <username>"
    return 1
    fi
    
    curl "https://web.archive.org/cdx/search/cdx?url=twitter.com/$1/status/&matchType=prefix&output=json&filter=statuscode:200" > "cdx_$1.json"
    echo "Created cdx_$1.json"
}

twtquery() {

    if [ -z "$1" ]; then
        echo "Check if there's any archives of a twitter user."
        echo "Usage: twtquery <username>"
    return 1
    fi

    response=$(curl -s "https://web.archive.org/cdx/search/cdx?url=twitter.com/$1/status/&matchType=prefix&output=json&filter=statuscode:200")
    if [ "$response" = "[]" ]; then
        echo "Nothing found!"
    else
        echo "Valid!"
    fi
}

twtmake() {

    if [ -z "$1" ]; then
        echo "Print all the image URLs"
        echo "Usage: twtmake <username>"
    return 1
    fi
    
    json_file="cdx_$1.json"

    jq -r '.[] | "\([.[1], .[2]])"' "$json_file" | while IFS=',' read -r timestamp original; do
        # Clean up quotes from extracted values
        timestamp=$(echo "$timestamp" | tr -d '"' | tr -d '[')
        original=$(echo "$original" | tr -d '"' | tr -d ']')

        # Now you can use timestamp and original variables for your command
        #echo "Timestamp: $timestamp"
        #echo "Original URL: $original"
        formURL="https://web.archive.org/web/$timestamp/$original"

        if [ "$2" = "img" ]; then
            imageURL="$(curl -s "$formURL" | grep 'meta property="og:image" content="' | grep -o 'https://web.archive.org/web/'"$timestamp"'im_/https://pbs.twimg.com/media/[A-Za-z0-9-]\+\.[a-z]\+')"
            echo "$imageURL"
        else
            echo "$formURL"
        fi
    done
}

twthelp() { # outdated
    echo "twtarc - Uses archive.org to attempt to recover images from a deleted account."
    echo "twtcdx - Gets the CDX file from API."
    echo "twtquery - Check if a user was even archived."
    echo "twtmake - Print all URLs of a certain type."
}

# NOTE: most of this was AI generated but ive made a lot of edits to it now.
zipback() {

    if [ -z "$1" ]; then
        echo "Get all archives from a wayback website, no dupes."
        echo "Usage: zipback <site> <extensions>"
        echo "-h for suggested formats."
        return 1
    elif [ "$1" = "-h" ]; then
        echo "Old sites: jpg jpeg zip avi mpg mpeg wmv"
        return 1
    fi

    BASE_URL="$1"
    shift
    EXTENSIONS=("$@")  # All remaining arguments are extensions

    # if we dont have the cdx already, get it
    if ! test -f cdx_$BASE_URL.json; then
        echo "Fetching list of files from archive.org for $BASE_URL..."
        curl -s "https://web.archive.org/cdx/search/cdx?url=${BASE_URL}&matchType=prefix&output=json&collapse=urlkey&filter=statuscode:200" > cdx_$BASE_URL.json
    else
        echo "cdx found"
    fi

    # we're timing out when triyng to get the cdx
    if grep -q "<html" cdx_$BASE_URL.json; then
        echo -e "$ERROR cdx file invalid! IA is having issues. Try later."
        grep "<html" cdx_$BASE_URL.json
        rm cdx_$BASE_URL.json # delete it, its no good
        return 1
    fi

    # === BUILD jq FILTER ===
    jq_filter=""
    for ext in "${EXTENSIONS[@]}"; do
        jq_filter+="endswith(\".${ext}\") or "
    done
    jq_filter="${jq_filter::-4}"  # Remove trailing " or "

    # === PARSE AND DOWNLOAD FILES ===
    echo "Filtering for extensions: ${EXTENSIONS[*]}"
    echo "Downloading to zipback/"
    touch ./zipback/temp_urlList.txt
    touch ./zipback/temp_urlList.txt

    # da loop
    jq -r '.[] | select(.[2] | '"$jq_filter"') | .[1] + " " + "https://web.archive.org/web/" + .[1] + "/" + .[2]' cdx_"$BASE_URL".json | tail -n +2 | while read -r timestamp url; do
    filename=$(basename "$url")
    if [ -f "./zipback/$filename" ]; then
        echo "NOTE: Exists, skipping $filename"
        continue
    fi
    
    # mostly for debugging
    time=$(date +%H:%M:%S)

    # if we hit IA too hard they block us temporarily
    status=$(wget --spider --timeout=10 --server-response "$url" 2>&1) # | awk '/^  HTTP/{print $2}'
    if echo "$status" | grep -q "Connection refused"; then
        echo -e "[$time] $ERROR Can't connect to $url, we're probably blocked."
        echo -e "Calling timeout-test [DEBUG]"
        #timeout-test
        echo -e "$WARN Taking a long nap (2 minutes)."
        sleep 160 # 2 = minutes, 300 = 5

        # try again after sleep
        status=$(wget --spider --timeout=10 --server-response "$url" 2>&1)
        # still blocked? just cancel it.
        if echo "$status" | grep -q "Connection refused"; then
            echo -e "$ERROR Still blocked. Exiting."
            return 1
        fi

    # Check if it's a 404 (broken link)
    elif echo "$status" | grep -q "404"; then
        echo -e "$WARN $filename Not found!! Skipping."
    # If it's OK, move on
    elif echo "$status" | grep -q "200"; then

        # download valley (the good one)
        echo "[$time] Downloading: $filename "
        echo "$url" >> ./zipback/temp_urlList.txt
        echo "$status" >> ./zipback/temp_urlList.txt
        wget --timeout=10 --tries=2 --waitretry=0 --random-wait --retry-connrefused -q --show-progress --directory-prefix="./zipback" "$url"
        requests=$(expr $requests + 1)

        # adding timestmaps (if you're a nerd and using WSL)
        # touchTime=$(date -d "${timestamp:0:8} ${timestamp:8:2}:${timestamp:10:2}:${timestamp:12:2}" +"%Y%m%d%H%M.%S")
        # touch -t "$touchTime" "$filename"

        # dont get too caught up on certain files
        if [ $? -ne 0 ]; then
            echo -e "[$time] $WARN Shits too slow!! Skipping."
            echo "$url" >> ./zipback/err_urlList.txt
        else
            echo "$url" >> ./zipback/urlList.txt
        fi

        # check if its not somehow HTML cus IA be quirky like that
        verify=$(file ./zipback/$filename)
        if echo "$verify" | grep -q "HTML"; then
            echo -e "[$time] $ERROR $filename is HTML. Deleting."
            echo "$url" >> ./zipback/err_urlList.txt
            rm ./zipback/$filename
        fi
        sleep 3 # frail child needs frequent breaks

        if [ "$requests" -ge 8 ]; then
            echo -e "[$time] $NOTE Resting..." # honk snoo
            sleep 30
            requests=0
        fi

    # failsafe
    else
        echo -e "[$time] $ERROR Uhhh, unexpected code? $status"
        return 1
    fi

    done

rm ./zipback/temp_urlList.txt
}

cdxback() {

    if [ -z "$1" ]; then
        echo "Gets the cdx file for a given page."
        echo "Usage: cdxback <site>"
    return 1
    fi
    
    curl -s "https://web.archive.org/cdx/search/cdx?url=$1&matchType=prefix&output=json&collapse=urlkey&filter=statuscode:200" > "cdx_$1.json"
    echo "Created cdx_$1.json"
}

cdxmake() {

     if [ -z "$1" ]; then
        echo "Generates a list of URLs from a CDX. Use after cdxback."
        echo "Usage: cdxmake <site>"
    return 1
    fi

    BASE_URL="$1"
    # da loop
    jq -r '.[] | select(.[2]) | .[1] + " " + "https://web.archive.org/web/" + .[1] + "/" + .[2]' cdx_"$BASE_URL".json | tail -n +2 | while read -r timestamp url; do
    filename=$(basename "$url")
    echo "$url" >> $BASE_URL\_list.txt
    done
}

timeout-test() {
    echo -e "Repeatedly sending reqs every 5 seconds until it lets us in"
    
    while true; do
    # if we hit IA too hard they block us temporarily
        time=$(date +%H:%M:%S)
        echo -e "[$time] $NOTE Checking..."
        status=$(wget --spider --timeout=10 --server-response "https://web.archive.org" 2>&1)
        if echo "$status" | grep -q "Connection refused"; then
            echo -e "[$time] $ERROR Still blocked, trying again."
            sleep 5
        else
            echo -e "[$time] Unblocked!"
            return 1
        fi
    done
}

da-search() {
    search=$1
    #shift
    # "$@"
    rg "$search" /sym/Root/Backups/DeviantArtDB | while IFS= read -r line; do
    # Extract the quoted strings manually using POSIX tools
    filename=$(echo "$line" | cut -d: -f1)
    timestamp=$(echo "$line" | tr '"' '\n' | awk 'NR==4 {print $1}')
    original=$(echo "$line" | tr '"' '\n' | awk 'NR==6 {print $1}')

    echo "Found @ $filename/$timestamp"
    # Create the Web Archive URL
    archive_url="https://web.archive.org/web/${timestamp}im_/$original"

    # Print the archive URL
    echo $archive_url >> $search.txt

    # Use curl to fetch the URL
    #curl -O "$archive_url"
    done
    echo "Sent to $search.txt"
}

da-search-man() {

    if [ $1 == "list" ]; then
      ls /sym/Root/Backups/DeviantArtDB/CDX
      return 1
    fi

    search=$2
    #shift
    # "$@"
    rg "$search" /sym/Root/Backups/DeviantArtDB/CDX/$1 | while IFS= read -r line; do
    # Extract the quoted strings manually using POSIX tools
    filename=$(echo "$line" | cut -d: -f1)
    timestamp=$(echo "$line" | tr '"' '\n' | awk 'NR==4 {print $1}')
    original=$(echo "$line" | tr '"' '\n' | awk 'NR==6 {print $1}')

    echo "Found @ $filename/$timestamp"
    # Create the Web Archive URL
    archive_url="https://web.archive.org/web/${timestamp}im_/$original"

    # Print the archive URL (optional, for debugging)
    echo $archive_url >> $search.txt

    # Use curl to fetch the URL (you can add options like -O to save the file)
    #curl -O "$archive_url"
    done
    echo "Sent to $search.txt"
}

wixmp-search() {
    uuid="$1"

    if [ -z "$uuid" ]; then
        echo "Usage: $0 <artist_uuid>"
        echo "-h for help"
        return 1
    elif [ $uuid == "-h" ]; then
        echo "how2find UUID: Find image from a user, direct link, string after /f/."
        return 1
    fi

    # List of base URL paths
    paths=(
    "intermediary/f"
    "f"
    )

    for path in "${paths[@]}"; do
    url="https://web.archive.org/cdx/search/cdx?url=images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/${path}/$uuid/&matchType=prefix&filter=mimetype:image/*&output=json&collapse=urlkey"
    echo "Checking: $path"

    response=$(curl -s "$url")

    if [[ -n "$response" && "$response" != "[]" ]]; then

        timestamp=$(echo "$response" | jq -r '.[1][1]')
        original=$(echo "$response" | jq -r '.[1][2]')

        # Create the Web Archive URL
        echo "Found $timestamp"
        archive_url="https://web.archive.org/web/$timestamp/$original"

        # Print the archive URL
        echo $archive_url >> $uuid.txt
    else
        echo "Nothing for $path"
    fi
    done
}

tumbldryer() { # unfinished 

inputList="${1}_list.txt"
tempFile="temp.html"

while IFS= read -r pageUrl; do

    status=$(wget --spider --timeout=10 --server-response "$pageUrl" 2>&1)

    if echo "$status" | grep -q "Connection refused"; then
        echo -e "[$(date)] ERROR Can't connect to $pageUrl, we're probably blocked."
        echo -e "Calling timeout-test [DEBUG]"
        # timeout-test

        echo -e "WARN Taking a long nap (2 minutes)."
        sleep 160 # Sleep for 2 minutes

        # Try again after sleeping
        status=$(wget --spider --timeout=10 --server-response "$pageUrl" 2>&1)

        if echo "$status" | grep -q "Connection refused"; then
            echo -e "ERROR Still blocked after retry. Exiting."
            return 1
        fi

    fi

    if echo "$status" | grep -q "404"; then
        echo -e "WARN $pageUrl Not found!! Skipping."

    elif echo "$status" | grep -q "200"; then
        echo -e "\nDownloading: $pageUrl"
        curl -s "$pageUrl" -o "$tempFile"
        grep -oE 'http://[0-9]{1,3}\.media\.tumblr\.com[^ "]*' "$tempFile" | sort -u >> "${1}_found.txt"

    else
        echo -e "[$time] $ERROR Uhhh, unexpected code? $status"
        return 1
    fi

done < "$inputList"

# Remove duplicates from the output list
sort -u "$outputList" -o "$outputList"


}

# yes yes I KNOW I KNOW ITS AI GENERATED I JUST
# WANTED A SOLUTION ITS SO HOT IN MY ROOM RN
# ILL REWRITE THIS LATER IF YOU REALLY WANT
checkdel() {
    # Check arguments
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Usage: checkdel <artist> [live]"
	echo "live only supports twitter right now"
        return 1
    elif [ -n "$1" ]; then
	imagesDir=$1
    	metadataDir="$imagesDir/metadata"
    	deletedDir="$imagesDir/deleted"
    fi

    if [ "$2" = "live" ]; then
        echo "live check"
	metadataDir="$imagesDir/integrityTemp"
	# echo $metadataDir

   gallery-dl -d . --postprocessor twitter-integrity --no-download -o skip=false --download-archive /dev/null "https://x.com/$1" > /dev/null

#	if [[ "$1" == *x.com* ]]; then
#	   gallery-dl -d . --postprocessor twitter-integrity --no-download -o skip=false --download-archive /dev/null "https://x.com/$1" > /dev/null        
#	elif [[ "$1" == *pixiv.net* ]]; then
#	   gallery-dl -d . --postprocessor pixiv-integrity --no-download -o skip=false --download-archive /dev/null "$1" > /dev/null
#	fi
    fi

    # Ensure metadata directory exists
    if [ ! -d "$metadataDir" ]; then
        echo "Metadata directory not found at: $metadataDir"
        return 1
    fi

    # Create deleted directory if it doesn't exist
    mkdir -p "$deletedDir"

    # echo "using $metadataDir"
    # Extract 19-digit Twitter post IDs from filenames
    tmpImageIds=$(mktemp)
    tmpMetaIds=$(mktemp)

    find "$imagesDir" -type f | grep -v "$metadataDir/" | grep -v "$deletedDir/" | sed -n 's#.*/\([0-9]\{19\}\)_.*#\1#p' | sort -u > "$tmpImageIds"
    find "$metadataDir" -type f | sed -n 's#.*/\([0-9]\{19\}\)_.*#\1#p' | sort -u > "$tmpMetaIds"

    # Find IDs with images but no metadata
    missingMetaIds=$(comm -23 "$tmpImageIds" "$tmpMetaIds")

    # Move matching image files to "deleted" folder
    echo "Moving image files with no corresponding metadata to: $deletedDir"

    echo "$missingMetaIds" | while read postId; do
        echo "$postId"
        find "$imagesDir" -type f | grep "/${postId}_" | grep -v "$metadataDir/" | grep -v "$deletedDir/" | while read file; do
            mv "$file" "$deletedDir/"
        done
    done

    # Cleanup
    rm -f "$tmpImageIds" "$tmpMetaIds"

    if [ "$2" = "live" ]; then
	rm -rf "$imagesDir/integrityTemp"
    fi

}

twtarc-neo() {
    if [ -z "$1" ]; then
        echo "Recovered archived images from a specified Twitter profile."
        echo "Usage: twtarc <username>"
        return 1
    fi

    mkdir -p "$1"

    # Grab the CDX.json
    curl -s "https://web.archive.org/cdx/search/cdx?url=twitter.com/$1/status/&matchType=prefix&output=json" > "cdx_$1.json"

    json_file="cdx_$1.json"

    # Loop through each entry in the JSON array
    jq -r '.[] | "\([.[1], .[2]])"' "$json_file" | while IFS=',' read -r timestamp original; do
        timestamp=$(echo "$timestamp" | tr -d '"' | tr -d '[')
        original=$(echo "$original" | tr -d '"' | tr -d ']')

        formURL="https://web.archive.org/web/${timestamp}if_/${original}"

        # Grab all tweet-image <img> tags
        imageURLs=$(curl -s "$formURL" | grep -o 'https://web.archive.org/web/'"$timestamp"'im_/https://pbs.twimg.com/media/[A-Za-z0-9_-]\+\.[a-zA-Z0-9]\+')

        case "$original" in
            https://*|http://*)
                if [ -z "$imageURLs" ]; then
                    echo "[$timestamp] No images found."
                else
                    for imageURL in $imageURLs; do
                        echo "[$timestamp] Downloading: $imageURL"
                        wget -nc -P "$1" -q "$imageURL"
                        sleep 2 # avoid archive.org timeouts
                    done
                fi
                ;;
            *)
                echo "Invalid URL: $original"
                ;;
        esac
    done

    touch "$1/GATHERED-BY-TWTARC"
}

# https://gist.github.com/rsms/87570aa1a839ce4884e7d83a3c3dac84
apk-size() {
	apk info -e -s \* >/tmp/apksize
	awk 'NR % 3 == 1' /tmp/apksize | cut -d ' ' -f 1 > /tmp/apkname
	awk 'NR % 3 == 2' /tmp/apksize > /tmp/apksize2
	
	while read -r n unit; do
	  B=$n
	  case "$unit" in
	    KiB) B=$(( n * 1024 )) ;;
	    MiB) B=$(( n * 1024 * 1024 )) ;;
	    GiB) B=$(( n * 1024 * 1024 * 1024 )) ;;
	  esac
	  printf "%12u %4s %-3s\n" $B $n $unit
	done < /tmp/apksize2 > /tmp/apksize
	
	paste -d' ' /tmp/apksize /tmp/apkname | sort -n -u | cut -c14-
	rm /tmp/apksize /tmp/apksize2 /tmp/apkname
}

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
