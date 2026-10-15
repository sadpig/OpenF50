#!/bin/sh
# Build openf50-hfp as a static arm64 binary (no libbluetooth needed: it uses the kernel's Bluetooth sockets directly).
#   tools/hfp/build.sh [OUT]      default: tools/hfp/openf50-hfp    - install it as /opt/openf50/bin/openf50-hfp
set -eu
HERE=$(cd "$(dirname "$0")" && pwd); OUT=${1:-$HERE/openf50-hfp}
docker run --rm --platform linux/arm64 -v "$HERE":/w alpine sh -c \
  'apk add -q gcc musl-dev linux-headers && gcc -Wall -O2 -static -o /w/openf50-hfp.out /w/openf50-hfp.c'
mv "$HERE/openf50-hfp.out" "$OUT"; echo "built $OUT"
