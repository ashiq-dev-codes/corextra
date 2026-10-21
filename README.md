# corextra

Handy Dart extensions and utilities for Flutter — plus form validators, responsive helpers, logging, and an in-app DevTools panel.

[![pub package](https://img.shields.io/pub/v/corextra.svg)](https://pub.dev/packages/corextra)

Works on **Android, iOS, Web (including WASM), macOS, Windows, and Linux**.

---

## Getting Started

Add the dependency:

```yaml
dependencies:
  corextra: ^1.3.2
```

Import it:

```dart
import 'package:corextra/corextra.dart';
```

---

## Features

### Extensions
- Null-safe checks: `.isNullOrEmpty` on `String?` and `List?`
- Safe conversions: `.toTryInt()`, `.toTryDouble()`, `.toTryBool()`
- String helpers: `.capitalize()`, `.toPascalCase()`, `.toCamelCase()`
- DateTime parsing and formatting
- `safeSetState` — calls `setState()` only if the widget is still mounted

### Form Validators
- `required`, `email`, `phone`, `otp`, `password`, `confirmPassword`
- `minLength`, `maxLength`, `numeric`, `url`, `pattern`
- `FormValidators.compose([...])` — run several validators, return the first error
- `FormValidators.optional(validator)` — skip validation when a non-required field is empty
- Every validator accepts a custom `message:`
- Optional translations via `easy_localization`

### Responsive
- `ResponsiveBreakpoints` — `sm` / `md` / `lg` / `xl` / `xxl` on `BuildContext` or `BoxConstraints`
- `deviceType`, `isMobile`, `isTablet`, `isDesktop`
- `responsive<T>(base: ..., md: ..., lg: ...)` — pick a value per screen size, no `LayoutBuilder` needed
- `screenWidth`, `screenHeight`, `isPortrait`, `isLandscape` on `BuildContext`

### Error Handling
- `CorextraException`, `CorextraCustomException`, `CorextraNetworkException`
- `DioErrorHandler` — turns Dio errors into clear, typed exceptions

### Logging
- `debugLog` — simple logger with levels (`info` / `warning` / `error`). Prints in debug builds and shows in the DevTools Logs tab
- `AppLogger` — structured logs for app events and Dio requests
- `AppLoggerInterceptor` — pretty, color-coded Dio logs (turn off with `enabled: false`)
- `CorextraSocketLogger` — logs socket messages to the console **and** DevTools. See [Socket Logging](#socket-logging)

### Animation
- `FadeSlideTransition` — fade + slide in from `top`, `bottom`, `left`, `right`, or a `custom` offset

### Models
- `CorextraJsonModel` — API models with one line per field: no hand-written parsing, `toJson`, `==` or `toString`. See [Models](#models)
- `CorextraDataClass` — `==`, `hashCode` and `toString` for classes with normal fields
- `CorextraSortable` — `list.sort()`, `<` and `>` by the fields you pick
- `CorextraValidatable` — `validation.isValid` and `validation.errors` using your `FormValidators`
- No `build_runner`, no code generation, no extra dependencies

---

## Models

Write each field once, as a typed getter. corextra handles parsing, `toJson`, `==` and `toString`. All four are mixins (`with`), so `extends` stays free for your own base class.

```dart
class UserModel with CorextraJsonModel {
  UserModel.fromJson(this.json);

  @override
  final Map<String, dynamic> json;

  int? get id => read('id');                 // "7", 7 and 7.0 all read as 7
  String get name => read('name') ?? '';     // a default when missing
  bool? get isNewUser => read('is_new_user'); // true, "true", 1 and "1" read as true
  DateTime? get joinedAt => read('joined_at');
  Role get role => readEnum('role', Role.values) ?? Role.member;
  List<String>? get tags => readList('tags');
  AddressModel? get address => readModel('address', AddressModel.fromJson);
  List<CourtModel>? get courts => readModelList('courts', CourtModel.fromJson);

  // The API sends this under different keys; the first one with a value wins.
  String? get email => read('user_email', fallbackKeys: ['email', 'userEmail']);

  // A dot reads inside nested objects: json['owner']['name'].
  String? get ownerName => read('owner.name');

  // Numbers are Unix timestamps (seconds or milliseconds); text is read as an ISO date.
  DateTime? get startsAt => read('days_until_start');

  // Any other date format.
  DateTime? get startTime => readDate('start_time', format: 'HH:mm:ss');

  // Works the same when the API sends the object or list as JSON text, like "{\"prices\": {...}}".
  MetaModel? get meta => readModel('meta', MetaModel.fromJson);
}
```

The type comes from the getter, so always write it: `int? get id`, not `get id`.

`read`, `write` and the other helpers are for use inside the model only; the analyzer warns if other code calls them. That keeps JSON keys in one place, and the rest of your app uses typed fields like `user.id`.

**What you get:**

```dart
final user = UserModel.fromJson(response.data);

user.id;                                     // 7, converted on first read, then reused
user.toJson();                               // what the API sent, plus anything you changed
user == UserModel.fromJson(user.toJson());   // true: equal when the data matches
print(user);                                 // UserModel{id: 7, name: Ashiq, ...}
```

**Safe by default:** a missing key or a value of the wrong type reads as `null` and never throws. `7.5` never silently becomes the int `7`, a map never becomes the text `"{...}"`, and a nested `fromJson` that throws gives `null`. The model never changes the `json` you passed in.

**Wrong values don't go unnoticed:** in debug builds, a value that exists but can't be read prints one warning, so a bad API field is easy to spot:

```text
UserModel: "id" should be int, but the JSON has text "abc". It reads as null.
```

Each model type and key warns once, and missing or blank values never warn. Release builds print nothing. To turn warnings off: `CorextraJsonModel.debugWarnings = false;`

**Customize anything:**

```dart
class CourtModel extends BaseEntity with CorextraJsonModel {
  CourtModel.fromJson(this.json);

  // An optional typed constructor for building one by hand.
  CourtModel({int? id, String? name}) : json = {'id': id, 'name': name};

  @override
  final Map<String, dynamic> json;

  int? get id => read('id');
  String? get name => read('name');

  // A field you change at runtime; reads and toJson() see the new value.
  set name(String? value) => write('name', value);

  // Custom logic, built once and reused until the next write().
  String get label => cached('label', () => '#$id ${name ?? ''}');

  // Compare by id instead of all data.
  @override
  bool operator ==(Object other) => other is CourtModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  // Change what gets sent to the API.
  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'name': name?.trim()};
}
```

**Copying a model** (for example in a cubit, so the screen rebuilds): add a `copyWith` with only the fields you change. `toJson()` already carries the rest.

```dart
ChatModel copyWith({int? unreadCount, String? avatarUrl}) => ChatModel.fromJson({
  ...toJson(),
  'unread_count': ?unreadCount, // `?` skips the key when the value is null
  'avatar_url': ?avatarUrl,
});

chat.copyWith(unreadCount: 0);
```

The `?` form needs Dart 3.8 or newer. On older Dart, write `if (unreadCount != null) 'unread_count': unreadCount,` instead.

For a one-off copy you can skip `copyWith`: `ChatModel.fromJson({...chat.toJson(), 'unread_count': 0})`.

**Good to know:**
- `toJson()` keeps every key the API sent, including ones you didn't declare, and sends back anything you didn't change exactly as it came in. JSON that arrived as text goes back as text.
- Each field is converted on first read and remembered inside that model, so reading it again is cheap. If the map you passed to `fromJson` changes later, the model notices and reads the new value.
- Lists and maps from getters are copies, so editing one never changes the model. To change a value, use a setter or `copyWith`.
- A key that really contains a dot is always read as that key first.

**The other three mixins** work on any class, including a `CorextraJsonModel`:

```dart
// CorextraDataClass: like a Python @dataclass or a Java record.
class GeoPoint with CorextraDataClass {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;

  @override
  Map<String, Object?> get fields => {'lat': lat, 'lng': lng};
}

// CorextraSortable and CorextraValidatable.
class Player with CorextraJsonModel, CorextraSortable, CorextraValidatable {
  Player.fromJson(this.json);

  @override
  final Map<String, dynamic> json;

  String? get name => read('name');
  int? get rank => read('rank');

  @override
  List<Object?> get sortBy => [rank, name]; // ties on rank are sorted by name; nulls go last

  @override
  Map<String, String?> validate() => {
    'name': FormValidators.required(name),
  };
}

players.sort();                   // by rank, then name
player.validation.isValid;        // false when name is empty
player.validation.errors;         // {name: This field is required}
player.validation.firstError;     // This field is required
player.validation.errorFor('name');
```

The results sit under `validation` so they never clash with an `isValid` or `errors` field your API already sends.

If two mixins both define `==` (for example `CorextraJsonModel` and `CorextraDataClass`), the last one in the `with` list wins, and anything you write in the class itself wins over both.

---

## DevTools Panel

An in-app inspector, like Flutter DevTools but inside your app. No extra setup or connection needed.

```dart
MaterialApp(
  builder: (context, child) =>
      CorextraDevToolsOverlay(child: child ?? const SizedBox.shrink()),
  home: const HomeScreen(),
)

dio.interceptors.add(const CorextraDevToolsInterceptor());
```

Tap the floating bubble to open the panel.

| Tab | What it shows |
|---|---|
| **Network** | Every HTTP request and socket message. Filter by method or status. |
| **Logs** | Every `debugLog` / `AppLogger` call. Filter by level. |
| **Info** | App version and device details (the browser, on web). |

**Find anything** — the search box at the top works like a browser's find:
- Searches every tab at once: URLs, headers, request and response bodies, logs, and app info
- Every match is highlighted; the current one in orange
- Press **Enter** (or the arrows) to jump to the next match — DevTools opens the right tab, request, and section for you
- Each tab shows how many matches it holds
- **Shift+Enter** goes back, **Esc** clears, **Cmd/Ctrl+F** focuses the box

**In the Network tab:**
- Headers, query params, and body each get their own tab
- JSON shows as a collapsible, color-coded tree
- Large bodies scroll inside their own box
- Copy, Share, and Fullscreen buttons stay in view while you scroll
- Auth headers (`Authorization`, `Cookie`, …) get a **TOKEN** badge. Hide their values on screen with `hiddenHeaders` — Copy still gives the real value

**Good to know:**
- Tap **Minimize** to shrink the panel into a small floating window
- Long lists and large bodies have easy-to-grab scrollbars — drag along the right edge, or tap it to jump
- Android's back button closes the panel step by step, without affecting your app
- On web, **Share** opens the browser's share sheet, or copies to the clipboard if the browser doesn't have one
- On in debug builds, off in release. Change it anytime with `CorextraDevTools.instance.enabled = true`
- Built to stay out of your way, even with constant API traffic: console logs are formatted between frames instead of inside your requests, the panel refreshes a few times a second at most, and huge responses open instantly

Coming later: widget inspector, memory snapshots, storage viewer, and route inspector.

---

## Socket Logging

`CorextraSocketLogger` logs every socket message in two places:

- **Console** — a color-coded block per message (debug builds only)
- **DevTools** — a row in the **Network** tab (filter by **Socket**)

It works with any socket library (Socket.IO, WebSocket, etc.). Call it wherever you send or receive:

```dart
final logger = CorextraSocketLogger(url: socketUrl);

// Messages from the server
socket.onAny((event, [data]) => logger.receive(event, data));
socket.onConnectError((error) => logger.receive('connect_error', error, isError: true));

// Messages you send
logger.emit('chat:open', payload);
socket.emit('chat:open', payload);

// Messages you send and wait for a reply (ack)
final ack = await logger.emitWithAck(
  'chat:latest_messages',
  payload,
  () => socket.timeout(15000).emitWithAckAsync('chat:latest_messages', payload),
);
```

Each row in DevTools shows the event name, `EMIT` (sent) or `ON` (received), and its status: `OK`, `ERR`, or pending while waiting for an ack.

| Option | Default | What it does |
|---|---|---|
| `consoleEnabled` | `true` | Turn console logs on or off |
| `devToolsEnabled` | follows `CorextraDevTools.instance.enabled` | Turn DevTools capture on or off |
| `captureBody` | `true` | Save message data in DevTools |
| `maxBodyLength` | `100000` | Trims text messages longer than this |

---

## Example

A runnable demo app, including the DevTools panel, lives in [`example/`](example/):

```sh
cd example
flutter pub get
flutter run
```
