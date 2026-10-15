# The VPN toolkit as a module: dikeckaan/mu300-linux-vpn

Decided with the user on 2026-10-09: everything VPN moves out of openf50-linux into its own public repository,
**dikeckaan/mu300-linux-vpn**, and becomes a module that installs on the OPENF50's Ubuntu and OpenWrt, online (from the
device's own connection) and offline (a file copied onto the device). The engines (Xray, hev-socks5-tunnel,
sing-box) are inside the module; mihomo stays a separate add-on. openf50-linux keeps the kernel support and the
integration hooks. The LuCI VPN app (roadmap ②) and ③/④ will be developed in the module repository.

## What moves, what stays

**Moves to openf50-linux-vpn** (with its git history where possible):
`rootfs/overlay/opt/openf50/bin/openf50-vpn`, `rootfs/overlay/opt/openf50/lib/vpn/*` (drivers, uri.sh, openvpn-up),
`rootfs/overlay/etc/systemd/system/openf50-vpn.service`, `openwrt/overlay/etc/init.d/openf50-vpn`,
`rootfs/overlay/etc/openf50/vpn.conf.example`, `tools/fetch-xray.sh`, `tools/fetch-sing-box.sh`,
`tools/fetch-mihomo.sh`, `tests/test_vpn.py`, `tests/test_vpn_drivers.py` (with the parts of `tests/helpers.py`
they need), the VPN spec/plan under docs/superpowers, and the VPN parts of README/FINDINGS 26 (copied; FINDINGS
keeps a pointer).

**Stays in openf50-linux:** the kernel configuration (TUN, WireGuard, nftables, XT_MARK, XFRM), the packages the
module needs in the images (jq, openssl-util / openssl, wireguard-tools, openvpn where it is today), and the
integration hooks, each of which already does nothing when `/opt/openf50/bin/openf50-vpn` is absent or must be made to:
`mobile-data` (`openf50-vpn guard`), `wifi-client` (kill switch on wlan0), `openf50-power` (stop/start the service),
`openf50-toolkit` (VPN menu, shown only when the module is installed), LuCI (`unisoc-modem/action vpn`,
`dashboard-info` capabilities.vpn), `openf50-update` (keeps `etc/openf50/vpn.conf` and `etc/openf50/vpn/`), and
`arch/build-rootfs.sh`'s link list.

## The module package (contract between the two repositories)

Release assets of dikeckaan/mu300-linux-vpn, **fixed names** so `releases/latest/download/NAME` always works:
`openf50-linux-vpn.tar.gz`, `openf50-linux-vpn-mihomo.tar.gz`, `SHA256SUMS` (sha256sum format, both files). Tags:
`vMAJOR.MINOR.PATCH` (first: v1.0.0).

`openf50-linux-vpn.tar.gz` unpacks (paths relative, `./` prefix allowed) into the extra directory
`$DISK/extra/vpn` (`$DISK` = /mnt/openf50-disk), the same place the vpn extra has today:

```
VERSION                  v1.0.0
components               one line each: "openf50-linux-vpn v1.0.0", "xray 26.x", "hev-socks5-tunnel 2.x", "sing-box 1.x"
requires                 "openf50-linux v2026.10.16" - the first openf50-linux release without a built-in openf50-vpn
bin/openf50-vpn            the command (LIB defaults to the extra's lib/vpn, see below)
bin/xray bin/hev-socks5-tunnel bin/sing-box     aarch64 engines, pinned by hash at build time
lib/vpn/*.sh lib/vpn/openvpn-up
etc/vpn.conf.example
service/systemd/openf50-vpn.service
service/procd/openf50-vpn
hooks/link               sh hooks/link SYSROOT   (SYSROOT "" = the running system, or $DISK/<os> during an update)
hooks/unlink             sh hooks/unlink SYSROOT
install.sh               offline convenience: sh install.sh  ->  openf50-extra install vpn --from <this tarball's dir>
```

`openf50-linux-vpn-mihomo.tar.gz` is the `vpn-mihomo` extra as today (`bin/mihomo`, `components`, `VERSION`,
`requires`), installed to `$DISK/extra/vpn-mihomo`.

