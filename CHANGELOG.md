# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-07-01

### Added

- App version shown in the Settings header.
- "Check for Updates…" menu item that opens the latest release page in the
  browser — Boo itself still has no network code.
- "Remember" now also works for **Leave in Downloads**: remembered leaves
  appear in Settings as "Stays in Downloads" rules and can be removed there.
- Files skipped as still-downloading trigger an automatic rescan a few seconds
  later, instead of waiting for the next Downloads event.

### Changed

- One toast per scan: sorting many files at once shows "Nom! Sorted 12 files"
  instead of a toast per file.
- The menu-bar ghost no longer polls 10×/second; reactions expire on a
  one-shot timer (less battery).
- "Leave in Downloads" choices are now tracked by name *and* creation date, so
  a different future file reusing the same name still gets sorted.

### Security

- **App Sandbox + hardened runtime.** Boo.app is signed with a single
  entitlement (Downloads read/write) — macOS itself enforces that Boo cannot
  touch anything outside your Downloads folder.
- Folder names are validated at every entry point (prompt, saved rules on
  load, and again before every move), and every destination is checked to stay
  inside Downloads — `../` and friends are rejected.
- Fixed a data race between the background sorter and Settings edits.
- Sorting now skips symlinks and files modified in the last 5 seconds, and
  recognizes more partial-download suffixes (`.opdownload`, `.!ut`, `.aria2`,
  `.filepart`) — protects files still being written, e.g. torrents that
  preallocate their full size.
- Release pipeline: GitHub Actions pinned to commit SHAs; the release job now
  verifies the app's signature and entitlements before publishing.
- README install steps now lead with checksum verification and the
  System Settings "Open Anyway" flow instead of `xattr`.
- Added `SECURITY.md` (private vulnerability reporting) and
  `SECURITY_AUDIT.md` (full audit of this release's fixes).

### Notes

- Because of the new sandbox, Boo now stores settings in its sandbox
  container — remembered rules from earlier versions reset once after updating.

## [1.1.0] - 2026-07-01

### Changed

- Unknown file types are now batched into a single popup per scan instead of
  one popup per file: one row per unrecognized extension, each with its own
  folder pick and "remember" toggle, applied all at once with a "Done" button.

## [1.0.0] - 2026-06-30

### Added

- Menu-bar ghost that idles, chomps when a file is sorted, and looks confused for
  unknown types.
- Silent auto-sort of `~/Downloads` into category folders (Images, Archives,
  Documents, and more) by file extension.
- Single native popup for unknown file types: pick a folder, name a new folder
  inline, and optionally remember the choice for that extension.
- Toast notification when a file is sorted.
- Settings window: pause watching, toggle toasts, and manage remembered rules.
- Ignores in-progress downloads (`.crdownload`, `.download`, `.part`, …) and waits
  for file size to stabilize before moving.

[1.2.0]: https://github.com/dizzpy/boo/releases/tag/v1.2.0
[1.1.0]: https://github.com/dizzpy/boo/releases/tag/v1.1.0
[1.0.0]: https://github.com/dizzpy/boo/releases/tag/v1.0.0
