#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
XCODE_DIR="${ROOT_DIR}/Neatlify Desktop"
PROJECT_PATH="${XCODE_DIR}/Neatlify Desktop.xcodeproj"
SCHEME="${SCHEME:-Neatlify Desktop DMG}"
CONFIGURATION="${CONFIGURATION:-Release}"

BUNDLE_ID_EXPECTED="${BUNDLE_ID_EXPECTED:-com.neatlify.desktop}"
TEAM_ID="${TEAM_ID:-YH8992LT9F}"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Clarence Johnson (YH8992LT9F)}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-AC_PROFILE}"

UNIVERSAL_BINARIES="${UNIVERSAL_BINARIES:-1}"
NOTARY_WAIT_MAX_SECONDS="${NOTARY_WAIT_MAX_SECONDS:-5400}" # 90 minutes

BUILD_ROOT="${XCODE_DIR}/build/release"
DERIVED_DATA_PATH="${BUILD_ROOT}/DerivedData"
ARCHIVE_PATH="${BUILD_ROOT}/Neatlify Desktop.xcarchive"
EXPORT_PATH="${BUILD_ROOT}/export"
EXPORT_OPTIONS_PLIST="${XCODE_DIR}/export-options.plist"
STAGING_DIR="${BUILD_ROOT}/dmg-staging"
DMG_PATH="${BUILD_ROOT}/Neatlify-Desktop.dmg"
LOG_DIR="${BUILD_ROOT}/logs"

APP_NAME="Neatlify Desktop.app"
EXPORTED_APP_PATH="${EXPORT_PATH}/${APP_NAME}"
EXPORTED_APP_BIN="${EXPORTED_APP_PATH}/Contents/MacOS/Neatlify Desktop"

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

preflight_repo_state() {
  log "Preflight: repo state"

  local info_plist="${XCODE_DIR}/Info.plist"
  [[ -f "${info_plist}" ]] || die "Missing Info.plist at: ${info_plist}"

  local bundle_id
  bundle_id="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "${info_plist}" 2>/dev/null || true)"
  [[ -n "${bundle_id}" ]] || die "Info.plist CFBundleIdentifier missing or unreadable"
  [[ "${bundle_id}" == "${BUNDLE_ID_EXPECTED}" ]] || die "Info.plist CFBundleIdentifier is '${bundle_id}' (expected '${BUNDLE_ID_EXPECTED}')"

  local bundle_id_key_count
  bundle_id_key_count="$(/usr/bin/grep -c "<key>CFBundleIdentifier</key>" "${info_plist}" || true)"
  [[ "${bundle_id_key_count}" -eq 1 ]] || die "Info.plist contains ${bundle_id_key_count} CFBundleIdentifier keys (expected exactly 1)"

  local ent_app="${XCODE_DIR}/Neatlify Desktop/Neatlify_Desktop.entitlements"
  local ent_dmg="${XCODE_DIR}/Neatlify Desktop/Neatlify_Desktop_DMG.entitlements"
  [[ -f "${ent_app}" ]] || die "Missing entitlements: ${ent_app}"
  [[ -f "${ent_dmg}" ]] || die "Missing entitlements: ${ent_dmg}"

  if /usr/bin/grep -q "com.apple.security.hardened-runtime" "${ent_app}" "${ent_dmg}"; then
    die "Invalid entitlement key present: com.apple.security.hardened-runtime"
  fi
}

preflight_signing() {
  log "Preflight: signing identity + notarization profile"

  # Identity must be present for Xcode to produce Developer ID signed exports.
  if ! /usr/bin/security find-identity -v -p codesigning 2>/dev/null | /usr/bin/grep -Fq "${SIGN_IDENTITY}"; then
    /usr/bin/security find-identity -v -p codesigning || true
    die "Signing identity not found in keychain: ${SIGN_IDENTITY}"
  fi

  # Quick credential sanity check (non-fatal if Apple is unreachable; submit will fail anyway).
  /usr/bin/xcrun notarytool history --keychain-profile "${KEYCHAIN_PROFILE}" --output-format json >/dev/null 2>&1 || \
    die "Notarytool keychain profile '${KEYCHAIN_PROFILE}' is not usable. Recreate it with: xcrun notarytool store-credentials ${KEYCHAIN_PROFILE}"
}

