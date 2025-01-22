#!/bin/bash
# Compares locally downloaded videos with the status of them online to see if any you have has since been deleted.
# Usage: videocheck = Uses new yt-dlp filename format (Title [VIDEOID].mp4)
# videocheck old = Uses old youtube-dl filename format (Title-VIDEOID.mp4)
videocheck() {
    # Video list file
    videoList="localIDs.txt"

    if [[ "$1" == "old" ]]; then
        # Extract video IDs from filenames in the old format
        find . -maxdepth 1 -regex '.*\.\(mkv\|mp4\|webm\)' | sed -E 's/.*-([A-Za-z0-9_-]{11})\.[^.]+$/\1/' > "$videoList"
    else
        # Extract video IDs from filenames with square brackets
        find . -maxdepth 1 -regex '.*\.\(mkv\|mp4\|webm\)' | sed -E 's/.*\[([^]]{11})\].*/\1/' > "$videoList"
    fi

    # Base URL for YouTube videos
    baseUrl="https://www.youtube.com/watch?v="

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
        if [[ -n "${DEBUG_SCRIPT}" ]]; then # Set DEBUG_SCRIPT environmental variable to anything to get full output
            output=$(yt-dlp --simulate "$videoUrl")
        else
            output=$(yt-dlp --simulate "$videoUrl" 2>&1) # Add your own cookies to see status of adult videos.
        fi

        # Check for specific strings in the output
        if echo "$output" | grep -q "inappropriate"; then
            echo "OK (18+): $videoId"
        elif echo "$output" | grep -q "terminated"; then
            echo "TERMINATED ACCOUNT: $videoUrl"
        elif echo "$output" | grep -q "Private video"; then
            echo "PRIVATE: $videoUrl"
        elif echo "$output" | grep -q "copyright claim"; then
            echo "COPYRIGHT CLAIMED: $videoUrl"
        elif echo "$output" | grep -q "Video unavailable"; then
            echo "Video unavailable: $videoUrl"
        elif [[ -n "${DEBUG_SCRIPT}" ]]; then
            echo "$output"
        else
            echo "OK: $videoId"
        fi
    done < "$videoList"
}
