#!/bin/bash
#
# uninstall.sh
# AdminRightsManager Uninstall Script
#
# Use this script (via Jamf policy) to remove the tool when
# the device falls out of the smart group scope (i.e., user
# is no longer an admin and has been remediated).
#

INSTALL_BASE="/Library/Application Support/AdminRightsManager"
APP_PATH="${INSTALL_BASE}/AdminRightsManager.app"
HELPER_PATH="/Library/PrivilegedHelperTools/com.adminrights.manager.helper"
DAEMON_PLIST="/Library/LaunchDaemons/com.adminrights.manager.helper.plist"
AGENT_PLIST="/Library/LaunchAgents/com.adminrights.manager.plist"
AUDIT_LOG="/Library/Logs/AdminRightsManager.log"
HELPER_LOG="/Library/Logs/AdminRightsManager-helper.log"
HELPER_ERR_LOG="/Library/Logs/AdminRightsManager-helper-error.log"

echo "AdminRightsManager: Starting uninstall..."

# ─── Stop LaunchDaemon ──────────────────────────────────────────
if [ -f "${DAEMON_PLIST}" ]; then
    echo "AdminRightsManager: Unloading LaunchDaemon..."
    /bin/launchctl bootout system "${DAEMON_PLIST}" 2>/dev/null
fi

# ─── Stop LaunchAgent ───────────────────────────────────────────
CONSOLE_USER=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ { print $3 }')
CONSOLE_UID=$(/usr/bin/id -u "${CONSOLE_USER}" 2>/dev/null)

if [ -n "${CONSOLE_USER}" ] && [ "${CONSOLE_USER}" != "loginwindow" ] && [ -n "${CONSOLE_UID}" ]; then
    echo "AdminRightsManager: Unloading LaunchAgent for ${CONSOLE_USER}..."
    /bin/launchctl bootout gui/"${CONSOLE_UID}" "${AGENT_PLIST}" 2>/dev/null
    /usr/bin/killall "AdminRightsManager" 2>/dev/null
fi

# ─── Remove files ───────────────────────────────────────────────
echo "AdminRightsManager: Removing files..."

rm -rf "${APP_PATH}"
rm -f "${HELPER_PATH}"
rm -f "${DAEMON_PLIST}"
rm -f "${AGENT_PLIST}"
rm -rf "${INSTALL_BASE}"

# Optionally preserve logs (comment out to delete)
# rm -f "${AUDIT_LOG}"
# rm -f "${HELPER_LOG}"
# rm -f "${HELPER_ERR_LOG}"

echo "AdminRightsManager: Uninstall complete"
exit 0
