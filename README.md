# 👻 Boo

A tiny macOS menu-bar ghost that eats your downloads and files them away.

Boo lives in your menu bar. When you download something it recognizes, the ghost
munches it and tucks it into the right folder (Images, Archives, Documents, and so on).
When it meets a file type it has never seen, it looks confused and asks you where it
should go, then remembers your answer for next time.

Native Swift. No Electron, no browser bundle, no background bloat. A couple of MB.

## Features

- Silent auto-sort for common file types
- Friendly popup for unknown types, with a "remember this type" option
- Animated ghost in the menu bar: idle, eating, confused, napping
- Toast when a file gets sorted ("Nom! Saved to Images")
- Settings window: pause, toggle toasts, manage learned rules
- Ignores in-progress downloads (`.crdownload`, `.download`, `.part`)
- Never touches your existing folders, only loose files in Downloads

## The many moods of Boo

Boo pulls a different face depending on what's happening:

<table>
  <tr>
    <td align="center"><img src="Sources/Boo/Resources/Avatars/default.svg" height="56" alt="watching"><br><sub>watching</sub></td>
    <td align="center"><img src="Sources/Boo/Resources/Avatars/eating.svg" height="56" alt="eating"><br><sub>eating</sub></td>
    <td align="center"><img src="Sources/Boo/Resources/Avatars/confused.svg" height="56" alt="confused"><br><sub>confused</sub></td>
    <td align="center"><img src="Sources/Boo/Resources/Avatars/sleep.svg" height="56" alt="napping"><br><sub>napping</sub></td>
    <td align="center"><img src="Sources/Boo/Resources/Avatars/happy.svg" height="56" alt="happy"><br><sub>happy</sub></td>
    <td align="center"><img src="Sources/Boo/Resources/Avatars/surprise.svg" height="56" alt="surprised"><br><sub>surprised</sub></td>
  </tr>
</table>

The full set lives in [`Sources/Boo/Resources/Avatars`](Sources/Boo/Resources/Avatars).

## Install

1. Download `Boo.dmg` from the [latest release](https://github.com/dizzpy/boo/releases/latest).
2. Open it and drag **Boo** into the **Applications** folder, then eject the disk image.
3. Boo is ad-hoc signed but **not notarized** (that needs a paid Apple Developer
   account), so on first launch macOS blocks it as an "unidentified developer".
   Clear it once — easiest way:

   ```bash
   xattr -dr com.apple.quarantine /Applications/Boo.app
   ```

   Or without the terminal: try to open Boo, then go to **System Settings →
   Privacy & Security**, scroll down, and click **Open Anyway**.
4. The ghost appears in your menu bar. To start it automatically, add Boo under
   **System Settings → General → Login Items**.

> If you ever see **"Boo is damaged and can't be opened"**, that's macOS's
> message for a quarantined un-notarized app — it isn't actually damaged. The
> `xattr` command above clears it.

> On first sort, macOS asks permission to access your Downloads folder — click **OK**.

## Run it (dev)

Requires Xcode or the Swift toolchain.

```bash
cd Boo
swift run
```

The ghost appears in your menu bar. Click it for controls.

> First run needs permission to your Downloads folder. Launched from Terminal,
> Boo inherits Terminal's file access. Built as a standalone `.app` (below),
> macOS prompts you automatically the first time it touches Downloads.

## Build a standalone app

```bash
bash make-app.sh
```

This produces `Boo.app` (with its app icon) and a ready-to-share `Boo.dmg`
installer — using only the Swift toolchain and stock macOS tools, no extra
dependencies. Move the app to `/Applications` and add it to your Login Items
to have the ghost start with your Mac.

## Customize

- **File-type map** — `Sources/Boo/Core/Categories.swift`. Add or move
  extensions to fit how you think about your files.
- **Ghost art** — `Sources/Boo/Resources/Avatars/*.svg`. Swap the SVGs to give
  Boo a new look.

## License

MIT. See `LICENSE`.

Built by [dizzpy](https://dizzpy.dev).
