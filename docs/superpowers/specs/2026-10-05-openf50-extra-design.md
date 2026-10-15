# openf50-extra: optional components downloaded on demand (design)

Date: 2026-10-05. Branch `openf50-extra` (on top of driver-fixes, PR #28 stack).

## Problem

The user (translated): "the VPN tool should not come embedded in the system; it should be downloadable with
openf50-extra". Today every image carries Xray-core (34 MB), hev-socks5-tunnel (0.4 MB) and sing-box (86 MB) in
`/opt/openf50/bin`, about 120 MB per system whether the VPN is used or not. Second, smaller problem: `openf50-ussd`
(and `sms`, `openf50-voice`) are not on the PATH of OpenWrt (and Ubuntu): only `/etc/profile.d` adds `/opt/openf50/bin`,
which a non-login shell (`ssh root@... openf50-ussd`) and sudo never see.

## Decisions

1. **What an extra is.** A release asset `openf50-extra-<name>.tar.gz` built by `tools/make-extra.sh`, listed in the
   release's `SHA256SUMS` like every other asset. Layout: `./name`, `./release` (the tag), `./components` (what is
   inside, with versions), `./bin/<commands>`. One extra exists: **vpn** = xray + hev-socks5-tunnel + sing-box. It
   is not split: openf50-vpn falls back from one engine to the other and the kill switch needs sing-box, so a VPN
   with only one of them is a half-working VPN. Only arm64 exists (both devices), so the name carries no arch.
2. **Where it comes from.** Only from a release, verified against that release's SHA256SUMS with openf50-update's
   own `fetch_verified` - never from a third-party URL at run time. The engines' upstream downloads stay pinned by
   hash in `tools/fetch-xray.sh` and `tools/fetch-sing-box.sh`, run at release build time. Test and offline hooks:
   `OPENF50_EXTRA_FILE=<tarball>` (a local file, in the style of `OPENF50_KERNEL_BUNDLE`), `OPENF50_RELEASE_URL=<base>`
   (another server with the same files and SHA256SUMS, as `install.sh` already has), `OPENF50_RELEASE=<tag>`.
   Which release: `OPENF50_RELEASE`, else the release of the running system (`/etc/openf50/image-version`), else (a
   `dev` image, or a release from before extras) the newest one.
3. **Where it goes.** `/mnt/openf50-disk/extra/<name>/` - on the Linux partition, next to `ubuntu/` and `openwrt/`,
   not inside a system. Both systems see the same copy (installed once, ~120 MB once), and nothing that replaces a
   system (openf50-update, the installer's "update", rollback) touches it; only a wipe does. Installation unpacks to
   `.<name>.new` and renames, so an interrupted install never leaves half an extra.
4. **PATH.** One list of the system's commands, `/opt/openf50/lib/path-commands`, read by `rootfs/assemble.sh`,
   `openwrt/build-rootfs.sh` and at boot by `openf50-extra link` (replaces rootfs-fixups' copy of the list;
   OpenWrt's `openf50-post` runs it too, so installed OpenWrt systems get new links without an update). It adds
   `openf50-ussd`, `sms`, `openf50-voice`, `openf50-extra`. `openf50-extra link` also links the commands of installed extras
   (`xray`, `sing-box`, `hev-socks5-tunnel`) into the PATH directory (Ubuntu `/usr/local/bin`, OpenWrt `/usr/bin`)
   and removes links into the extras that no longer resolve. openf50-vpn itself does not use the PATH: it looks in
   `/mnt/openf50-disk/extra/vpn/bin` first and then `/opt/openf50/bin` (images from before this change).
5. **openf50-update.** Installed extras are part of the update: `apply` downloads `openf50-extra-<name>.tar.gz` of the
   same release for every installed extra whose release differs, in the download phase (nothing is changed when a
   download fails), and installs them after the systems. `check` lists them.
6. **Existing installations with the VPN in use.** A system whose `/etc/openf50/vpn.conf` says `ENABLE=1` and that has
   no vpn extra gets one with the update - downloaded with the rest, before anything changes. If installing it fails
   after the switch, the engines are copied from the previous system (`<os>.old/opt/openf50/bin`) instead
   ("adopt"). A release without the asset (older) still has the engines in its images: nothing to do.
   Last line of defence, for every other path (an old installer, an updater from before self-update, a manual
   copy): `openf50-vpn run` with `ENABLE=1` and no engine adopts them from `<os>.old`, else runs
   `openf50-extra install vpn`, before the kill switch goes on. A VPN that was configured keeps working.
7. **Missing engine message.** `openf50-vpn run|gen` without an engine: `the VPN engines are not installed: run
   openf50-extra install vpn`; `status` shows the same line. The toolkit's "Turn on" installs the extra first.
8. **Installers.** `install.sh` / `install.ps1` ask "Install the VPN extra (Xray, sing-box; about N MB)?",
   default **no** (the point is that a system without VPN does not carry it). Yes: the extra comes from the same
   release download (verified with the same SHA256SUMS), is pushed and `android-install.sh` unpacks it into
   `extra/vpn` - offline, nothing on the device downloads. In update mode a system whose vpn.conf has `ENABLE=1` and
   no extra gets the engines adopted from the system being replaced (also offline). `--build` builds the extra
   with `tools/make-extra.sh`.
9. **Images.** `rootfs/assemble.sh` and `openwrt/build-rootfs.sh` no longer take xray/hev/sing-box;
   `make-release.sh` builds `openf50-extra-vpn.tar.gz`, puts it into SHA256SUMS and the upload, and its audit fails
   if an image still carries an engine. Saved: about 120 MB per installed system, ~48 MB per compressed image asset
   (measured in FINDINGS / the report).

## Commands

```
openf50-extra list              the extras a release offers, and which are installed
openf50-extra status            installed extras: release, size, commands
openf50-extra install NAME      download (release of this system), verify, install, link
openf50-extra remove NAME [--force]   refuses the vpn extra while ENABLE=1 unless --force (review fix)
openf50-extra link              put the system's and the extras' commands on the PATH (run at boot)
openf50-extra adopt NAME        take the engines from the system an update replaced (<os>.old); used by openf50-vpn
```

## Not done

- No per-arch assets (one arch exists).
- No extra other than vpn yet; the catalog is one line per extra in openf50-update (`EXTRAS`).
- The installer does not detect an installed extra on the device before asking; openf50-update brings an extra up to
  the system's release on the next `apply`.
