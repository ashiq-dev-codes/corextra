# corextra_example

A runnable demo app for the [corextra](https://pub.dev/packages/corextra) package.

## Running it

```sh
flutter pub get
flutter run
```

Runs on Android, iOS, macOS, Windows, Linux, and web. To try the web build with WebAssembly:

```sh
flutter run -d chrome --wasm
```

## What's inside

The app has two tabs:

- **Features** — responsive helpers, a state update with the fade-slide animation, and form validators.
- **DevTools** — buttons that create logs, HTTP requests, and socket messages.

The app is wrapped in `CorextraDevToolsOverlay`, so a floating bubble shows on screen. Tap it to open the DevTools panel (Network / Logs / Info / Performance), then tap the buttons and watch the panel update live.

The **Socket Messages** buttons simulate socket traffic with `CorextraSocketLogger`, so no server is needed. Filter by **Socket** in the Network tab to see them.
