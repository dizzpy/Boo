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
- Animated ghost in the menu bar: idle, eating, confused
- Toast when a file gets sorted ("Nom! Saved to Images")
- Settings window: pause, toggle toasts, manage learned rules
- Ignores in-progress downloads (`.crdownload`, `.download`, `.part`)
- Never touches your existing folders, only loose files in Downloads

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

This produces `Boo.app`. Move it to `/Applications` and add it to your
Login Items to have the ghost start with your Mac.

## Customize

The file-type map lives in `Sources/Boo/Core/Categories.swift`. Add or move
extensions there to fit how you think about your files.

## License

MIT. See `LICENSE`.

Built by [dizzpy](https://dizzpy.dev).
