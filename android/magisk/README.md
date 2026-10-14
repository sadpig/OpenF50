# Magisk module: switch to Linux from Android

A one-tap way to start the Linux system from Android. It replaces having a computer plugged in just to change the
boot slot. There are two ways to get it:

* **The release's installer zips** (`openf50-magisk-<tag>-<system>-k<kernel>.zip`, see "Installing from Android with a
  Magisk zip" in the [main README](../../README.md)) install Linux and then stay on the device as this module. After
  the install it is called "OPENF50 Linux" instead of "OPENF50 Linux switch"; the module id is the same
  (`openf50_linux_switch`), so the two replace each other. The Action button, `openf50-linux` and everything below work
  the same. Their files come from this directory (`installer/` is the installation part, `openf50-linux-switch/` is
  this module), assembled by `tools/make-magisk-zips.sh`.
* **The switch-only module**, for a device where Linux was installed from a computer (`./install.sh`). It installs
  nothing and only changes the boot slot:

```sh
android/magisk/build.sh          # builds openf50-linux-switch.zip
```

Install the zip in the Magisk app (Modules → Install from storage), or from a computer:

```sh
adb push android/magisk/openf50-linux-switch.zip /data/local/tmp/
adb shell "su -c 'magisk --install-module /data/local/tmp/openf50-linux-switch.zip'"
adb reboot                      # Magisk applies a new module on the next boot
```

## Using it

* **Magisk app → Modules → OPENF50 Linux switch → Action.** The device arms the slot Android is not on and reboots
  into Linux.
* **From a terminal or adb:**

```sh
su -c openf50-linux               # switch to Linux now
su -c 'openf50-linux status'      # what is on each slot; changes nothing
su -c 'openf50-linux --dry-run'   # print the block it would write, write nothing
```

Going back needs nothing: Linux restores Android's block during its own boot, so the next reboot returns to
Android. From inside Linux, `openf50-next-boot linux` arms another Linux boot and `openf50-os <name>` picks which
system starts.

## What it writes

Exactly 32 bytes: the AOSP `bootloader_control` block at offset `0x800` of `misc`, with the slot Android is not on
at the highest priority and `tries_remaining = 2` (LK treats 1 as an already failed boot), Android's slot still
bootable and marked successful. `boot_a`, `boot_b`, the GPT, `userdata` and every other partition are untouched, so
the worst case of a Linux that does not boot is that LK falls back to Android by itself.

The block is not a canned blob: the module reads the live one, changes the slot suffix and the two metadata bytes,
and recomputes the CRC32 (zlib, over the first 28 bytes) in `awk`, so it stays correct on a device whose block
differs. It refuses to do anything when the magic is not `BCAB`, when Android's slot is unknown, or when the other
boot partition is missing, is not a boot image, or is just a copy of Android's (no Linux installed).

## Checked on hardware

ZTE F50 / OPENF50, Magisk 30.7, Android 13: `status` and `--dry-run` produce exactly the trial block that
`boot/flash-trial.sh` computes on a computer, and the Action/`openf50-linux` path rebooted the device into Linux.
