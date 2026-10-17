# tools/android-su.sh - shared "adb + su" plumbing for the host-side tools. Source, do not run.
#
# Magisk 26+ on SAR devices does not put su in PATH: it lives in /debug_ramdisk (this is also how a
# patched FLYMODEM B16 boot exposes it). Resolve the binary once here - OPENF50_SU_BIN overrides the
# auto-detection - and use su_do/dev_pull everywhere, so every script works the same on rooted B09,
# on Magisk'd stock and on a no-downgrade rooted B16.
#
# su_do CMD runs CMD as root and prints its stdout. adb shell reads stdin: it is always closed here,
# so answers piped or typed into the calling script survive.
# dev_pull DEVICE_PATH LOCAL_PATH copies a device-side file (may be a block device) to the host
# WITHOUT streaming it through adb: su may hand the command a pty whose tty layer rewrites every LF
# as CRLF, silently inflating the bytes (issue #2). The file is written on the device, then pulled.
if [ -z "${OPENF50_SU_BIN:-}" ]; then
    _openf50_su=$(adb shell 'command -v su 2>/dev/null || [ -x /debug_ramdisk/su ] && echo /debug_ramdisk/su' </dev/null 2>/dev/null | tr -d '\r' | tail -n 1)
    [ -n "$_openf50_su" ] && OPENF50_SU_BIN=$_openf50_su
fi
su_do() { adb shell "${OPENF50_SU_BIN:-su} -c '$1'" </dev/null | tr -d '\r'; }
dev_pull() {
    adb shell "${OPENF50_SU_BIN:-su} -c 'cat $1 > /data/local/tmp/openf50-pull.bin'" </dev/null >/dev/null
    adb pull /data/local/tmp/openf50-pull.bin "$2" >/dev/null 2>&1
    adb shell "${OPENF50_SU_BIN:-su} -c 'rm -f /data/local/tmp/openf50-pull.bin'" </dev/null >/dev/null
}
