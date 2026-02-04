#!/bin/bash
#
# setup_workspace_mapping.sh
#
# Automatically creates a convenient symlink at /workspace/<directory-name>
# for whatever directory is mounted at /mnt/current_folder.
#
# This modular script can be sourced by container entrypoints to provide
# consistent directory mapping across different containers.
#

setup_workspace_mapping() {
    # Check if a directory is mounted at /mnt/current_folder
    if [ -d "/mnt/current_folder" ]; then
        # Extract actual directory name from /proc/1/mountinfo
        FOLDER_NAME=$(grep '/mnt/current_folder' /proc/1/mountinfo | awk '{print $4}' | xargs basename 2>/dev/null)

        if [ -z "$FOLDER_NAME" ]; then
            echo "[entrypoint] WARNING: Could not detect directory name from mount information"
            echo "[entrypoint] Using fallback name: current"
            FOLDER_NAME="current"
        fi

        echo "[entrypoint] Mounting workspace as: $FOLDER_NAME"

        # Ensure /workspace exists
        mkdir -p /workspace

        # Remove existing symlink/directory if present
        if [ -e "/workspace/$FOLDER_NAME" ]; then
            rm -rf "/workspace/$FOLDER_NAME"
        fi

        # Create symlink from /workspace/<folder_name> to /mnt/current_folder
        ln -sf /mnt/current_folder "/workspace/$FOLDER_NAME"
        echo "[entrypoint] Directory mapped: /mnt/current_folder -> /workspace/$FOLDER_NAME"

        return 0
    else
        echo "[entrypoint] No directory mounted at /mnt/current_folder"
        return 1
    fi
}