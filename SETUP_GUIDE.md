# GardNx — Complete Setup Guide

> Follow every step in order. Nothing is assumed. Takes about 30–45 minutes on a fresh PC.

---

## Table of Contents

1. [What you need to install first](#1-what-you-need-to-install-first)
2. [Clone the project](#2-clone-the-project)
3. [Create a Firebase project](#3-create-a-firebase-project)
4. [Register the Android app in Firebase](#4-register-the-android-app-in-firebase)
5. [Enable Firebase services](#5-enable-firebase-services)
6. [Download the Firebase credentials](#6-download-the-firebase-credentials)
7. [Deploy Firestore security rules](#7-deploy-firestore-security-rules)
8. [Set up the Python backend](#8-set-up-the-python-backend)
9. [Get API keys](#9-get-api-keys)
10. [Configure the .env file](#10-configure-the-env-file)
11. [Seed the database](#11-seed-the-database)
12. [Start the backend server](#12-start-the-backend-server)
13. [Set up the Flutter app](#13-set-up-the-flutter-app)
14. [Run on your phone](#14-run-on-your-phone)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. What you need to install first

Install all of these before doing anything else. After each one, open a **new** terminal and verify it works.

### Flutter SDK

1. Download from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\flutter` — **no spaces in the path**
3. Add `C:\flutter\bin` to your system PATH:
   - Search "environment variables" in the Start menu → Edit the system environment variables
   - Under User variables → select `Path` → Edit → New → type `C:\flutter\bin` → OK
4. **Open a new terminal** and verify:
   ```
   flutter --version
   ```
   Should say `Flutter 3.27.x` or higher.

> ⚠️ **PowerShell tip:** If you get "running scripts is disabled on this system" at any point, run this once:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

### Android Studio

1. Download from https://developer.android.com/studio
2. Install with default settings
3. Open Android Studio → SDK Manager → install:
   - Android SDK Platform **API 35** (or latest)
   - Android SDK Build-Tools
4. Run `flutter doctor` in a terminal — follow any extra steps it lists

### Java 17

Flutter's Gradle build requires Java 17.

1. Download JDK 17 from https://adoptium.net (Eclipse Temurin, JDK 17 LTS)
2. Install, then set the environment variable `JAVA_HOME` to the JDK folder (e.g. `C:\Program Files\Eclipse Adoptium\jdk-17.0.x`)
3. Also add `%JAVA_HOME%\bin` to PATH
4. Verify: `java -version` → should say `17.x`

### Python 3.11 or 3.12

1. Download from https://www.python.org/downloads/
2. **During install: check "Add Python to PATH"**
3. Verify: `python --version` → `3.11.x` or `3.12.x`

### Node.js (for Firebase CLI)

1. Download LTS from https://nodejs.org
2. Verify: `node --version` → `v18.x` or higher

### Firebase CLI

```bash
npm install -g firebase-tools
firebase --version
```

### Git

1. Download from https://git-scm.com/download/win
2. Verify: `git --version`

---

## 2. Clone the project

```bash
git clone https://github.com/KavishJoaheer/hello.git gardnx
cd gardnx
```

You should now have:
```
gardnx/
├── gardnx_app/       Flutter Android app
├── gardnx_backend/   Python FastAPI backend
└── firebase/         Firestore rules and indexes
```

---

## 3. Create a Firebase project

1. Go to https://console.firebase.google.com
2. Click **Add project**
3. Name it anything (e.g. `my-gardnx`)
4. Disable Google Analytics (not needed) → **Create project**
5. Wait ~30 seconds → **Continue**

Note your **Project ID** — it looks like `my-gardnx-ab12c`. You'll need it shortly.

---

## 4. Register the Android app in Firebase

1. In the Firebase Console, click the **Android icon** (Add app)
2. Enter this exact package name:
   ```
   com.ayushi.gardenaiplanner
   ```
3. App nickname: anything you like
4. Click **Register app**
5. **Download `google-services.json`**
6. Save it to:
   ```
   gardnx_app/android/app/google-services.json
   ```
   (Replace the placeholder file that is already there)
7. Click **Next** → **Next** → **Continue to console**

---

## 5. Enable Firebase services

In the Firebase Console, enable these one by one:

### Authentication
- Left sidebar → **Build → Authentication** → **Get started**
- Click the **Email/Password** provider → toggle **Enable** → **Save**

### Firestore Database
- Left sidebar → **Build → Firestore Database** → **Create database**
- Choose **Start in production mode** → **Next**
- Select any location (e.g. `europe-west`) → **Enable**
- Wait ~1 minute for provisioning

---

## 6. Download the Firebase credentials

The backend needs a service account key to talk to Firestore.

1. Firebase Console → ⚙️ **Project Settings** (gear icon, top left)
2. Click the **Service accounts** tab
3. Click **Generate new private key** → **Generate key**
4. Save the downloaded JSON file as:
   ```
   gardnx_backend/firebase-credentials.json
   ```

> 🔒 This file contains a private key. Never share it or commit it to Git. It is already in `.gitignore`.

---

## 7. Deploy Firestore security rules

This step configures who can read/write what in your database.

```bash
cd gardnx
firebase login          # opens a browser — sign in with your Google account
firebase use --add      # pick your Firebase project from the list
```

When prompted for an alias, type `default`.

Then deploy:
```bash
firebase deploy --only firestore
```

Expected output:
```
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!
```

---

## 8. Set up the Python backend

Open a terminal in the `gardnx_backend` folder:

```bash
cd gardnx_backend
```

### Create a virtual environment

```bash
python -m venv venv
```

### Activate it

**Command Prompt:**
```
venv\Scripts\activate.bat
```

**PowerShell:**
```powershell
.\venv\Scripts\Activate.ps1
```

> If PowerShell blocks the script, run this one-time fix first:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

After activation your prompt should start with `(venv)`.

### Install dependencies

```bash
pip install -r requirements.txt
```

Takes about 1–2 minutes.

---

## 9. Get API keys

All have free tiers. You need at minimum the **Gemini** key to get smart recommendations.

### Google Gemini — AI plant recommendations (recommended)
1. Go to https://aistudio.google.com/app/apikey
2. Sign in with Google → **Create API key** → copy it (starts with `AIza`)

### HuggingFace — garden photo analysis (optional)
1. Create a free account at https://huggingface.co
2. Go to **Settings → Access Tokens → New token**
3. Role: **Read** → **Generate** → copy the token (starts with `hf_`)

> If you skip this, set `USE_MOCK_MODEL=true` in the `.env` file. The app still works fully — it just uses simulated garden zones instead of real AI analysis.

### Perenual — global plant search (optional)
1. Go to https://perenual.com/docs/api → sign up → copy your key
2. Free tier: 100 requests/day. The built-in 40+ Mauritius plants do **not** need this.

---

## 10. Configure the .env file

Copy the example file and fill in your values:

```bash
# Command Prompt:
copy .env.example .env

# PowerShell:
Copy-Item .env.example .env
```

Open `.env` in Notepad and fill it in:

```env
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
FIREBASE_STORAGE_BUCKET=your-project-id.firebasestorage.app

USE_MOCK_MODEL=true
MODEL_WEIGHTS_PATH=./app/ml/weights/deeplabv3_garden.pth

HOST=0.0.0.0
PORT=8000
DEBUG=true

OPEN_METEO_BASE_URL=https://archive-api.open-meteo.com/v1/archive
PERENUAL_API_KEY=
GEMINI_API_KEY=paste-your-AIza-key-here
HF_API_TOKEN=
```

**Where to find `FIREBASE_STORAGE_BUCKET`:**
Firebase Console → ⚙️ Project Settings → General tab → scroll to "Default GCS bucket".
It looks like `your-project-id.firebasestorage.app`. Copy just the domain (no `gs://`).

> ✅ Keep `USE_MOCK_MODEL=true` for now. You can enable real AI segmentation later by setting it to `false` and adding your HuggingFace token.

---

## 11. Seed the database

This populates Firestore with 40+ plants and 80+ companion planting rules.

Make sure `(venv)` is still active, then:

```bash
python scripts/seed_database.py
```

Expected output:
```
=== Seeding plants ===
  [OK] plants/basil
  [OK] plants/bitter_gourd
  ... (40+ plants)
=== Seeding companion rules ===
  [OK] companion_rules/rule_001
  ...
Done.
```

> If you see `DeadlineExceeded` errors: Firestore is still provisioning. Wait 2–3 minutes and try again.

---

## 12. Start the backend server

Make sure `(venv)` is active, then:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Expected output:
```
INFO:     Firebase initialized successfully
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

**Verify it works** — open a browser and go to `http://localhost:8000/docs`. You should see Swagger API docs.

### Allow the firewall (required for phone access)

Open **Command Prompt as Administrator** and run:

```
netsh advfirewall firewall add rule name="GardNx Backend" dir=in action=allow protocol=TCP localport=8000
```

Or manually: Windows Defender Firewall → Advanced Settings → Inbound Rules → New Rule → Port → TCP → 8000 → Allow the connection.

---

## 13. Set up the Flutter app

Open a **new terminal** (keep the backend running in the other one).

### Find your PC's local IP address

```
ipconfig
```

Look for **IPv4 Address** under your Wi-Fi adapter. Example: `192.168.1.45`

Your phone and PC must be on the **same Wi-Fi network**.

### Set the backend URL in the Flutter app

Open:
```
gardnx_app/lib/config/constants/api_constants.dart
```

Find this section and replace the IP with yours:
```dart
static String get _defaultHost {
  if (kIsWeb) return 'localhost';
  if (Platform.isAndroid) return '192.168.1.45';  // ← your PC's IP here
  return 'localhost';
}
```

> **Using an emulator instead of a physical phone?** Use `10.0.2.2` instead — that's the emulator's alias for the host machine.

### Install Flutter dependencies

```bash
cd gardnx_app
flutter pub get
```

---

## 14. Run on your phone

### Enable USB debugging on Android

1. **Settings → About phone** → tap **Build number** 7 times
2. **Settings → Developer options** → enable **USB debugging**
3. Connect phone to PC via USB cable
4. Accept the "Allow USB debugging?" prompt on the phone

### Check Flutter sees your device

```bash
flutter devices
```

Your phone should appear in the list.

### Run the app

```bash
flutter run
```

First build takes 3–5 minutes. After that, hot-reload (`r` key) is instant.

### First launch checklist

- [ ] Splash screen → Login screen
- [ ] Register a new account (email + password)
- [ ] Dashboard shows empty garden list → tap "+" to create a garden
- [ ] Plant catalog tab shows 40+ plants
- [ ] Climate tab shows weather data
- [ ] Create a bed → get recommendations → select plants → Generate Layout → Save → Calendar tab shows tasks ✅

---

## 15. Troubleshooting

### ❌ Flutter not recognised ("flutter is not recognized as a command")
`C:\flutter\bin` is not in your PATH. Add it via system environment variables, then **open a new terminal**.

### ❌ PowerShell won't activate venv ("running scripts is disabled")
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Then try `.\venv\Scripts\Activate.ps1` again.

### ❌ Backend starts in mock mode even with `USE_MOCK_MODEL=false`
The `.env` file is missing or in the wrong folder. It must be at `gardnx_backend/.env` (not the `.env.example`). Restart uvicorn after any changes to `.env`.

### ❌ App can't connect to backend (timeout)
1. Check backend is running: `http://localhost:8000/docs` in a browser on the PC
2. Check the IP in `api_constants.dart` matches your current IP (`ipconfig`) — it changes when you reconnect to Wi-Fi
3. Check phone and PC are on the same Wi-Fi network
4. Check the firewall rule was added (step 12)

### ❌ "Could not auto-generate layout"
Make sure the backend is running. The error message shown includes details — check the backend terminal for the full stack trace.

### ❌ "No matching client found for package name"
Your `google-services.json` is from a different Firebase project. Re-download it from Firebase Console → Project Settings → Your apps → the `com.ayushi.gardenaiplanner` entry.

### ❌ Firestore PERMISSION_DENIED
Run `firebase deploy --only firestore` from inside the `gardnx/` folder. Make sure you linked the CLI to your project first with `firebase use --add`.

### ❌ Plant catalog is empty
The database has not been seeded. Run (with venv active):
```bash
cd gardnx_backend
python scripts/seed_database.py
```

### ❌ Calendar tab is empty
The calendar is generated only after you **save a layout**. Complete the full flow: create garden → create bed → get recommendations → select plants → auto-generate → save layout.

### ❌ App crashes: "Default FirebaseApp is not initialized"
`google-services.json` is missing or in the wrong place. It must be at `gardnx_app/android/app/google-services.json`.

### ❌ Gradle build fails: "SDK location not found"
Set the `ANDROID_HOME` environment variable to your Android SDK path. Find it in Android Studio → SDK Manager. Usually `C:\Users\YourName\AppData\Local\Android\Sdk`.

---

## Environment variables quick reference

| Variable | Required | Notes |
|---|---|---|
| `FIREBASE_CREDENTIALS_PATH` | ✅ | Path to service account JSON |
| `FIREBASE_STORAGE_BUCKET` | ✅ | `your-project-id.firebasestorage.app` |
| `USE_MOCK_MODEL` | ✅ | `true` = skip real ML (recommended for dev) |
| `HOST` | ✅ | Must be `0.0.0.0` so phone can connect |
| `PORT` | ✅ | `8000` |
| `DEBUG` | ✅ | `true` for development |
| `OPEN_METEO_BASE_URL` | ✅ | Leave as default |
| `GEMINI_API_KEY` | optional | Smart plant recommendations |
| `PERENUAL_API_KEY` | optional | Global plant search only |
| `HF_API_TOKEN` | optional | Only needed if `USE_MOCK_MODEL=false` |

---

*Last updated: March 2026*
