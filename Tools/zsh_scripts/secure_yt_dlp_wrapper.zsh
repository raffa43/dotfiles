#!/usr/bin/env zsh

# Define where to put suspicious files
QUARANTINE_DIR="$HOME/Quarantine"
mkdir -p "$QUARANTINE_DIR"

# ---------------------------------------------------------
# 1. INTERNAL HOOK: Post-download security check
# (yt-dlp calls this part of the script via --exec)
# ---------------------------------------------------------
if [[ "$1" == "--internal-check" ]]; then
    FILEPATH="$2"
    FILENAME=$(basename "$FILEPATH")
    IS_SUSPICIOUS=0

    echo -e "\n=> [SECURITY] Running checks on: $FILENAME"

    # Check 1: File Signature (MIME Type)
    MIME_TYPE=$(file --mime-type -b "$FILEPATH")
    echo "   - Detected MIME type: $MIME_TYPE"
    
    if ! echo "$MIME_TYPE" | grep -qiE 'video|audio|application/mp4'; then
        echo "   [!] WARNING: File signature is NOT a recognized media format!"
        IS_SUSPICIOUS=1
    fi

    # Check 2: ClamAV Virus Scan
    if command -v clamscan &> /dev/null; then
        echo "   - Running ClamAV scan..."
        if ! clamscan --no-summary "$FILEPATH"; then
            echo "   [!] ALERT: ClamAV detected a threat!"
            IS_SUSPICIOUS=1
        fi
    else
        echo "   - ClamAV (clamscan) not found, skipping virus scan."
    fi

    # Action: Quarantine if anything failed
    if [[ $IS_SUSPICIOUS -eq 1 ]]; then
        echo "=> [ACTION] File is suspicious. Moving to quarantine..."
        mv "$FILEPATH" "$QUARANTINE_DIR/"
        chmod -x "$QUARANTINE_DIR/$FILENAME"
        echo "=> [QUARANTINED] File moved to $QUARANTINE_DIR/$FILENAME"
    else
        echo "=> [OK] File is clean and ready to play!"
    fi
    exit 0
fi

# ---------------------------------------------------------
# 2. MAIN EXECUTION: MPV vs Manual Download
# ---------------------------------------------------------
args=("$@")
is_mpv=0

# MPV fetches stream metadata by silently requesting JSON data.
for arg in "${args[@]}"; do
    if [[ "$arg" == "--dump-json" || "$arg" == "-J" ]]; then
        is_mpv=1
        break
    fi
done

if [[ $is_mpv -eq 1 ]]; then
    # MPV MODE: Pass arguments normally but bypass the unusual extension block.
    # We do NOT remux or quarantine here because no file is being downloaded.
    yt-dlp --compat-options allow-unsafe-ext "${args[@]}"
else
    # MANUAL DOWNLOAD MODE: Apply formatting, remux, and trigger the security check.
    # Get the absolute path to this script so yt-dlp can call it back safely.
    SCRIPT_PATH=$(realpath "$0")
    
    yt-dlp \
        --compat-options allow-unsafe-ext \
        --trim-filenames 150 \
        -o "%(title)s.%(ext)s" \
        -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" \
        --merge-output-format mp4 \
        --remux-video mp4 \
        --exec "$SCRIPT_PATH --internal-check {}" \
        "${args[@]}"
fi
