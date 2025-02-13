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
        echo "unlistedhunter stats"
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
        output=$(yt-dlp --simulate --print-json "$videoUrl" 2>&1) # Add  <loc> to see adult video statuses

        # Check for specific strings in the output
        if echo "$output" | grep -q "copyright claim"; then # Copyright claimed
            printf "C"
            cCount=$((cCount + 1))
        elif echo "$output" | grep -q "inappropriate"; then # 18+
            printf "A"
            aCount=$((aCount + 1))
        elif echo "$output" | grep -q "Private"; then # Private video
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
                printf "UNLISTED: %s" "$videoUrl\n"
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
