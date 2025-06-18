#!/bin/bash
set -e

TARGET_DIR=${WORKSPACE:-/playground}

USERNAME=player
GROUPNAME=player
CURRENT_UID=$(id -u "$USERNAME" 2>/dev/null)
CURRENT_GID=$(id -g "$USERNAME" 2>/dev/null)

# check if TARGET_DIR is mounted
if mountpoint -q "$TARGET_DIR"; then
    HOST_UID=$(stat -c "%u" $TARGET_DIR)
    HOST_GID=$(stat -c "%g" $TARGET_DIR)

    # check if chid and chown are needed
    if [ "$CURRENT_UID:$CURRENT_GID" != "$HOST_UID:$HOST_GID" ]; then
        echo "[*] Current UID:GID ($CURRENT_UID:$CURRENT_GID) does not match host UID:GID ($HOST_UID:$HOST_GID) for $TARGET_DIR."

        echo "[*] Chowning /home/${USERNAME}..."
        chown -R "${USERNAME}:${GROUPNAME}" "/home/${USERNAME}"

        echo "[*] Changing user $USERNAME:$GROUPNAME to $HOST_UID:$HOST_GID..."
        usermod -u "$HOST_UID" "$USERNAME"
        groupmod -g "$HOST_GID" "$GROUPNAME"
    else
        echo "[*] User ID and group ID match. Continuing as $USERNAME."
    fi
else
    echo "[!] $TARGET_DIR is not mounted. Continuing as $USERNAME and chown $TARGET_DIR."
    chown -R "${USERNAME}:${GROUPNAME}" "${TARGET_DIR}"
fi

exec gosu "$USERNAME" "$@"
