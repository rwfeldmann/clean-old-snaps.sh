#!/bin/bash

# clean_old_snaps.sh
# Removes disabled snap revisions to free up disk space
# Make sure to stop any running snaps BEFORE running this
# Use at your own risk!

set -euo pipefail

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${level}: ${message}"
}

# Function to check if snap is installed
check_snap_installed() {
    if ! command -v snap &>/dev/null; then
        log_message "ERROR" "snap command not found. Is snapd installed?"
        exit 1
    fi
}

# Function to clean old snap revisions
clean_old_snaps() {
    log_message "INFO" "Starting cleanup of disabled snap revisions"

    # Ensure LANG is set for consistent output
    export LANG=en_US.UTF-8

    # Get list of disabled snaps
    local snap_list
    snap_list=$(snap list --all | awk '/disabled/{print $1, $3}' 2>/dev/null)
    
    if [ -z "$snap_list" ]; then
        log_message "INFO" "No disabled snap revisions found"
        return 0
    fi

    local count=0
    # Process each disabled snap
    while read -r snapname revision; do
        if [ -z "$snapname" ] || [ -z "$revision" ]; then
            log_message "WARNING" "Invalid snap data, skipping"
            continue
        fi

        log_message "INFO" "Removing $snapname (revision $revision)"
        if snap remove "$snapname" --revision="$revision" 2>/dev/null; then
            log_message "INFO" "Successfully removed $snapname (revision $revision)"
            ((count++))
        else
            log_message "ERROR" "Failed to remove $snapname (revision $revision)"
        fi
    done <<< "$snap_list"

    log_message "INFO" "Cleanup complete. Removed $count snap revisions"
}

# Main execution
main() {
    # Check if running as root (optional, depending on system requirements)
    if [ "$(id -u)" -ne 0 ]; then
        log_message "WARNING" "This script may require root privileges for some operations"
        # Uncomment if root is mandatory
        # exit 1
    fi

    check_snap_installed
    clean_old_snaps
}

main "$@"
