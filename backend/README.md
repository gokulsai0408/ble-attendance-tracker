# BLE Attendance Backend

This backend is wired to the Flutter app through `API_BASE_URL`.

## Local setup

1. Copy `.env.example` to `.env`.
2. Fill in `FIREBASE_PROJECT_ID`, `FIREBASE_WEB_API_KEY`, and `GOOGLE_APPLICATION_CREDENTIALS`.
3. Run `npm install`.
4. Run `npm run dev` or `npm start`.

For the Android emulator, the Flutter app defaults to `http://10.0.2.2:3000`.
For a physical Android device, run Flutter with:

```sh
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:3000
```
