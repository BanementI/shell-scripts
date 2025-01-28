idgen() {
    if [[ "$1" == "old" ]]; then
        # Extract video IDs from filenames in the old format
        find . -maxdepth 1 -regex '.*\.\(mkv\|mp4\|webm\)' | sed -En '/.*-[A-Za-z0-9_-]{11}\.[^.]+$/ s/.*-([A-Za-z0-9_-]{11})\.[^.]+$/\1/p' | uniq
    else
        # Extract video IDs from filenames with square brackets
        find . -maxdepth 1 -regex '.*\.\(mkv\|mp4\|webm\)' | grep '\[[^]]\{11\}\]' | sed -E 's/.*\[([^]]{11})\].*/\1/' | uniq 
    fi
}
