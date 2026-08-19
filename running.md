# Running SchoolGuardian Locally

This covers starting the backend and running the Flutter app, on both
the Android emulator and a real phone connected by USB cable.

---

## 1. Start the backend

```bash
cd "Backend-schoolGuardian-main"
npm run dev
```

Leave this terminal open and running the whole time you're testing the
app. Confirm it's alive with:

```bash
curl http://localhost:3000
```

`Cannot GET /` is a normal response — it just means no route is
defined at `/` itself; your real routes live under `/api/...`.

---

## 2. Running on the Android emulator

No extra setup needed. From the `schoolguardian_app` folder:

```bash
flutter run
```

The app defaults to `http://10.0.2.2:3000/api`, which the emulator
automatically maps to your laptop's `localhost`. This only works
inside the emulator — never on a real phone.

---

## 3. Running on a real phone over USB cable

A real phone doesn't understand `10.0.2.2`, and WiFi-to-WiFi between
phone and laptop can be blocked by router isolation settings. The
reliable fix is to tunnel port 3000 straight through the USB cable and
point the app at `127.0.0.1`.

**Every time you plug the phone in fresh, do this first:**

```bash
adb devices
```

Confirm your phone shows up with `device` next to it (not empty, not
`unauthorized` — if `unauthorized`, unlock the phone and tap "Allow"
on the USB debugging prompt).

```bash
adb reverse tcp:3000 tcp:3000
```

This forwards the phone's `127.0.0.1:3000` through the cable to your
laptop's `127.0.0.1:3000`. It does **not** persist — redo it after
every unplug/replug.

Then launch the app:

```bash
cd "schoolguardian_app"
flutterphone
```

`flutterphone` is a shell alias (defined in `~/.bashrc`) equivalent
to:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

If `flutter run` offers multiple targets (Chrome, Linux, your phone),
pick your phone's number from the list.

Because this goes entirely over USB, the phone's WiFi/mobile data
state doesn't matter — it can be on WiFi, mobile data, or even
airplane mode with just the cable connected.

---

## Quick reference

| Target             | Command                                                              | Extra setup                          |
|---------------------|-----------------------------------------------------------------------|----------------------------------------|
| Emulator            | `flutter run`                                                        | None                                   |
| Real phone (USB)    | `flutterphone`                                                       | `adb reverse tcp:3000 tcp:3000` first  |

---

## Troubleshooting

- **"Couldn't reach server" on the phone** → the `adb reverse` tunnel
  isn't active. Check with `adb reverse --list`; it should print
  `tcp:3000 tcp:3000`. If empty, redo it.
- **Backend shows nothing when you try to register** → the request
  never arrived. Confirm the tunnel (above) and that the backend is
  still running (`curl http://localhost:3000` from the laptop).
- **Registration works on emulator but not phone, or vice versa** →
  almost always the wrong `API_BASE_URL`. Emulator needs `10.0.2.2`;
  phone (with the tunnel) needs `127.0.0.1`.