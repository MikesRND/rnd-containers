#!/bin/bash
set -e

# Run NVIDIA entrypoint initialization (using our modified copy without exec)
if [ -f /opt/nvidia/nvidia_entrypoint_no_exec.sh ]; then
    echo "[entrypoint] Running NVIDIA initialization..."
    if source /opt/nvidia/nvidia_entrypoint_no_exec.sh; then
        echo "[entrypoint] NVIDIA initialization completed"
    else
        echo "[entrypoint] WARNING: NVIDIA initialization failed, continuing anyway..."
    fi
else
    echo "[entrypoint] WARNING: Modified NVIDIA entrypoint not found at /opt/nvidia/nvidia_entrypoint_no_exec.sh"
fi

# Read UID/GID/USERNAME or fallback
USER_NAME=${USERNAME:-developer}
USER_ID=${USERID:-1000}
GROUP_ID=${GROUPID:-1000}

echo "[entrypoint] Creating user: $USER_NAME ($USER_ID:$GROUP_ID)"

# If group doesn't exist, create it
if ! getent group "$GROUP_ID" > /dev/null 2>&1; then
    groupadd -g "$GROUP_ID" "$USER_NAME"
elif ! getent group "$USER_NAME" > /dev/null 2>&1; then
    # Group ID exists but with different name, use existing group
    EXISTING_GROUP=$(getent group "$GROUP_ID" | cut -d: -f1)
    echo "[entrypoint] Using existing group: $EXISTING_GROUP ($GROUP_ID)"
fi

# If user doesn't exist, create it with home directory
if ! id "$USER_NAME" > /dev/null 2>&1; then
    if id "$USER_ID" > /dev/null 2>&1; then
        # UID already exists, need to handle this
        EXISTING_USER=$(id -nu "$USER_ID")
        echo "[entrypoint] UID $USER_ID already exists for user: $EXISTING_USER"
        
        if [ "$EXISTING_USER" != "$USER_NAME" ]; then
            # Rename existing user to desired name (safer than delete/recreate)
            echo "[entrypoint] Renaming existing user $EXISTING_USER to $USER_NAME"
            # Rename the user and their home directory
            usermod -l "$USER_NAME" "$EXISTING_USER"
            usermod -d "/home/$USER_NAME" -m "$USER_NAME" 2>/dev/null || true
            # Set up sudo without password for convenience in container
            mkdir -p /etc/sudoers.d
            echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"
            # Update USER_NAME for the rest of the script
            USER_NAME="$USER_NAME"
        fi
    else
        useradd -m -u "$USER_ID" -g "$GROUP_ID" -s /bin/bash "$USER_NAME"
        # Add user to sudo group
        usermod -aG sudo "$USER_NAME"
        # Set up sudo without password for convenience in container
        mkdir -p /etc/sudoers.d
        echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"
        # Ensure the user owns their home directory
        chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME"
    fi
fi

# Fix /workspace permissions if it exists
if [ -d "/workspace" ]; then
    echo "[entrypoint] Fixing /workspace permissions for user $USER_NAME ($USER_ID:$GROUP_ID)"
    chown -R "$USER_ID:$GROUP_ID" /workspace 2>/dev/null || {
        echo "[entrypoint] WARNING: Could not change /workspace ownership (may need root privileges)"
    }
fi

# Switch to the user and change to workspace directory if it exists
WORKSPACE_DIR="/workspace/gpu-algorithms"
if [ -d "$WORKSPACE_DIR" ]; then
    WORK_DIR="$WORKSPACE_DIR"
else
    WORK_DIR="/home/$USER_NAME"
fi

if [ $# -eq 0 ]; then
    # No command provided, start interactive bash
    exec su - "$USER_NAME" -c "cd '$WORK_DIR' && exec bash"
elif [ "$1" = "sleep" ] && [ "$2" = "infinity" ]; then
    # Handle sleep infinity command specially for container persistence
    exec su - "$USER_NAME" -c "cd '$WORK_DIR' && exec sleep infinity"
else
    # Command provided, execute it
    exec su - "$USER_NAME" -c "cd '$WORK_DIR' && exec \"\$@\"" -- "$@"
fi