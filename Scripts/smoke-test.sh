#!/bin/bash
# Local smoke test for Boo: drops test files into ~/Downloads and checks that
# the running app sorts each one into the right folder. Usage:
#   bash Scripts/smoke-test.sh
set -u

DL="$HOME/Downloads"
TS="bootest-$(date +%s)"
TIMEOUT=45

# "ext:ExpectedFolder" pairs, one per built-in category worth checking.
CASES="png:Images jpg:Images pdf:Documents txt:Documents zip:Archives mp3:Audio mp4:Video csv:Spreadsheets"

if ! pgrep -xq Boo; then
  echo "Boo is not running - launching /Applications/Boo.app ..."
  open -a /Applications/Boo.app || { echo "FAIL: could not launch Boo"; exit 1; }
  echo ">>> If macOS asks for Downloads access, click Allow. <<<"
  sleep 3
fi

echo "Creating test files in $DL ..."
for c in $CASES; do
  ext="${c%%:*}"
  printf 'boo smoke test\n' > "$DL/$TS.$ext"
done

echo "Waiting for Boo to sort (up to ${TIMEOUT}s; Boo waits ~6s for fresh files to settle) ..."
echo

pass=0
fail=0
start=$(date +%s)

for c in $CASES; do
  ext="${c%%:*}"
  folder="${c##*:}"
  file="$TS.$ext"
  ok=""
  while :; do
    if [ -f "$DL/$folder/$file" ]; then ok=yes; break; fi
    now=$(date +%s)
    [ $((now - start)) -ge "$TIMEOUT" ] && break
    sleep 1
  done
  if [ -n "$ok" ]; then
    echo "  PASS  .$ext -> $folder/"
    pass=$((pass + 1))
    rm -f "$DL/$folder/$file"
  else
    echo "  FAIL  .$ext  (still in Downloads or missing)"
    fail=$((fail + 1))
    rm -f "$DL/$file"
  fi
done

echo
echo "Result: $pass passed, $fail failed"
if [ "$fail" -eq 0 ]; then
  echo "All good - Boo is eating properly."
else
  echo "Something is off. Check the ghost menu: if it says"
  echo "\"Boo can't see Downloads\", click it and allow access, then re-run."
fi
exit "$fail"
