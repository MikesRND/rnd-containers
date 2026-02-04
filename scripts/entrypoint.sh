#!/bin/bash
set -e

# ── Drop-in hooks ──────────────────────────────────────────
# Higher layers place scripts in /etc/entrypoint.d/ for
# platform-specific initialization (NVIDIA, DPDK, etc.)
if [ -d /etc/entrypoint.d ]; then
    for hook in /etc/entrypoint.d/*.sh; do
        [ -f "$hook" ] || continue
        echo "[entrypoint] Running hook: $(basename "$hook")"
        source "$hook" || echo "[entrypoint] WARNING: hook $(basename "$hook") failed, continuing..."
    done
fi

# ── User creation ───────────────────────────────────────────
USER_NAME=${USERNAME:-developer}
USER_ID=${USERID:-1000}
GROUP_ID=${GROUPID:-1000}

echo "[entrypoint] Setting up user: $USER_NAME ($USER_ID:$GROUP_ID)"

# Create group if needed
if ! getent group "$GROUP_ID" > /dev/null 2>&1; then
    groupadd -g "$GROUP_ID" "$USER_NAME"
elif ! getent group "$USER_NAME" > /dev/null 2>&1; then
    EXISTING_GROUP=$(getent group "$GROUP_ID" | cut -d: -f1)
    echo "[entrypoint] Using existing group: $EXISTING_GROUP ($GROUP_ID)"
fi

# Create or reconcile user
if ! id "$USER_NAME" > /dev/null 2>&1; then
    if id "$USER_ID" > /dev/null 2>&1; then
        EXISTING_USER=$(id -nu "$USER_ID")
        if [ "$EXISTING_USER" != "$USER_NAME" ]; then
            echo "[entrypoint] Renaming $EXISTING_USER -> $USER_NAME"
            usermod -l "$USER_NAME" "$EXISTING_USER"
            usermod -d "/home/$USER_NAME" -m "$USER_NAME" 2>/dev/null || true
        fi
    else
        useradd -m -u "$USER_ID" -g "$GROUP_ID" -s /bin/bash "$USER_NAME"
        usermod -aG sudo "$USER_NAME"
    fi
fi

# Always ensure sudoers + home ownership (safety net for pre-existing users)
mkdir -p /etc/sudoers.d
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"
chown -R "$USER_NAME:$GROUP_ID" "/home/$USER_NAME" 2>/dev/null || true

# ── Workspace permissions ───────────────────────────────────
WORK_DIR="${WORKDIR:-/workspace}"
if [ -d "$WORK_DIR" ]; then
    echo "[entrypoint] Fixing $WORK_DIR permissions for $USER_NAME ($USER_ID:$GROUP_ID)"
    chown "$USER_ID:$GROUP_ID" "$WORK_DIR" 2>/dev/null || true
    for item in "$WORK_DIR"/*; do
        if [ -e "$item" ] && [ ! -L "$item" ] && [ "$(stat -c %u "$item")" = "0" ]; then
            echo "[entrypoint] Fixing permissions: $(basename "$item")"
            chown -R "$USER_ID:$GROUP_ID" "$item" 2>/dev/null || true
        fi
    done
fi

# ── Exec ────────────────────────────────────────────────────
if [ $# -eq 0 ]; then
    echo "[entrypoint] Launching interactive shell for $USER_NAME in $WORK_DIR"
    exec su - "$USER_NAME" -c "cd '$WORK_DIR' && exec bash"
elif [ "$1" = "sleep" ] && [ "$2" = "infinity" ]; then
    echo "[entrypoint] Keeping container alive (workdir: $WORK_DIR)"
    exec su - "$USER_NAME" -c "cd '$WORK_DIR' && exec sleep infinity"
else
    echo "[entrypoint] Executing as $USER_NAME in $WORK_DIR: $*"
    exec su - "$USER_NAME" -c "cd '$WORK_DIR' && exec \"\$@\"" -- "$@"
fi