clean_build_root() {
  log "Cleaning build output: ${BUILD_ROOT}"
  /bin/rm -rf "${BUILD_ROOT}"
  /bin/mkdir -p "${EXPORT_PATH}" "${LOG_DIR}"
}

archive_app() {
  log "Archive: ${SCHEME} (${CONFIGURATION})"

  local extra_args=()
  if [[ "${UNIVERSAL_BINARIES}" == "1" ]]; then
    extra_args+=(ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO)
  fi

  /usr/bin/xcodebuild archive \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -destination "generic/platform=macOS" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -archivePath "${ARCHIVE_PATH}" \
    "${extra_args[@]}" \
    2>&1 | /usr/bin/tee "${LOG_DIR}/xcodebuild-archive.log"
}

export_app() {
  log "Export: Developer ID distribution"
  [[ -f "${EXPORT_OPTIONS_PLIST}" ]] || die "Missing export options: ${EXPORT_OPTIONS_PLIST}"

  /usr/bin/xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}" \
    2>&1 | /usr/bin/tee "${LOG_DIR}/xcodebuild-export.log"

  [[ -d "${EXPORTED_APP_PATH}" ]] || die "Export did not produce app at: ${EXPORTED_APP_PATH}"
  [[ -f "${EXPORTED_APP_BIN}" ]] || die "Exported app binary missing: ${EXPORTED_APP_BIN}"
}

verify_app_signature() {
  log "Verify: app signature"

  /usr/bin/codesign --verify --deep --strict --verbose=4 "${EXPORTED_APP_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/codesign-verify-app.log"
  /usr/bin/codesign -dv --verbose=4 "${EXPORTED_APP_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/codesign-details-app.log"

  local id
  id="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "${EXPORTED_APP_PATH}/Contents/Info.plist" 2>/dev/null || true)"
  [[ "${id}" == "${BUNDLE_ID_EXPECTED}" ]] || die "Exported app CFBundleIdentifier is '${id}' (expected '${BUNDLE_ID_EXPECTED}')"

  if ! /usr/bin/grep -Fq "Authority=Developer ID Application" "${LOG_DIR}/codesign-details-app.log"; then
    die "Exported app is not Developer ID signed (Authority chain missing). See: ${LOG_DIR}/codesign-details-app.log"
  fi
  if ! /usr/bin/grep -Fq "TeamIdentifier=${TEAM_ID}" "${LOG_DIR}/codesign-details-app.log"; then
    die "Exported app TeamIdentifier is not '${TEAM_ID}'. See: ${LOG_DIR}/codesign-details-app.log"
  fi
  if ! /usr/bin/grep -q "^Timestamp=" "${LOG_DIR}/codesign-details-app.log"; then
    die "Exported app signature is missing a secure timestamp. See: ${LOG_DIR}/codesign-details-app.log"
  fi

  if [[ "${UNIVERSAL_BINARIES}" == "1" ]]; then
    local archs
    archs="$(/usr/bin/lipo -archs "${EXPORTED_APP_BIN}" 2>/dev/null || true)"
    [[ "${archs}" == *"arm64"* && "${archs}" == *"x86_64"* ]] || die "Exported app is not universal (archs: '${archs}')."
  fi

  # Pre-notarization, Gatekeeper is expected to reject with "source=Unnotarized Developer ID".
  # We'll re-check after stapling.
  /usr/sbin/spctl -a -vv -t exec "${EXPORTED_APP_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/spctl-app-pre-notary.log" || true
}

build_dmg() {
  log "Package: DMG (UDZO, read-only)"

  /bin/rm -rf "${STAGING_DIR}"
  /bin/mkdir -p "${STAGING_DIR}"

  /usr/bin/ditto "${EXPORTED_APP_PATH}" "${STAGING_DIR}/${APP_NAME}"
  /bin/ln -sf /Applications "${STAGING_DIR}/Applications"

  /usr/bin/hdiutil create \
    -volname "Neatlify Desktop" \
    -srcfolder "${STAGING_DIR}" \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "${DMG_PATH}" \
    2>&1 | /usr/bin/tee "${LOG_DIR}/hdiutil-create-dmg.log"

  /usr/bin/file "${DMG_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/file-dmg.log"
}

