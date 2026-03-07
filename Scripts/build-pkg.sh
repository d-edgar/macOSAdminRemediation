#!/bin/bash
#
# build-pkg.sh
# Builds the AdminRightsManager distribution PKG for deployment via Jamf Pro.
#
# Prerequisites:
#   1. Build the app in Xcode (Release configuration)
#   2. Build the helper tool in Xcode (Release configuration)
#   3. Run this script from the project root
#
# Usage:
#   ./Scripts/build-pkg.sh [version]
#   ./Scripts/build-pkg.sh 1.0.0
#

set -e

# ─── Configuration ──────────────────────────────────────────────
VERSION="${1:-1.0.0}"
PKG_IDENTIFIER="com.adminrights.manager"
PKG_NAME="AdminRightsManager-${VERSION}.pkg"
BUILD_DIR="./build/pkg-root"
SCRIPTS_DIR="./build/pkg-scripts"
OUTPUT_DIR="./build"

XCODE_BUILD_DIR="./build/Release"  # Adjust if your Xcode build output differs

echo "========================================="
echo " AdminRightsManager PKG Builder v${VERSION}"
echo "========================================="

# ─── Clean and prepare ──────────────────────────────────────────
echo "Preparing build directories..."
rm -rf "${BUILD_DIR}" "${SCRIPTS_DIR}"
mkdir -p "${BUILD_DIR}/Library/Application Support/AdminRightsManager"
mkdir -p "${BUILD_DIR}/Library/PrivilegedHelperTools"
mkdir -p "${BUILD_DIR}/Library/LaunchDaemons"
mkdir -p "${BUILD_DIR}/Library/LaunchAgents"
mkdir -p "${SCRIPTS_DIR}"

# ─── Copy app bundle ────────────────────────────────────────────
echo "Copying app bundle..."
if [ -d "${XCODE_BUILD_DIR}/AdminRightsManager.app" ]; then
    cp -R "${XCODE_BUILD_DIR}/AdminRightsManager.app" \
        "${BUILD_DIR}/Library/Application Support/AdminRightsManager/"
else
    echo "ERROR: App bundle not found at ${XCODE_BUILD_DIR}/AdminRightsManager.app"
    echo "       Build the app in Xcode first (Product > Build, Release configuration)"
    exit 1
fi

# ─── Copy privileged helper ─────────────────────────────────────
echo "Copying privileged helper..."
if [ -f "${XCODE_BUILD_DIR}/com.adminrights.manager.helper" ]; then
    cp "${XCODE_BUILD_DIR}/com.adminrights.manager.helper" \
        "${BUILD_DIR}/Library/PrivilegedHelperTools/"
else
    echo "ERROR: Helper tool not found at ${XCODE_BUILD_DIR}/com.adminrights.manager.helper"
    echo "       Build the helper target in Xcode first"
    exit 1
fi

# ─── Copy LaunchDaemon plist ────────────────────────────────────
echo "Copying LaunchDaemon plist..."
cp "./AdminRightsHelper/com.adminrights.manager.helper.plist" \
    "${BUILD_DIR}/Library/LaunchDaemons/"

# ─── Copy LaunchAgent plist ─────────────────────────────────────
echo "Copying LaunchAgent plist..."
cp "./LaunchAgent/com.adminrights.manager.plist" \
    "${BUILD_DIR}/Library/LaunchAgents/"

# ─── Copy install scripts ──────────────────────────────────────
echo "Copying install scripts..."
cp "./Scripts/preinstall.sh" "${SCRIPTS_DIR}/preinstall"
cp "./Scripts/postinstall.sh" "${SCRIPTS_DIR}/postinstall"
chmod +x "${SCRIPTS_DIR}/preinstall"
chmod +x "${SCRIPTS_DIR}/postinstall"

# ─── Build component PKG ───────────────────────────────────────
echo "Building component package..."
pkgbuild \
    --root "${BUILD_DIR}" \
    --identifier "${PKG_IDENTIFIER}" \
    --version "${VERSION}" \
    --scripts "${SCRIPTS_DIR}" \
    --ownership recommended \
    "${OUTPUT_DIR}/AdminRightsManager-component.pkg"

# ─── Build distribution PKG (optional, for better Jamf compatibility) ───
echo "Building distribution package..."
productbuild \
    --package "${OUTPUT_DIR}/AdminRightsManager-component.pkg" \
    --identifier "${PKG_IDENTIFIER}" \
    --version "${VERSION}" \
    "${OUTPUT_DIR}/${PKG_NAME}"

# ─── Clean up intermediate files ────────────────────────────────
rm -f "${OUTPUT_DIR}/AdminRightsManager-component.pkg"

echo ""
echo "========================================="
echo " PKG built successfully!"
echo " Output: ${OUTPUT_DIR}/${PKG_NAME}"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Upload ${PKG_NAME} to Jamf Pro"
echo "  2. Create a policy scoped to your admin users smart group"
echo "  3. Deploy the config profile (ConfigProfile/com.adminrights.manager.mobileconfig)"
echo "  4. Create an uninstall policy scoped to the remediated smart group"
echo "     using Scripts/uninstall.sh"
