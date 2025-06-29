#!/bin/sh
##################################################################
# ARCFUNC
#
# Scripts to help maintain my archives.
#
##################################################################

arcfunc() {
    printf "arcfunc by banement\n"
    printf "pixivcheck - Checks if pixiv images are still online or not.\n"
    printf "pixivnum - Displays the detected amount of pixiv images.\n"
    printf "unlistedhunter - Basically a better version of videocheck, prioritises unlisted videos.\n"
    printf "videocheck - Checks the status of downloaded youtube videos.\n"
    printf "idgen - Generates a list of video IDs as output.txt.\n"
    printf "zipback - Fetches all of a specified file format from an archive on IA.\n"
    printf "wixmp-search <uuid> - Searches IA API for URLs.\n"
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
    find . -maxdepth 1 -type f -print | sed -nE 's/^([0-9]+)_p.*/\1/p'
}

# Scans the current folder for youtube video IDs downloaded by yt-dlp/youtube-dl, then checks if they are still online.
# Usage: videocheck [old] 
videocheck() {
    # Video list file
    videoList="localIDs.txt"
    cCount=0
    aCount=0
    pCount=0
    tCount=0
    dCount=0
    pubCount=0

    stats() {
        echo "videocheck stats"
        echo "C A P T . D"
        echo "$cCount $aCount $pCount $tCount $pubCount $dCount"
    }

    if [ "$1" = "old" ]; then
        # Extract video IDs from filenames in the old format
        find . -maxdepth 1 -regex '.*\.\(mkv\|mp4\|webm\)' | sed -En '/.*-[A-Za-z0-9_-]{11}\.[^.]+$/ s/.*-([A-Za-z0-9_-]{11})\.[^.]+$/\1/p' | uniq > "$videoList"
    else
        # Extract video IDs from filenames with square brackets
        find . -maxdepth 1 -regex '.*\.\(mkv\|mp4\|webm\)' | grep '\[[^]]\{11\}\]' | sed -E 's/.*\[([^]]{11})\].*/\1/' | uniq > "$videoList"
    fi

    # Base URL for YouTube videos
    baseUrl="https://www.youtube.com/watch?v="

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
        if [ -n "${DEBUG_SCRIPT}" ]; then # Set DEBUG_SCRIPT environmental variable to anything to get full output
            output=$(yt-dlp --simulate "$videoUrl")
        else
            output=$(yt-dlp --simulate --cookies ~/ai/cookies.txt "$videoUrl" 2>&1)
        fi

        # Check for specific strings in the output
        if echo "$output" | grep -q "inappropriate"; then
            echo "OK (18+): $videoId"
            (aCount++)
        elif echo "$output" | grep -q "terminated"; then
            echo "TERMINATED ACCOUNT: $videoUrl"
            (tCount++)
        elif echo "$output" | grep -q "Private video"; then
            echo "PRIVATE: $videoUrl"
            (pCount++)
        elif echo "$output" | grep -q "copyright claim"; then
            echo "COPYRIGHT CLAIMED: $videoUrl"
            (cCount++)
        elif echo "$output" | grep -q "Video unavailable"; then
            echo "Video unavailable: $videoUrl"
            (dCount++)
        elif [ -n "${DEBUG_SCRIPT}" ]; then
            echo "$output"
        else
            echo "OK: $videoId"
            (pubCount++)
        fi
    done < "$videoList"
    stats
}

# 
idgen() {
  (find . -regex '.*\.\(mkv\|mp4\|webm\)' | sed -En '/.*-[A-Za-z0-9_-]{11}\.[^.]+$/ s/.*-([A-Za-z0-9_-]{11})\.[^.]+$/\1/p'; \
  find . -regex '.*\.\(mkv\|mp4\|webm\)' | grep '\[[^]]\{11\}\]' | sed -E 's/.*\[([^]]{11})\].*/\1/' | uniq) >> output.txt
}

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

# NOTE: initially ai generated but theres a shit ton of edits by me now
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
        exit 1
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
            exit 1
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

        # adding timestmaps
        touchTime=$(date -d "${timestamp:0:8} ${timestamp:8:2}:${timestamp:10:2}:${timestamp:12:2}" +"%Y%m%d%H%M.%S")
        touch -t "$touchTime" "$filename"

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
        exit 1
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

wixmp-search() {
    uuid="$1"

    if [ -z "$uuid" ]; then
        echo "Usage: $0 <artist_uuid>"
        echo "-h for help"
        exit 1
    elif [ $uuid == "-h" ]; then
        echo "how2find UUID: Find image from a user, direct link, string after /f/."
        exit 1
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

        # Print the archive URL (optional, for debugging)
        echo $archive_url >> $uuid.txt
    else
        echo "Nothing for $path"
    fi
    done
}