**hooks/link SYSROOT** (idempotent, POSIX sh, busybox ash) makes one system use the module: symlink
`SYSROOT/opt/openf50/bin/openf50-vpn` -> the extra's `bin/openf50-vpn` and `SYSROOT/opt/openf50/lib/vpn` -> the extra's
`lib/vpn` (a real file or directory there from an older image is moved aside to `*.builtin`, never deleted);
install the service (Ubuntu: copy the unit to `SYSROOT/etc/systemd/system/`, enable it with a symlink in
`multi-user.target.wants` when the VPN is wanted - `ENABLE=1` in `etc/openf50/vpn.conf` or the store's enabled flag,
exactly what `openf50-vpn enabled` answers; OpenWrt: copy to `SYSROOT/etc/init.d/openf50-vpn`, `/etc/rc.d` link the same
way); copy `vpn.conf.example` to `SYSROOT/etc/openf50/vpn.conf.example`. With SYSROOT "" on a running system it may
also `systemctl daemon-reload` / start the service when wanted and not running. **hooks/unlink** undoes exactly that
and puts a `*.builtin` back.

`openf50-vpn` itself: `LIB=${OPENF50_VPN_LIB:-<dir of the real bin/openf50-vpn>/../lib/vpn}` with a fallback to
`/opt/openf50/lib/vpn`, so it works both from the extra and through the symlinks. Engine lookup (engine_path) already
prefers the vpn extra's bin.

## openf50-linux side

