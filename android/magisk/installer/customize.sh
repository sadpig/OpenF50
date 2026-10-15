# OPENF50 Linux installer zip. Magisk sources this file into its own installer shell, so it changes none of that
# shell's options and never exits: the installation runs as a child process (openf50/install.sh) under Magisk's
# busybox, and its exit status decides - 0 installed, 3 dry run, anything else not installed. Only after success
# does this zip become the "OPENF50 Linux" switch module (Action button, su -c openf50-linux). The three messages here
# stay English: they are shown before the installer knows the language.
SKIPUNZIP=1
if ! $BOOTMODE; then
    abort "! Install this zip in the Magisk app or with: magisk --install-module <zip> (not from recovery)"
fi
[ "${MAGISK_VER_CODE:-0}" -ge 26000 ] || abort "! This zip needs Magisk 26.0 or newer"
# Everything taken from the zip comes out of it here, once: the zip may lie on /sdcard, where any app can replace it
# while the installation runs, and the module's files (system/* among them) run as root later.
openf50_x=$TMPDIR/openf50-zip
rm -rf "$openf50_x"
unzip -o -q "$ZIPFILE" 'openf50/*' module.prop action.sh switch.sh bootchain.sh 'system/*' -d "$openf50_x" >&2 ||
    abort "! The zip could not be unpacked"
OPENF50_DIR=$openf50_x/openf50 ZIPFILE=$ZIPFILE MAGISKBIN=${MAGISKBIN:-/data/adb/magisk} \
    "${MAGISKBIN:-/data/adb/magisk}/busybox" sh "$openf50_x/openf50/install.sh"
openf50_rc=$?
rm -rf "$openf50_x/openf50"
case $openf50_rc in
    0) ;;
    3) rm -rf "$openf50_x"; abort "- Dry run: nothing was written, the module was not installed" ;;
    *) rm -rf "$openf50_x"; abort "! OPENF50 Linux was not installed; the messages above say why and what was not changed" ;;
esac
mkdir -p "$MODPATH" && cp -R "$openf50_x/module.prop" "$openf50_x/action.sh" "$openf50_x/switch.sh" "$openf50_x/bootchain.sh" "$openf50_x/system" "$MODPATH/" ||
    { rm -rf "$openf50_x"; abort "! The switch module could not be installed"; }
rm -rf "$openf50_x"
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/switch.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/bootchain.sh" 0 0 0755
set_perm "$MODPATH/system/bin/openf50-linux" 0 0 0755
unset openf50_x openf50_rc
