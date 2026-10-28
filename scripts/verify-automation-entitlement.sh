#!/bin/bash
set -euo pipefail
app=${1:?Pass the signed app bundle path}
entitlements=$(mktemp)
trap 'rm -f "$entitlements"' EXIT
codesign --display --entitlements - --xml "$app" > "$entitlements"
python3 - "$entitlements" <<'CHECK'
import plistlib
import sys
try:
    with open(sys.argv[1], "rb") as source:
        entitlements = plistlib.load(source)
except (plistlib.InvalidFileException, ValueError):
    sys.exit("FinderOne has no valid signed entitlements; Apple Events access will be blocked.")
if entitlements.get("com.apple.security.automation.apple-events") is not True:
    sys.exit("FinderOne is missing the Apple Events entitlement required to control Finder.")
CHECK
