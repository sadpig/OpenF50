#!/bin/sh
# Build openf50_peek.ko against the same kernel kernel/build-all.sh builds.
#   tools/openf50-peek/build.sh [OUT]      default: work/k54/openf50_peek.ko
set -eu
TOP=$(cd "$(dirname "$0")/../.." && pwd)
OUT=${1:-$TOP/work/k54}
docker build -q -t openf50-kbuild "$TOP/kernel" >/dev/null
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
cp "$TOP/tools/openf50-peek/openf50_peek.c" "$TOP/tools/openf50-peek/Kbuild" "$W/"
docker run --rm -v openf50-kernel:/src -v "$W":/work openf50-kbuild bash -euc '
cd /src/zte-u30air
make O=/src/out-linux ARCH=arm64 LLVM=1 LLVM_IAS=1 CC=clang LD=ld.lld -j"$(nproc)" M=/work modules >/tmp/b.log 2>&1 ||
    { tail -20 /tmp/b.log; exit 1; }'
mkdir -p "$OUT"; cp "$W/openf50_peek.ko" "$OUT/"
echo "$OUT/openf50_peek.ko"