* `openf50-extra`: `vpn` and `vpn-mihomo` come from the module repository: base URL
  `https://github.com/dikeckaan/mu300-linux-vpn/releases/latest/download` (`OPENF50_VPN_URL` overrides, e.g. a pinned
  tag or a local server); checked against that release's `SHA256SUMS`. Offline: `openf50-extra install vpn --from
  FILE|DIR` (a tarball, or a directory holding the tarball and SHA256SUMS: then it is verified). After unpacking,
  run `hooks/link ""` for the running system and `hooks/link $DISK/<os>` for every other installed system; `remove`
  runs `hooks/unlink` likewise. `openf50-extra link` (every boot) runs `hooks/link ""` for every extra that has one.
  `requires`: refuse a module that needs a newer openf50-linux than this system.
* `openf50-update apply`: extras are no longer taken from the openf50-linux release. `vpn` / `vpn-mihomo` are brought
  to the module's latest release when installed; the new systems get `hooks/link $DISK/<os>` before the reboot.
  **Migration and safety:** a system whose VPN is wanted (`openf50-vpn enabled` on the running system answers yes, or
  a vpn extra is installed) must have the module after the update. An old-format vpn extra (engines only, no
  `bin/openf50-vpn`) is replaced by the module during apply. If the module cannot be fetched (offline, GitHub down) and
  is not staged (`OPENF50_VPN_MODULE=FILE`, or the tarball + SHA256SUMS in the stage directory), **apply refuses before
  changing anything**, saying how to stage it - a VPN with the kill switch on would otherwise leave the device with no
  connection after the reboot (the user's VPN must never break on an update).
* Images: no `openf50-vpn`, no `lib/vpn`, no service file, no `vpn.conf.example` in the Ubuntu/OpenWrt/Arch images;
  `path-commands` no longer lists openf50-vpn (the extra's bin/ is linked by openf50-extra). jq, openssl, wireguard-tools
  and openvpn stay where they are installed today.
* `tools/make-release.sh` and `tools/make-extra.sh` no longer build `vpn` / `vpn-mihomo`; the release notes table
  points to openf50-linux-vpn. `install.sh` / `install.ps1` / the Magisk installer: the "install the VPN" question
  downloads the module from the module repository (host side, as the vpn extra is fetched today) and installs it the
  same way.
* Tests: `test_vpn*.py` leave; new tests cover openf50-extra with a module tarball (hooks run, --from file/dir,
  requires refused), openf50-update's migration and its refusal without the module, the images without openf50-vpn
  (test_static), the hooks being optional (mobile-data/wifi-client/openf50-power/toolkit with no openf50-vpn).

### As implemented in openf50-linux (what the module must meet)

* The tarball is checked like every extra before it is unpacked and again on disk: plain files and directories
  only (no symlink, hard link, device, FIFO), names of `[A-Za-z0-9._+-]` not starting with a dot, at most four
  levels below the top (`service/systemd/openf50-vpn.service` is three), 600 MB unpacked at most. `VERSION` is one line
  of `[A-Za-z0-9._-]{1,40}`; `bin/openf50-vpn`, `hooks/link` and `hooks/unlink` must be there (vpn-mihomo: a program in
  `bin/`). A `manifest` (sha256sum lines, `./path`) is checked when there is one. Files are owned by root afterwards,
  set-id and group/other write bits cleared.
* `requires` is read as the line `openf50-linux vYYYY.MM.DD`; tags compare as text. A system whose image-version is not
  a `v…` tag (a build of one's own) is not judged.
* The hooks run as `OPENF50_DISK=<disk> OPENF50_EXTRA_DIR=<disk>/extra/vpn sh hooks/link SYSROOT` (likewise unlink).
  `openf50-extra install` links every installed system whose release meets `requires` (the running one with SYSROOT
  "", the others as `$DISK/<os>`); `remove` unlinks every system before the extra is deleted; `link` (boot) links
  the running system. `openf50-update apply` links the systems it updated, after they are switched.
* The installed tarball's sha256 is kept in `$DISK/extra/.vpn.sha256`: an online install or an update whose
  SHA256SUMS lists the same hash downloads nothing.
* `openf50-update apply` stages: `OPENF50_VPN_MODULE=FILE|DIR`, else `$DISK/.openf50-update/vpn/` (the tarball and its
  SHA256SUMS; used up by the update), else the download. The module is installed before the systems are switched,
  so a module that fails its checks stops a device that needs it while nothing is changed.
* The host installers push the module as `openf50-extra-vpn.tar.gz` (android-install.sh takes a `name` extra or one
  with `VERSION` and, for vpn, `bin/openf50-vpn` and the hooks); the systems link it at their first boot.
* `openf50-extra adopt` is gone (it answers "nothing to adopt" with status 1): the module carries its engines.
* **Fail closed when the kill switch is orphaned.** `rootfs/overlay/opt/openf50/lib/vpn-orphan.sh` (sourced, POSIX,
  read with sed, nothing sourced): `vpn_killswitch_orphaned CMD [ROOT]` is true when CMD (`openf50-vpn`) is not
  executable and the VPN is wanted with its kill switch - `ENABLE` from `vpn.conf` (the last line, quotes and a
  trailing comment dropped; only 1 is on), `KILL_SWITCH` from `etc/openf50/vpn/settings` when the store is in use (a
  `profiles` directory and a readable settings file), else from `vpn.conf`; only 0 is off. Then `mobile-data up`
  keeps the bearer down, `wifi-client connect`/`up` joins nothing and shares nothing, each saying "the VPN's kill
  switch is on but the VPN module is missing ... (openf50-extra install vpn, or turn the kill switch off)";
  `dashboard-info` reports `vpn.orphaned`, and the toolkit's VPN page says so and offers the install.
  `openf50-update` and `tools/android-install.sh` carry the same two functions (they run where the file is not
  installed); a test holds the copies equal.
* **Updates and reinstalls over a kill switch.** `openf50-update apply` refuses before switching anything when the
  module cannot be had or fails its checks; a system the hook could not link after the switch gets a loud warning
  and fails closed by itself (above). A reinstall from a computer: the installers look at the systems being
  replaced through a read-only mount; the VPN question defaults to yes when one has its VPN on, and "no" is refused
  when its kill switch is on too. `android-install.sh` refuses the same on its own (UPDATE=1, no module pushed or
  installed) before any system is replaced; with the kill switch off it only warns.

Known limitations (accepted 2026-10-09):
* The installed module's hash (`.vpn.sha256`) is written only by `openf50-extra install` and `openf50-update apply`: a
  module pushed by an installer or installed with `OPENF50_EXTRA_FILE` is downloaded once more at the next update.
* With the VPN on and its kill switch off, a system without the module joins and brings up mobile data in the clear:
  the VPN simply is not running there (it was the user's choice to allow traffic outside the tunnel).

## openf50-linux-vpn side

Layout: `bin/`, `lib/vpn/`, `service/{systemd,procd}/`, `etc/`, `hooks/`, `install.sh`, `tools/` (fetch-*.sh,
`make-module.sh OUTDIR [TAG]` -> the two tarballs + SHA256SUMS), `tests/` (moved tests + `test_module.py`: the
tarball layout, hooks/link and unlink against a fake SYSROOT for Ubuntu and OpenWrt, `*.builtin` handling,
idempotence), `.github/workflows/tests.yml` (macOS + Ubuntu, as openf50-linux's), `.github/workflows/release.yml`
(`workflow_dispatch` with a tag, from main only, refuses an existing tag: builds with make-module.sh on
ubuntu-24.04-arm or with the pinned downloads, publishes), README (install online/offline on Ubuntu and OpenWrt,
commands, profiles, security model), LICENSE (MIT, as openf50-linux; engines keep their licences - listed in the
release notes), docs (the VPN spec and FINDINGS excerpt).

## Order

1. openf50-linux-vpn: repository with history, layout, hooks, make-module, tests, CI; a local build of the module.
2. openf50-linux: the side above, against that local build.
3. Device test on the U30 Air (OpenWrt, the user's VPN: legacy xray profile) and on F50-B (Ubuntu): update from
   v2026.10.15 with the module staged, VPN state and exit IP unchanged after the reboot; online install from the
   module repo's first release; offline `--from`; remove; an apply with the VPN on and no module refused.
4. Release module v1.0.0, then openf50-linux v2026.10.16.
