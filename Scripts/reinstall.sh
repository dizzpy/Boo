#!/bin/bash
# Rebuilds Boo from source and reinstalls it over whatever is in /Applications.
# For local dev/testing only. Usage:
#   bash Scripts/reinstall.sh          # rebuild + reinstall
#   bash Scripts/reinstall.sh --fresh  # also reset the Downloads permission
#                                       # prompt, as if this were a first install
set -euo pipefail

APP="/Applications/Boo.app"
FRESH=0
[ "${1:-}" = "--fresh" ] && FRESH=1

echo "==> Quitting any running Boo..."
pkill -x Boo 2>/dev/null || true
sleep 1

echo "==> Building Boo.app ..."
bash make-app.sh

echo "==> Replacing $APP ..."
rm -rf "$APP"
cp -R Boo.app "$APP"
rm -rf Boo.app Boo.dmg

if [ "$FRESH" -eq 1 ]; then
  echo "==> Resetting Downloads permission (macOS will prompt again) ..."
  tccutil reset SystemPolicyDownloadsFolder co.dizzpy.boo 2>/dev/null || true
fi

echo "==> Verifying signature ..."
codesign --verify --strict "$APP"

echo "==> Launching Boo ..."
open "$APP"

echo
echo "Done. New version installed and running."
[ "$FRESH" -eq 1 ] && echo "Click Allow if macOS asks for Downloads access."
echo "Run 'bash Scripts/smoke-test.sh' to verify sorting works."
