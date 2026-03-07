#!/bin/bash
#
# uninstall.sh
# CNUAdminManager Uninstall Script
#
# Use this script (via Jamf policy) to remove the tool when
# the device falls out of the smart group scope (i.e., user
# is no longer an admin and has been remediated).
#

INSTALL_BASE="/Library/Application Support/CNUAdminManager"
APP_PATH="${INSTALL_BASE}/CNUAdminManager.app"
HELPER_PATH="/Library/PrivilegedHelperTools/com.cnu.adminmanager.helper"
DAEMON_PLIST="/Library/LaunchDaemons/com.cnu.adminmanager.helper.plist"
AGENT_PLIST="/Library/LaunchAgents/com.cnu.adminmanager.plist"
AUDIT_LOG="/Library/Logs/CNUAdminManager.log"
HELPER_LOG="/Library/Logs/CNUAdminManager-helper.log"
HELPER_ERR_LOG="/Library/Logs/CNUAdminManager-helper-error.log"

echo "CNUAdminManager: Starting uninstall..."

# ─── Stop LaunchDaemon ──────────────────────────────────────────
if [ -f "${DAEMON_PLIST}" ]; then
    echo "CNUAdminManager: Unloading LaunchDaemon..."
    /bin/launchctl bootout system "${DAEMON_PLIST}" 2>/dev/null
fi

# ─── Stop LaunchAgent ───────────────────────────────────────────
CONSOLE_USER=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ { print $3 }')
CONSOLE_UID=$(/usr/bin/id -u "${CONSOLE_USER}" 2>/dev/null)

if [ -n "${CONSOLE_USER}" ] && [ "${CONSOLE_USER}" != "loginwindow" ] && [ -n "${CONSOLE_UID}" ]; then
    echo "CNUAdminManager: Unloading LaunchAgent for ${CONSOLE_USER}..."
    /bin/launchctl bootout gui/"${CONSOLE_UID}" "${AGENT_PLIST}" 2>/dev/null
    /usr/bin/killall "CNUAdminManager" 2>/dev/null
fi

# ─── Remove files ───────────────────────────────────────────────
echo "CNUAdminManager: Removing files..."

rm -rf "${APP_PATH}"
rm -f "${HELPER_PATH}"
rm -f "${DAEMON_PLIST}"
rm -f "${AGENT_PLIST}"
rm -rf "${INSTALL_BASE}"

# Optionally preserve logs (comment out to delete)
# rm -f "${AUDIT_LOG}"
# rm -f "${HELPER_LOG}"
# rm -f "${HELPER_ERR_LOG}"

echo "CNUAdminManager: Uninstall complete"
exit 0
