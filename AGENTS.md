# Agent Instructions

Rules for any coding agent (Claude Code, Cursor, Codex, Copilot, ...) working in this repo. Read this before touching code.

User docs live in [README.md](README.md) and [CHANGELOG.md](CHANGELOG.md). This file links to them instead of repeating them.

## What this package is

`corextra` is a Flutter utility package published on pub.dev: extensions, form validators, responsive helpers, logging, Dio helpers and an in-app DevTools panel. It's pure Dart, with no native code, and it must run on every Flutter platform, including web and WASM.

Apps import one library, [lib/corextra.dart](lib/corextra.dart), which exports everything public. A file it doesn't export is internal.

## The two rules above all

Every change must keep both of these true. If a task can't be done without breaking one, stop and ask.

### 1. Run on every platform Flutter supports

Android, iOS, web (including WASM), macOS, Windows and Linux. A change that works on one platform but breaks or degrades another is a bug, even if nobody reports it.

- No `dart:io` or browser-only APIs in shared code, and that includes packages that import them internally. Put such code behind a conditional import, the way [platform_services.dart](lib/devtools/util/platform_services.dart) does.
- No native code, and no plugin or package that doesn't support every platform above.
- Where a platform can't support a feature, fall back quietly. Never throw or crash.

### 2. Stay lightweight

Everything in corextra ends up inside other developers' apps: their app size, build time, startup time and dependency tree. Keep that cost as small as possible.

- Ask before adding a dependency. Prefer a few lines of Dart over a new package.
- Keep version ranges wide, and ask before narrowing one. Wide ranges let apps resolve corextra alongside their own dependencies.
- Don't add assets, fonts or code generation without asking.
- Do no work until the app asks for it: no top-level setup, timers or listeners that start on their own.
- Keep code that runs often (per request, per log, per frame) cheap.

## Working rules

1. **Treat exported API as public.** Apps you'll never see use everything `lib/corextra.dart` exports. Removing, renaming or changing the behavior of anything exported is a breaking change: say so clearly and note it in the CHANGELOG.
2. **Follow the existing pattern.** Copy how a similar extension, validator or widget is built.
3. **Change only what the task needs.** No drive-by refactors, renames or reformatting of unrelated code.
4. **Don't guess.** If a requirement or expected behavior is unclear, ask.

## Folder rules

These folders have their own `AGENTS.md` with rules that only matter there. Read it before working in that folder; not every tool loads it for you.

| File | Covers |
| --- | --- |
| [lib/devtools/AGENTS.md](lib/devtools/AGENTS.md) | In-app DevTools panel: shared state, recording, tabs, find, tests |
| [example/AGENTS.md](example/AGENTS.md) | Demo app: layers, demo actions, simulated responses |

Keeping these files useful:

- Don't add a `CLAUDE.md` anywhere. Claude Code reads `AGENTS.md` directly, and a `CLAUDE.md` in the same or a parent folder stops it from doing so.
- Each rule lives in one file only: here if it applies everywhere, or in the folder where someone would break it.
- Add a folder file only when a folder has several rules nothing outside it needs, and list it in the table above. A single rule goes in the closest existing file.
- Don't copy values that live in code (versions, limits, defaults, lists of files). Name the file that holds them, so the rule never goes stale.
- If a rule is out of date, fix it in the same change.

## Where things go

- `lib/<feature>/` holds one feature each: `extensions/`, `validators/`, `responsive/`, `logs/`, `network/`, `devtools/` and so on. Put new code in the matching folder, or a new one named the same way.
- `test/` mirrors `lib/`.
- `example/` is a runnable app that shows off the package.

## Adding to the API

- Export new public files from `lib/corextra.dart`, keeping the exports in alphabetical order.
- Give every public member a one-line `///` doc comment; pub.dev scores documented APIs.
- Add tests in the matching `test/` folder. Tests import `package:corextra/corextra.dart`, like apps do.
- Document user-facing additions in the README, and add a demo to the example app.
- Log with `log` from `dart:developer`, like the rest of the package. Never use `print` or `debugPrint`.

## UI

Developers judge the package by how its UI looks and feels, so make every widget and screen user-friendly and attractive.

- Make it clear at a glance: plain labels, an obvious main action and helpful feedback when something happens.
- Handle every state: empty, loading and error each show a clear message. Never leave a blank area or show a raw exception.
- Fit every screen size, from a small phone to a desktop window, with no overflow. Long text wraps or truncates cleanly.
- Make controls easy to tap and keep animations short and smooth.
- Match the existing look: spacing, corner radius, icons from `lucide_icons_flutter`. Don't invent a new style.

## Code style

- Match the file you're in: naming, structure and `dart format` formatting.
- Comments are one line, stating only the non-obvious *why*. That includes `///` doc comments.
- Don't leave commented-out code or unused code behind.

### No `!` null checks

Never use the `!` null-check operator. It throws at runtime when the value is null, and that crashes the app using corextra. Instead:

- Use `?.` and `??` to fall back to a sensible default.
- Or check for null first. Copy a field into a local variable so Dart promotes it to non-null.
- If null really means the caller made a mistake, throw an `ArgumentError` or `StateError` whose message says what was missing.
- In UI and in code that records data, show a fallback instead of throwing.

Older code still has some `!`. Replace it in the lines you change; don't sweep files you aren't otherwise touching.

## Releasing

- The version is in `pubspec.yaml`, the install snippet in the README's Getting Started section, and the CHANGELOG heading. Change all three together.
- Add a CHANGELOG entry at the top in the existing format: `## <version>` and plain, user-facing bullets.
- `dart pub publish --dry-run` must pass without warnings, and its file list must not include IDE, OS or build files. Only publish when asked.

## Commits

- Use Conventional Commits, like the existing history: `type: summary`, e.g. `feat: add socket tab` or `fix: keep panel above dialogs`. Types are `feat`, `fix`, `refactor`, `style`, `docs` and `chore`.
- Only commit when asked.

## Before you finish

There is no CI, so run these yourself:

```sh
dart format --output=none --set-exit-if-changed lib test example/lib
flutter analyze
flutter test
```

For UI changes, also run the example app on a device and on web: `cd example && flutter run`, then `flutter run -d chrome`.

Then check:

- Both rules above still hold: nothing platform-specific in shared code, and no new dependency, asset or startup work you didn't ask about.
- No new `!` null checks, and any UI you changed handles its empty, loading and error states.
- Any change to exported API is called out, and breaking changes are in the CHANGELOG.
- The README and CHANGELOG cover every user-visible change.
- You followed the folder `AGENTS.md` for every folder you changed.
