#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

TEAM_ID="${TEAM_ID:-YH8992LT9F}"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Clarence Johnson (YH8992LT9F)}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-AC_PROFILE}"

NOTARY_WAIT_TIMEOUT="${NOTARY_WAIT_TIMEOUT:-20m}"

BUILD_ROOT="${BUILD_ROOT:-${ROOT_DIR}/Neatlify Desktop/build/notary-smoke}"
LOG_DIR="${BUILD_ROOT}/logs"

APP_NAME="Notary Smoke Test.app"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-com.neatlify.desktop.notarysmoketest}"
VOL_NAME="Notary Smoke Test"

APP_DIR="${BUILD_ROOT}/${APP_NAME}"
APP_BIN="${APP_DIR}/Contents/MacOS/NotarySmokeTest"
APP_PLIST="${APP_DIR}/Contents/Info.plist"

STAGING_DIR="${BUILD_ROOT}/dmg-staging"
DMG_PATH="${BUILD_ROOT}/Notary-Smoke-Test.dmg"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required tool: $1"
}

clean() {
  /bin/rm -rf "${BUILD_ROOT}"
  /bin/mkdir -p "${LOG_DIR}"
}

create_app_bundle() {
  log "Build: minimal universal app bundle"

  /bin/mkdir -p "${APP_DIR}/Contents/MacOS"

  cat > "${BUILD_ROOT}/main.c" <<'EOF'
#include <stdio.h>
int main(void) {
  puts("Notary smoke test OK");
  return 0;
}
EOF

  /usr/bin/cc -arch arm64 -arch x86_64 "${BUILD_ROOT}/main.c" -o "${APP_BIN}" 2>&1 | /usr/bin/tee "${LOG_DIR}/cc.log"
  /bin/chmod 755 "${APP_BIN}"

  cat > "${APP_PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>NotarySmokeTest</string>
  <key>CFBundleIdentifier</key>
  <string>${APP_BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Notary Smoke Test</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
</dict>
</plist>
EOF
}

sign_and_verify_app() {
  log "Sign: app (Developer ID + hardened runtime + timestamp)"
  /usr/bin/codesign --force --sign "${SIGN_IDENTITY}" --timestamp --options runtime "${APP_DIR}" 2>&1 | /usr/bin/tee "${LOG_DIR}/codesign-sign-app.log"
  /usr/bin/codesign --verify --deep --strict --verbose=4 "${APP_DIR}" 2>&1 | /usr/bin/tee "${LOG_DIR}/codesign-verify-app.log"
  /usr/bin/codesign -dv --verbose=4 "${APP_DIR}" 2>&1 | /usr/bin/tee "${LOG_DIR}/codesign-details-app.log"

  if ! /usr/bin/grep -Fq "Authority=Developer ID Application" "${LOG_DIR}/codesign-details-app.log"; then
    die "Smoke app not Developer ID signed. See: ${LOG_DIR}/codesign-details-app.log"
  fi
  if ! /usr/bin/grep -Fq "TeamIdentifier=${TEAM_ID}" "${LOG_DIR}/codesign-details-app.log"; then
    die "Smoke app TeamIdentifier mismatch. See: ${LOG_DIR}/codesign-details-app.log"
  fi
  if ! /usr/bin/grep -q "^Timestamp=" "${LOG_DIR}/codesign-details-app.log"; then
    die "Smoke app signature missing timestamp. See: ${LOG_DIR}/codesign-details-app.log"
  fi
}

build_and_sign_dmg() {
  log "Package: DMG (UDZO, read-only)"

  /bin/rm -rf "${STAGING_DIR}"
  /bin/mkdir -p "${STAGING_DIR}"
  /usr/bin/ditto "${APP_DIR}" "${STAGING_DIR}/${APP_NAME}"
  /bin/ln -sf /Applications "${STAGING_DIR}/Applications"

  /usr/bin/hdiutil create \
    -volname "${VOL_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "${DMG_PATH}" \
    2>&1 | /usr/bin/tee "${LOG_DIR}/hdiutil-create-dmg.log"

  log "Sign: DMG"
  /usr/bin/codesign --force --sign "${SIGN_IDENTITY}" --timestamp "${DMG_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/codesign-sign-dmg.log"
  /usr/bin/codesign --verify --deep --strict --verbose=4 "${DMG_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/codesign-verify-dmg.log"
  /usr/bin/codesign -dv --verbose=4 "${DMG_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/codesign-details-dmg.log"
}

notarize_and_staple() {
  log "Notarize: submit"
  local submit_json
  submit_json="$(/usr/bin/xcrun notarytool submit "${DMG_PATH}" --keychain-profile "${KEYCHAIN_PROFILE}" --output-format json 2>&1 | /usr/bin/tee "${LOG_DIR}/notary-submit.json")"

  local submission_id
  submission_id="$(/usr/bin/python3 -c 'import json,sys; raw=sys.stdin.read(); start=raw.rfind("{"); print((json.loads(raw[start:]).get("id","")) if start!=-1 else "")' <<<"${submit_json}")"
  [[ -n "${submission_id}" ]] || die "Unable to parse submission id. See: ${LOG_DIR}/notary-submit.json"
  echo "${submission_id}" > "${LOG_DIR}/notary-submission-id.txt"
  log "Notarize: submission id = ${submission_id}"

  log "Notarize: wait (timeout ${NOTARY_WAIT_TIMEOUT})"
  /usr/bin/xcrun notarytool wait "${submission_id}" --keychain-profile "${KEYCHAIN_PROFILE}" --timeout "${NOTARY_WAIT_TIMEOUT}" --output-format json 2>&1 | /usr/bin/tee "${LOG_DIR}/notary-wait.json"

  local status
  status="$(/usr/bin/python3 -c 'import json,sys; raw=sys.stdin.read(); start=raw.rfind("{"); print((json.loads(raw[start:]).get("status","")) if start!=-1 else "")' < "${LOG_DIR}/notary-wait.json")"
  if [[ "${status}" != "Accepted" ]]; then
    /usr/bin/xcrun notarytool log --keychain-profile "${KEYCHAIN_PROFILE}" "${submission_id}" > "${LOG_DIR}/notary-log.json" 2>&1 || true
    die "Notarize: status=${status}. See: ${LOG_DIR}/notary-log.json"
  fi

  /usr/bin/xcrun notarytool log --keychain-profile "${KEYCHAIN_PROFILE}" "${submission_id}" > "${LOG_DIR}/notary-log.json" 2>&1 || true

  log "Staple: DMG"
  /usr/bin/xcrun stapler staple -v "${DMG_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/stapler-staple.log"
  /usr/bin/xcrun stapler validate -v "${DMG_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/stapler-validate.log"
}

main() {
  require_tool cc
  require_tool codesign
  require_tool ditto
  require_tool hdiutil
  require_tool python3
  require_tool xcrun

  clean
  create_app_bundle
  sign_and_verify_app
  build_and_sign_dmg
  notarize_and_staple

  log "Done"
  log "Smoke DMG: ${DMG_PATH}"
}

main "$@"
