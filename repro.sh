#!/bin/bash
# Starts Pest, kills the Playwright run-server mid-run, and reports whether the
# Pest process notices the closed connection or spins forever.
#
# usage: ./repro.sh <label> <kill-delay-seconds> [extra pest args...]
cd "$(dirname "$0")" || exit 1
LABEL="$1"; DELAY="$2"; shift 2
rm -f vendor/pestphp/pest-plugin-browser/.temp/playwright-server.json
set -m
./vendor/bin/pest "$@" >"/tmp/pest-repro-${LABEL}.log" 2>&1 &
PESTPID=$!
sleep "$DELAY"
if kill -0 $PESTPID 2>/dev/null; then
  pkill -f "playwright run-server" >/dev/null 2>&1 \
    && echo "run-server killed at t=${DELAY}s" \
    || echo "WARNING: no run-server running at t=${DELAY}s"
else
  echo "WARNING: pest already exited before t=${DELAY}s (window too short)"
fi
verdict="HANG"
for t in $(seq 1 12); do
  sleep 5
  if ! kill -0 $PESTPID 2>/dev/null; then
    verdict="EXITED ~$((DELAY + t*5))s after start"
    break
  fi
  if [ $((t % 4)) -eq 0 ]; then
    echo "  t=$((DELAY + t*5))s alive cpu=$(ps -o %cpu= -p $PESTPID | tr -d ' ')% stat=$(ps -o stat= -p $PESTPID | tr -d ' ')"
  fi
done
if kill -0 $PESTPID 2>/dev/null; then
  kill -KILL -$PESTPID 2>/dev/null; kill -KILL $PESTPID 2>/dev/null
fi
wait $PESTPID 2>/dev/null
pkill -f "playwright run-server" >/dev/null 2>&1
echo "VERDICT[$LABEL]: $verdict"
echo "--- last output ---"
tail -4 "/tmp/pest-repro-${LABEL}.log"