sign_and_verify_dmg() {
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
  [[ -n "${submission_id}" ]] || die "Unable to parse notarization submission id. See: ${LOG_DIR}/notary-submit.json"
  echo "${submission_id}" > "${LOG_DIR}/notary-submission-id.txt"
  log "Notarize: submission id = ${submission_id}"

  log "Notarize: polling (max ${NOTARY_WAIT_MAX_SECONDS}s)"
  local start_epoch
  start_epoch="$(/bin/date +%s)"
  local attempt=0
  while true; do
    attempt=$((attempt + 1))

    local info_json
    info_json="$(/usr/bin/xcrun notarytool info "${submission_id}" --keychain-profile "${KEYCHAIN_PROFILE}" --output-format json 2>&1)"
    printf '%s\n' "${info_json}" > "${LOG_DIR}/notary-info-latest.json"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${info_json}" >> "${LOG_DIR}/notary-info-history.log"

    local status
    status="$(/usr/bin/python3 -c 'import json,sys; raw=sys.stdin.read(); start=raw.rfind("{"); print((json.loads(raw[start:]).get("status","")) if start!=-1 else "")' <<<"${info_json}")"

    if [[ "${status}" == "Accepted" ]]; then
      log "Notarize: Accepted"
      break
    fi
    if [[ "${status}" == "Invalid" ]]; then
      /usr/bin/xcrun notarytool log "${submission_id}" --keychain-profile "${KEYCHAIN_PROFILE}" > "${LOG_DIR}/notary-log.json" 2>&1 || true
      die "Notarize: Invalid. See: ${LOG_DIR}/notary-log.json"
    fi

    local now_epoch
    now_epoch="$(/bin/date +%s)"
    local elapsed=$((now_epoch - start_epoch))
    if (( elapsed > NOTARY_WAIT_MAX_SECONDS )); then
      log "Notarize: still processing after ${elapsed}s"
      log "Notarize: check status later with:"
      log "  xcrun notarytool info ${submission_id} --keychain-profile ${KEYCHAIN_PROFILE} --output-format json"
      die "Notarize: timed out waiting for completion (submission id: ${submission_id})"
    fi

    # Backoff: 20s for first 5 minutes, then 60s.
    if (( elapsed < 300 )); then
      /bin/sleep 20
    else
      /bin/sleep 60
    fi
  done

  /usr/bin/xcrun notarytool log "${submission_id}" --keychain-profile "${KEYCHAIN_PROFILE}" > "${LOG_DIR}/notary-log.json" 2>&1 || true

  log "Staple: DMG"
  /usr/bin/xcrun stapler staple -v "${DMG_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/stapler-staple.log"
  /usr/bin/xcrun stapler validate -v "${DMG_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/stapler-validate.log"

  # Optional but helpful: staple/validate the exported app too (offline-friendly),
  # even though the DMG is already stapled.
  log "Staple: app"
  /usr/bin/xcrun stapler staple -v "${EXPORTED_APP_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/stapler-staple-app.log"
  /usr/bin/xcrun stapler validate -v "${EXPORTED_APP_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/stapler-validate-app.log"
  /usr/sbin/spctl -a -vv -t exec "${EXPORTED_APP_PATH}" 2>&1 | /usr/bin/tee "${LOG_DIR}/spctl-app-post-notary.log" || true
}

main() {
  require_tool xcodebuild
  require_tool codesign
  require_tool hdiutil
  require_tool xcrun
  require_tool plutil
  require_tool python3
  require_tool ditto
  require_tool lipo
  require_tool spctl
  require_tool security

  preflight_repo_state
  preflight_signing

  clean_build_root
  archive_app
  export_app
  verify_app_signature
  build_dmg
  sign_and_verify_dmg
  notarize_and_staple

  log "Done"
  log "Notarized DMG: ${DMG_PATH}"
}

main "$@"
