# Real Estate Flutter App

## Setup

```bash
cd server
npm install
```

```bash
flutter pub get
```

## Run

**Terminal 1 — API**

```bash
cd server
npm start
```

**Terminal 2 — app**

```bash
flutter run
```

Physical device (replace with your PC’s LAN IP):

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
```
