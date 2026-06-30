# Contributing to Boo

Thanks for wanting to help the ghost eat more downloads! 👻

## Getting started

```bash
git clone https://github.com/dizzpy/boo.git
cd boo
swift build      # compile
swift run        # run the menu-bar app
```

Requires macOS 13+ and the Swift toolchain (Xcode or the standalone toolchain).

## Project layout

```
Sources/Boo/
  App/    App entry point and delegate
  Core/   File watching, sorting, persistence (no UI)
  UI/     Menu-bar ghost, toast, settings, prompts (AppKit + SwiftUI)
```

Keep `Core/` free of UI imports so the sorting logic stays testable and small.

## Making a change

1. Branch off `main` using a typed name: `feat/…`, `fix/…`, `docs/…`, `chore/…`.
2. Make your change. Add or move file-type rules in `Sources/Boo/Core/Categories.swift`.
3. Run `swift build` and make sure it compiles with **no warnings**.
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/) (see below).
5. Open a pull request against `main` and fill in the template.

## Commit messages

We use Conventional Commits. The type prefix drives the changelog:

```
feat:     a new user-facing capability
fix:      a bug fix
docs:     documentation only
refactor: code change that neither fixes a bug nor adds a feature
chore:    tooling, build, dependencies
```

Example: `feat(sorter): remember unknown types per extension`

## Code style

- Match the surrounding code: small types, clear names, light comments.
- No new dependencies — Boo is intentionally pure AppKit + SwiftUI.
- UI work runs on the main thread; file work runs off it.

## Reporting bugs

Open an issue with the bug report template. Include your macOS version and steps
to reproduce.
