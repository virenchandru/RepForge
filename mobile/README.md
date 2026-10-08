# RepForge Mobile

Flutter client for the RepForge Laravel authentication API. The app includes
login, account registration, an authenticated welcome screen, and logout.

## Run on an Android emulator

Start the backend from the `backend` directory:

```sh
php artisan serve --host=0.0.0.0
```

Then run the Flutter app from this directory:

```sh
flutter pub get
flutter run
```

The Android emulator uses `http://10.0.2.2:8000/api` by default. Flutter web on
the same computer uses `http://127.0.0.1:8000/api`.

To connect a physical phone or use another backend address, pass the API base
URL at launch (include `/api`):

```sh
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

The phone and development computer must be on the same network, and the
computer's firewall must allow the backend port. The API also accepts
cross-origin requests from Flutter web.

To run the web version on this computer, use `flutter run -d chrome`.

To build an Android APK for a presentation:

```sh
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Replace the example address with the backend computer's LAN IP. The APK is
written to `build/app/outputs/flutter-apk/app-debug.apk`. The debug build
allows HTTP connections for local backend demos; use HTTPS for release builds.
