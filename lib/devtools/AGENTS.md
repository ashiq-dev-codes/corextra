# DevTools Instructions

Rules for `lib/devtools/`. Package-wide rules are in [../../AGENTS.md](../../AGENTS.md).

The panel runs inside other people's apps, on top of their UI, often in QA builds. It must never crash the host app, slow it down, or record anything while it's turned off.

## State and recording

- All state lives in `CorextraDevTools.instance` ([devtools_controller.dart](devtools_controller.dart)). Add new state there, not in a new singleton or global.
- Stores are bounded ring buffers. Give any new store a cap too, and clear it in `resetAll()`.
- Code that records data (interceptors, loggers, probes) checks `CorextraDevTools.instance.enabled` first, then only appends to a store. Keep it cheap: it runs on every request or log. Store references, not formatted text; formatting happens only when the panel shows it.
- `enabled` defaults to `kDebugMode`. Never switch it on by default for release builds; apps opt in.

## Panel UI

- A busy app must never make the panel busy. Build from store data with `DevToolsLiveBuilder` ([live_builder.dart](panel/live_builder.dart)), never `ListenableBuilder`, so a burst of captures costs one rebuild. Build long content lazily, only what's on screen, and cache anything derived from a request on that request.

- Never use `Navigator`, routes, `showDialog`, `showMenu` or `PopupMenuButton`. The panel can be mounted with only a local `Overlay` above it. Use `MenuAnchor` or the ambient `Overlay` instead.
- A nested view (a detail screen or fullscreen viewer) wraps itself in `BackHandlerScope` ([back_handler_scope.dart](panel/back_handler_scope.dart)) so Android's back button closes just that view.
- The panel opens both as a small floating window and full screen, in light and dark themes. Check a UI change in all four.
- Empty tabs use `DevToolsEmptyState` ([empty_state.dart](panel/empty_state.dart)), so they all look the same.

## Tabs and find

The find bar searches each tab's data, not its widgets, so it can see off-screen rows and other tabs. Every tab must take part:

- Register a tab in [devtools_tabs.dart](panel/devtools_tabs.dart). It goes in three lists there that must stay in the same order: the tab specs, the `TabBarView` children and the `DevToolsFind` sources. Export the tab from `lib/corextra.dart`.
- Give the tab a `static final FindSource findSource` that yields every text it can show, in on-screen order, each with a stable id.
- Render that text with `FindText`, passing the same id. A view that hides content (a detail screen or folded section) mixes in `FindAware` to open it when the match is inside. A long list uses `FindListView` inside `DevToolsScrollToTop(scrollbar: true)`, so it gets the same easy-grab scrollbar as everywhere else.
- Find lives in [find/](find/) and is internal: don't export it.

## Tests

- The controller is shared across tests. Tests in `test/devtools/` set `CorextraDevTools.instance.enabled = true` and call `resetAll()` in `setUp` and `tearDown`; new tests must too.
