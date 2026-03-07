#!/bin/bash
#
# preinstall.sh
# AdminRightsManager PKG Preinstall Script
#
# Handles cleanup of any existing installation before upgrade.
#

DAEMON_PLIST="/Library/LaunchDaemons/com.adminrights.manager.helper.plist"
AGENT_PLIST="/Library/LaunchAgents/com.adminrights.manager.plist"

echo "AdminRightsManager: Starting preinstall..."

# ─── Stop existing LaunchDaemon ─────────────────────────────────
if [ -f "${DAEMON_PLIST}" ]; then
    echo "AdminRightsManager: Unloading existing LaunchDaemon..."
    /bin/launchctl bootout system "${DAEMON_PLIST}" 2>/dev/null
fi

# ─── Stop existing LaunchAgent for current user ─────────────────
CONSOLE_USER=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ { print $3 }')
CONSOLE_UID=$(/usr/bin/id -u "${CONSOLE_USER}" 2>/dev/null)

if [ -n "${CONSOLE_USER}" ] && [ "${CONSOLE_USER}" != "loginwindow" ] && [ -n "${CONSOLE_UID}" ]; then
    if [ -f "${AGENT_PLIST}" ]; then
        echo "AdminRightsManager: Unloading existing LaunchAgent for ${CONSOLE_USER}..."
        /bin/launchctl bootout gui/"${CONSOLE_UID}" "${AGENT_PLIST}" 2>/dev/null
    fi

    # Kill the app if it's running
    /usr/bin/killall "AdminRightsManager" 2>/dev/null
fi

echo "AdminRightsManager: Preinstall complete"
exit 0
