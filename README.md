# MiniFlow

Minimal offline task manager built with Flutter.

---

## Features

- Add / edit / delete tasks
- Priority levels (low, medium, high)
- Due dates & tags
- Search, filter, sort
- Progress tracking
- Responsive UI (web + mobile)
- Offline storage (SharedPreferences)

---

## Tech

- Flutter + Dart
- ChangeNotifier (state)
- SharedPreferences (local JSON storage)

---

## Architecture

```text
UI → ViewModel → Model → Storage
````

---

## Install

```bash id="x8v2lp"
flutter pub get
flutter run -d web-server
```

---

## Build

```bash id="c9q2aa"
flutter build web
```

---

## Storage

Saved locally under:
`miniflow_taches`

---

## License

MIT
