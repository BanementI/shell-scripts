#!/bin/bash
# Looks for locally downloaded videos (or change the video list name to read from a list of IDs) and sees if they are unlisted on YouTube.
# Usage: "unlistedhunter" = Extracts video IDs with yt-dlp new format (Title [VIDEOID].mp4).
# "unlistedhunter old" = Uses old youtube-dl format (Title-VIDEOID.mp4)
#
unlistedhunter() {
    # Video list file
    videoList="localIDs.txt"
    cCount=0
    aCount=0
    pCount=0
    tCount=0
    pubCount=0

    stats() {
        echo "unlistedhunter stats"
        echo "C A P T . U F"
        echo "$cCount $aCount $pCount $tCount $pubCount $unCount"
        exit 0
    }

    # Show the stats if you Ctrl + C
    trap stats SIGINT

   if [[ "$1" == "old" ]]; then
        # Extract video IDs from filenames in the old format
        find . -maxdepth 1 -regex '.*\.\(mkv\|mp4\|webm\)' | sed -E 's/.*-([A-Za-z0-9_-]{11})\.[^.]+$/\1/' > "$videoList"
   else
        # Extract video IDs from filenames with square brackets
        find . -maxdepth 1 -regex '.*\.\(mkv\|mp4\|webm\)' | sed -E 's/.*\[([^]]{11})\].*/\1/' > "$videoList"
   fi

    # Base URL for YouTube videos
    baseUrl="https://www.youtube.com/watch?v="
    echo "unlistedhunter: C = Copyright, A = 18+, P = Private, T = Terminated, . = Public" 

    # Loop through each line in the video list
    while read -r videoId; do
        # Skip empty lines
        if [[ -z "$videoId" ]]; then
            echo "Skipping empty line."
            continue
        fi

        # Construct the full video URL
        videoUrl="${baseUrl}${videoId}"

        # Run yt-dlp to simulate fetching video info (without actually downloading it)
        output=$(yt-dlp --simulate --print-json $videoUrl 2>&1) # Add your own cookies to see status of adult videos.

        # Check for specific strings in the output
        if echo "$output" | grep -q "copyright claim"; then # Copyright claimed
            echo -n "C"
            ((cCount++))
        elif echo "$output" | grep -q "inappropriate"; then # 18+
            echo -n "A"
            ((aCount++))
        elif echo "$output" | grep -q "Private"; then # Private video
            echo -n "P"
            ((pCount++))
        elif echo "$output" | grep -q "terminated"; then # Terminated YT account
            echo -n "T"
            ((tCount++))
        elif echo "$output" | grep -q "unlisted"; then # What we want
            printf "\nUNLISTED: $videoUrl\n"
            echo $output | jq '.title'
            ((unCount++))       
        else # Public videos
                echo -n "."
                ((pubCount++))
        fi
    done < "$videoList"
    stats
}
