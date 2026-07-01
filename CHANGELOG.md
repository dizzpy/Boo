# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.1.0]: https://github.com/dizzpy/boo/releases/tag/v1.1.0
[1.0.0]: https://github.com/dizzpy/boo/releases/tag/v1.0.0
