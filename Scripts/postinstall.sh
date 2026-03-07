#!/bin/bash
#
# postinstall.sh
# CNUAdminManager PKG Postinstall Script
#
# This script runs after the PKG installs files to disk.
# It sets up the LaunchDaemon, LaunchAgent, and ensures
# correct permissions.
#

INSTALL_BASE="/Library/Application Support/CNUAdminManager"
APP_PATH="${INSTALL_BASE}/CNUAdminManager.app"
HELPER_PATH="/Library/PrivilegedHelperTools/com.cnu.adminmanager.helper"
DAEMON_PLIST="/Library/LaunchDaemons/com.cnu.adminmanager.helper.plist"
AGENT_PLIST="/Library/LaunchAgents/com.cnu.adminmanager.plist"
LOG_DIR="/Library/Logs"

echo "CNUAdminManager: Starting postinstall..."

# ─── Ensure directories exist ───────────────────────────────────
mkdir -p "${INSTALL_BASE}"
mkdir -p "/Library/PrivilegedHelperTools"

# ─── Set ownership and permissions ──────────────────────────────

# App bundle
chown -R root:wheel "${APP_PATH}"
chmod -R 755 "${APP_PATH}"

# Privileged helper
chown root:wheel "${HELPER_PATH}"
chmod 755 "${HELPER_PATH}"

# LaunchDaemon plist
chown root:wheel "${DAEMON_PLIST}"
chmod 644 "${DAEMON_PLIST}"

# LaunchAgent plist
chown root:wheel "${AGENT_PLIST}"
chmod 644 "${AGENT_PLIST}"

# Signal directory (needs to be writable by the app running as the user)
mkdir -p "${INSTALL_BASE}"
chmod 777 "${INSTALL_BASE}"

# ─── Load the LaunchDaemon (privileged helper) ──────────────────
echo "CNUAdminManager: Loading LaunchDaemon..."

# Unload first if already loaded (upgrade scenario)
/bin/launchctl bootout system "${DAEMON_PLIST}" 2>/dev/null

# Load the daemon
/bin/launchctl bootstrap system "${DAEMON_PLIST}"

if [ $? -eq 0 ]; then
    echo "CNUAdminManager: LaunchDaemon loaded successfully"
else
    echo "CNUAdminManager: WARNING - Failed to load LaunchDaemon"
fi

# ─── Load the LaunchAgent for the current console user ──────────
echo "CNUAdminManager: Loading LaunchAgent..."

CONSOLE_USER=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ { print $3 }')
CONSOLE_UID=$(/usr/bin/id -u "${CONSOLE_USER}" 2>/dev/null)

if [ -n "${CONSOLE_USER}" ] && [ "${CONSOLE_USER}" != "loginwindow" ] && [ -n "${CONSOLE_UID}" ]; then
    # Unload first if already loaded (upgrade scenario)
    /bin/launchctl bootout gui/"${CONSOLE_UID}" "${AGENT_PLIST}" 2>/dev/null

    # Load for current user
    /bin/launchctl bootstrap gui/"${CONSOLE_UID}" "${AGENT_PLIST}"

    if [ $? -eq 0 ]; then
        echo "CNUAdminManager: LaunchAgent loaded for user ${CONSOLE_USER} (UID ${CONSOLE_UID})"
    else
        echo "CNUAdminManager: WARNING - Failed to load LaunchAgent for ${CONSOLE_USER}"
    fi

    # Launch the app immediately for the first-run experience
    echo "CNUAdminManager: Launching app for first-run..."
    /usr/bin/sudo -u "${CONSOLE_USER}" /usr/bin/open "${APP_PATH}" &
else
    echo "CNUAdminManager: No console user detected. LaunchAgent will load at next login."
fi

echo "CNUAdminManager: Postinstall complete"
exit 0
