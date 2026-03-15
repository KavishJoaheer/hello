# MYGarden Planner — Complete Setup & Developer Guide

> This document covers everything needed to install, configure, and run the MYGarden Planner project
> on a brand-new PC with a brand-new Firebase account. No prior knowledge of the existing setup is
> required. Follow every step in order.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [How This Project Was Built](#2-how-this-project-was-built)
3. [Architecture](#3-architecture)
4. [Prerequisites — Install These First](#4-prerequisites--install-these-first)
5. [Step 1 — Clone / Copy the Project](#5-step-1--clone--copy-the-project)
6. [Step 2 — Create a New Firebase Project](#6-step-2--create-a-new-firebase-project)
7. [Step 3 — Register the Android App in Firebase](#7-step-3--register-the-android-app-in-firebase)
8. [Step 4 — Enable Firebase Services](#8-step-4--enable-firebase-services)
9. [Step 5 — Download Service Account Key (for backend)](#9-step-5--download-service-account-key-for-backend)
10. [Step 6 — Install Firebase CLI and Deploy Rules](#10-step-6--install-firebase-cli-and-deploy-rules)
11. [Step 7 — Set Up the Python Backend](#11-step-7--set-up-the-python-backend)
12. [Step 8 — Get API Keys](#12-step-8--get-api-keys)
13. [Step 9 — Configure the Backend .env File](#13-step-9--configure-the-backend-env-file)
14. [Step 10 — Seed the Database](#14-step-10--seed-the-database)
15. [Step 11 — Start the Backend Server](#15-step-11--start-the-backend-server)
16. [Step 12 — Set Up the Flutter App](#16-step-12--set-up-the-flutter-app)
17. [Step 13 — Configure the Backend URL in Flutter](#17-step-13--configure-the-backend-url-in-flutter)
18. [Step 14 — Run the App](#18-step-14--run-the-app)
19. [Project File Reference](#19-project-file-reference)
20. [Environment Variables Reference](#20-environment-variables-reference)
21. [Firestore Data Schema](#21-firestore-data-schema)
22. [API Endpoints Reference](#22-api-endpoints-reference)
23. [Troubleshooting](#23-troubleshooting)

---

## 1. Project Overview

**MYGarden Planner** is a mobile garden planning application for Mauritius home gardeners.

| What it does | How |
|---|---|
| Photo analysis | User takes a garden photo → backend segments it into sunny/shady/soil zones |
| Plant recommendations | Based on zones, season, region → ranked plant list from 40+ Mauritius-curated plants |
| Layout planning | Drag-and-drop grid editor with spacing and companion planting rules |
| Planting calendar | Month-by-month task schedule generated from the layout |
| Plant database | 40+ plants + 80+ companion rules curated for Mauritius conditions |
| Climate data | Open-Meteo API — free historical weather per GPS location |

**Platform:** Android only (physical device or emulator, API 24+)

**Repository structure:**
```
GardNx/
├── gardnx_app/          Flutter Android app (Dart)
├── gardnx_backend/      Python FastAPI backend
└── firebase/            Firestore rules, indexes, firebase.json
```

---

## 2. How This Project Was Built

### Technology Choices

| Layer | Technology | Why |
|---|---|---|
| Mobile app | Flutter 3.27 + Dart 3.6 | Cross-platform, single codebase, Material 3 UI |
| State management | Riverpod 2.x | Compile-safe providers, no BuildContext required |
| Navigation | GoRouter 14.x | Declarative routing with auth redirect support |
| Backend | Python 3.11 + FastAPI | Async, auto-docs, easy ML integration |
| Database | Firebase Firestore | Real-time sync, offline support, no server management |
| Authentication | Firebase Auth (email/password) | Secure, no custom auth server needed |
| Plant catalog | Perenual API (free tier) | 10,000+ plant database with images |
| Smart recommendations | Gemini API (cloud) / Ollama+Gemma (local) / Rule-based fallback | Three-tier: always works offline |
| Climate data | Open-Meteo | Free, no API key, historical Mauritius weather |
| Photo analysis | HuggingFace segformer-b0-finetuned-ade-512-512 | Garden zone detection |

### Project Structure — Flutter App

```
gardnx_app/lib/
├── config/
│   ├── constants/api_constants.dart     Backend URL and endpoint paths
│   ├── routes/app_router.dart           All routes + auth redirect logic
│   └── theme/                           App colours and typography
├── features/
│   ├── auth/                            Login, register, splash screens
│   ├── home/                            Dashboard, garden list, bottom nav
│   ├── garden_analysis/                 Camera capture, zone overlay, result
│   ├── layout_planner/                  Recommendations, grid editor
│   ├── manual_input/                    Fallback drawing tool
│   ├── calendar/                        Planting calendar, tasks
│   ├── plant_database/                  Plant catalog with search/filter
│   ├── climate/                         Weather data display
│   ├── profile/                         User preferences, sign-out
│   └── onboarding/                      First-launch walkthrough
└── shared/
    └── providers/firebase_providers.dart   Firebase singleton providers
```

Each feature follows clean architecture:
```
feature/
├── data/repositories/     API calls + Firestore reads/writes
├── domain/models/         Dart data classes (Freezed or manual)
└── presentation/
    ├── providers/         Riverpod providers
    ├── screens/           Full-page widgets
    └── widgets/           Reusable UI components
```

### Project Structure — Python Backend

```
gardnx_backend/
├── app/
│   ├── api/v1/endpoints/
│   │   ├── analysis.py      POST /analysis/upload, /segment, /result
│   │   ├── plants.py        GET /plants/catalog, /search, /engine-status
│   │   ├── layout.py        POST /layout/generate, /validate, /recommend
│   │   ├── calendar.py      POST /calendar/generate, /tasks
│   │   └── climate.py       GET /climate/current, /monthly
│   ├── models/              Pydantic request/response models
│   ├── services/
│   │   ├── plant_recommender.py        Rules-based plant scoring
│   │   ├── layout_generator.py         Grid placement algorithm
│   │   ├── companion_checker.py        Static companion planting rules
│   │   ├── gemini_companion_checker.py Gemini-powered companion check
│   │   ├── calendar_generator.py       Task schedule generation
│   │   └── climate_service.py          Open-Meteo integration
│   ├── ml/
│   │   └── hf_garden_analyzer.py       HuggingFace segmentation model
│   └── data/
│       ├── plants_mauritius.json        40+ plant definitions
│       ├── companion_rules.json         80+ companion planting rules
│       └── mauritius_regions.json       4 regional climate profiles
├── scripts/
│   └── seed_database.py                Populates Firestore from JSON files
├── .env                                Your local environment variables (never commit)
├── firebase-credentials.json           Firebase service account key (never commit)
└── requirements.txt                    Python dependencies
```

### Key Design Decisions

1. **No Firebase Storage** — Profile photos are stored locally on the device using `path_provider`. This avoids Firebase Storage costs (requires Blaze paid plan).

2. **Three-tier recommendation engine** — The app tries Gemini (cloud AI) first, falls back to Ollama+Gemma (local LLM), then falls back to rule-based scoring. The user can also manually select which engine to use in the UI.

3. **Anonymous backend auth** — The backend uses Firebase Admin SDK. Since the app does not yet send Firebase ID tokens with requests, the backend accepts anonymous users (logs a warning but does not block). This is intentional for the current development stage.

4. **Mock ML mode** — The backend can run with `USE_MOCK_MODEL=true` which returns dummy segmentation data. This lets you develop and test without a GPU or model weights file.

5. **Mauritius-specific plant data** — All 40+ plants in `plants_mauritius.json` were curated for Mauritius growing conditions (tropical/subtropical climate, local varieties). The data includes sowing months, spacing, companion plants, and regional suitability.

---

## 3. Architecture

```
┌─────────────────────────────────────────────┐
│              Android Phone / Emulator        │
│                                             │
│  Flutter App (Riverpod + GoRouter)          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Firebase │  │ Firebase │  │  HTTP    │  │
│  │   Auth   │  │Firestore │  │  (Dio)   │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
└───────┼─────────────┼─────────────┼─────────┘
        │             │             │
        ▼             ▼             ▼
   Firebase Auth  Firestore DB   FastAPI Backend
   (cloud)        (cloud)        (your PC, port 8000)
                                      │
                              ┌───────┼────────┐
                              ▼       ▼        ▼
                          Gemini   Ollama   Open-Meteo
                          (cloud)  (local)  (free API)
```

**Data flow — Plant Recommendations:**
1. Flutter sends POST `/layout/recommend` with bed size, sun exposure, season, region
2. Backend scores all 40+ plants from `plants_mauritius.json`
3. Returns top 15 ranked suggestions
4. User selects plants → Flutter sends POST `/layout/generate`
5. Backend runs greedy grid placement algorithm → returns `PlantPlacement[]`
6. Flutter renders the grid in `LayoutEditorScreen`
7. User saves → Flutter saves layout to Firestore + calls `/calendar/generate`
8. Calendar events saved to `gardens/{id}/events/`

---

## 4. Prerequisites — Install These First

Install all of these on the new PC before doing anything else.

### 4a. Flutter SDK

1. Go to https://flutter.dev/docs/get-started/install/windows
2. Download Flutter SDK (version **3.27 or later**)
3. Extract to `C:\flutter` (no spaces in path)
4. Add `C:\flutter\bin` to your system PATH
5. Verify: open a new terminal and run:
   ```
   flutter --version
   ```
   You should see `Flutter 3.27.x` or higher.

### 4b. Android Studio

1. Download from https://developer.android.com/studio
2. Install with default settings
3. Open Android Studio → SDK Manager → install:
   - Android SDK Platform **API 35** (or latest)
   - Android SDK Build-Tools
   - Android Emulator (optional — only needed if no physical device)
4. Run `flutter doctor` in terminal — follow any instructions it gives

### 4c. Java / JDK

Flutter's Gradle needs Java 17.

1. Download JDK 17 from https://adoptium.net (Eclipse Temurin, JDK 17 LTS)
2. Install and set `JAVA_HOME` environment variable to the JDK folder
3. Add `%JAVA_HOME%\bin` to PATH
4. Verify: `java -version` → should say `17.x`

### 4d. Python 3.11+

1. Download from https://www.python.org/downloads/ (version **3.11 or 3.12**)
2. During install: **check "Add Python to PATH"**
3. Verify: `python --version` → should say `3.11.x` or `3.12.x`

### 4e. Node.js (for Firebase CLI)

1. Download from https://nodejs.org (LTS version, 18+)
2. Install with default settings
3. Verify: `node --version` → `v18.x` or higher

### 4f. Firebase CLI

```bash
npm install -g firebase-tools
firebase --version
```

### 4g. Git

1. Download from https://git-scm.com/download/win
2. Install with default settings
3. Verify: `git --version`

---

## 5. Step 1 — Clone / Copy the Project

### Option A — Copy from USB / shared folder

Copy the entire `GardNx/` folder to your PC, e.g. `C:\Users\YourName\GardNx\`

### Option B — Git repository

```bash
git clone <your-repo-url> GardNx
cd GardNx
```

After copying, you should have:
```
GardNx/
├── gardnx_app/
├── gardnx_backend/
└── firebase/
```

---

## 6. Step 2 — Create a New Firebase Project

1. Go to https://console.firebase.google.com
2. Click **Add project**
3. Enter a project name, e.g. `mygarden-planner`
4. Disable Google Analytics (not needed) → click **Create project**
5. Wait for provisioning (~30 seconds) → click **Continue**

**Note your Project ID** — it looks like `mygarden-planner-ab12c`. You will need it later.

---

## 7. Step 3 — Register the Android App in Firebase

1. In the Firebase Console, click the **Android** icon (Add app)
2. Enter the Android package name:
   ```
   com.ayushi.gardenaiplanner
   ```
   > This must match exactly. It is set in `gardnx_app/android/app/build.gradle.kts` as `applicationId`.
3. App nickname: `MYGarden Planner` (optional)
4. Click **Register app**
5. Click **Download google-services.json**
6. Place the downloaded file at:
   ```
   GardNx/gardnx_app/android/app/google-services.json
   ```
   (Replace the existing file)
7. Click **Next** through the remaining steps (the SDK is already configured in the code)

---

## 8. Step 4 — Enable Firebase Services

In your Firebase Console project, enable these three services:

### 8a. Authentication

1. Left sidebar → **Authentication** → **Get started**
2. **Sign-in method** tab → click **Email/Password**
3. Toggle **Enable** → click **Save**

### 8b. Firestore Database

1. Left sidebar → **Firestore Database** → **Create database**
2. Choose **Start in production mode** (rules will be deployed in Step 6)
3. Choose a region — recommended: `us-central1` (or `europe-west1` for lower latency from Mauritius)
4. Click **Create**
5. Wait for the database to provision (~1 minute)

### 8c. Firebase Cloud Messaging (optional — for push notifications)

FCM is already integrated in the app. No extra setup needed unless you want to send notifications.

---

## 9. Step 5 — Download Service Account Key (for backend)

The Python backend uses Firebase Admin SDK to read/write Firestore. It needs a private key.

1. In Firebase Console → **Project Settings** (gear icon, top left)
2. Click the **Service accounts** tab
3. Click **Generate new private key** → **Generate key**
4. A JSON file downloads — rename it to:
   ```
   firebase-credentials.json
   ```
5. Place it at:
   ```
   GardNx/gardnx_backend/firebase-credentials.json
   ```

> **IMPORTANT:** Never commit this file to Git. It contains your private key. It is already listed in `.gitignore`.

---

## 10. Step 6 — Install Firebase CLI and Deploy Rules

### 10a. Log in to Firebase CLI

```bash
firebase login
```

A browser window opens — log in with the same Google account used to create the Firebase project.

### 10b. Link project to firebase directory

```bash
cd GardNx/firebase
firebase use --add
```

Select your project from the list. Enter an alias like `default` when prompted.

If `--add` fails interactively, run:
```bash
firebase use your-project-id
```
(Replace `your-project-id` with your actual Firebase Project ID)

### 10c. Deploy Firestore rules and indexes

```bash
firebase deploy --only firestore
```

Expected output:
```
✔  firestore: released rules firestore.rules to cloud.firestore
✔  firestore: deployed indexes in firestore.indexes.json
```

This sets up the security rules so only authenticated users can read/write their own data.

---

## 11. Step 7 — Set Up the Python Backend

### 11a. Create a virtual environment

```bash
cd GardNx/gardnx_backend
python -m venv venv
```

### 11b. Activate the virtual environment

**Windows:**
```bash
venv\Scripts\activate
```

**Mac/Linux:**
```bash
source venv/bin/activate
```

You should see `(venv)` appear at the start of your terminal prompt.

### 11c. Install dependencies

```bash
pip install -r requirements.txt
```

This installs FastAPI, Firebase Admin SDK, Gemini SDK, httpx, and all other backend dependencies. Takes 1–3 minutes.

---

## 12. Step 8 — Get API Keys

You need up to 3 API keys for full functionality. The app works without them but with reduced features.

### 12a. Gemini API Key (for smart recommendations — IMPORTANT)

1. Go to https://aistudio.google.com/app/apikey
2. Click **Create API key**
3. Copy the key (starts with `AIza...`)

Free tier: very generous, suitable for development and personal use.

### 12b. Perenual Plant API Key (for global plant search)

1. Go to https://perenual.com/docs/api
2. Sign up for a free account
3. Go to your profile → API key section → copy your key

Free tier: 100 requests/day. Used only for the global plant search feature. The main plant database (40+ Mauritius plants) does NOT require this key.

### 12c. HuggingFace API Token (for garden photo analysis)

1. Go to https://huggingface.co and create a free account
2. Go to **Settings** → **Access Tokens** → **New token**
3. Name it anything → select **Read** role → **Generate**
4. Copy the token (starts with `hf_...`)

Used for the garden segmentation model. If you set `USE_MOCK_MODEL=true` in `.env`, this is not needed.

---

## 13. Step 9 — Configure the Backend .env File

Create the `.env` file in `GardNx/gardnx_backend/`:

```bash
cd GardNx/gardnx_backend
```

Create a file named `.env` with the following content (replace all `your-...` values):

```env
# Firebase
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json
FIREBASE_STORAGE_BUCKET=your-project-id.firebasestorage.app

# ML Model — set to true to skip real model (recommended unless you have GPU)
USE_MOCK_MODEL=true
MODEL_WEIGHTS_PATH=./app/ml/weights/deeplabv3_garden.pth

# Server
HOST=0.0.0.0
PORT=8000
DEBUG=true

# APIs
OPEN_METEO_BASE_URL=https://archive-api.open-meteo.com/v1/archive
PERENUAL_API_KEY=your-perenual-api-key-here
GEMINI_API_KEY=your-gemini-api-key-here
HF_API_TOKEN=your-huggingface-token-here
```

**How to find your `FIREBASE_STORAGE_BUCKET`:**
- Firebase Console → Project Settings → General tab
- Scroll to "Your apps" — look for the Storage bucket URL, e.g. `mygarden-planner-ab12c.firebasestorage.app`
- Use just the domain part (no `gs://` prefix)

> `USE_MOCK_MODEL=true` is recommended unless you have trained model weights. The app works fully in mock mode — it just returns simulated garden zones instead of real ones.

---

## 14. Step 10 — Seed the Database

This step populates Firestore with the 40+ plant definitions and 80+ companion rules.

Make sure your virtual environment is still active (`(venv)` in the prompt), then:

```bash
cd GardNx/gardnx_backend
python scripts/seed_database.py
```

Expected output:
```
=== Seeding plants ===
  [OK] plants/basil
  [OK] plants/bitter_gourd
  ... (39 more plants)
=== Seeding companion rules ===
  [OK] companion_rules/rule_001
  ... (80+ rules)
=== Seeding Mauritius regions ===
  [OK] regions/north
  [OK] regions/south
  [OK] regions/east
  [OK] regions/west
Done: N rules written.
```

If you see `DeadlineExceeded` errors: your Firestore database is still provisioning. Wait 2–3 minutes and run again.

To preview without writing (dry run):
```bash
python scripts/seed_database.py --dry-run
```

---

## 15. Step 11 — Start the Backend Server

Make sure the virtual environment is active, then:

```bash
cd GardNx/gardnx_backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Expected output:
```
INFO:     Started server process [XXXX]
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Application startup complete.
```

**Test the backend is working:**
Open a browser and go to: `http://localhost:8000/docs`

You should see the interactive API documentation (Swagger UI) listing all endpoints.

### Important: `--host 0.0.0.0`

This makes the backend accessible from other devices on the same Wi-Fi network. Without it, only `localhost` can reach the backend, meaning a physical Android phone cannot connect.

---

## 16. Step 12 — Set Up the Flutter App

### 16a. Install dependencies

```bash
cd GardNx/gardnx_app
flutter pub get
```

This downloads all Flutter packages. Takes 1–3 minutes.

### 16b. Generate app icon

```bash
dart run flutter_launcher_icons
```

This generates the app icon from `assets/images/logo.png` for all Android resolutions.

---

## 17. Step 13 — Configure the Backend URL in Flutter

The Flutter app needs to know where the backend is running.

Open: `GardNx/gardnx_app/lib/config/constants/api_constants.dart`

Find this section:
```dart
static String get _defaultHost {
  if (kIsWeb) return 'localhost';
  if (Platform.isAndroid) return '192.168.100.19';  // ← change this
  return 'localhost';
}
```

Replace `192.168.100.19` with **your PC's local IP address**.

**How to find your PC's IP:**
- Windows: open Command Prompt → run `ipconfig` → look for `IPv4 Address` under your Wi-Fi adapter
- Example: `192.168.1.45`

Your phone and PC must be on **the same Wi-Fi network**.

**If running an Android emulator (not a physical phone):**
Use `10.0.2.2` instead — this is the emulator's alias for the host machine's localhost.

---

## 18. Step 14 — Run the App

### Physical Android device

1. On the Android phone: go to **Settings** → **About phone** → tap **Build number** 7 times to enable Developer Options
2. Go to **Settings** → **Developer options** → enable **USB debugging**
3. Connect phone to PC via USB cable
4. Accept the "Allow USB debugging?" prompt on the phone
5. In terminal:
   ```bash
   cd GardNx/gardnx_app
   flutter devices
   ```
   Your phone should appear in the list.
6. Run:
   ```bash
   flutter run
   ```

### Android emulator

1. Open Android Studio → **Device Manager** → **Create device**
2. Choose a phone (e.g. Pixel 6) → API 35 → Finish
3. Start the emulator
4. Run:
   ```bash
   flutter run
   ```

### First launch checklist

When the app opens:
- [ ] Splash screen shows logo then redirects to Login
- [ ] Register a new account with email + password
- [ ] Dashboard shows empty garden list — tap "+" to create a garden
- [ ] Plant catalog tab shows 40+ plants
- [ ] Climate tab shows weather data (needs internet)
- [ ] Navigate to a garden → create a bed → get plant recommendations

---

## 19. Project File Reference

| File | Purpose |
|---|---|
| `gardnx_app/lib/config/routes/app_router.dart` | All screen routes + auth redirect logic |
| `gardnx_app/lib/config/constants/api_constants.dart` | Backend URL — **edit this when changing PC or IP** |
| `gardnx_app/lib/shared/providers/firebase_providers.dart` | Firebase Auth, Firestore singletons |
| `gardnx_app/lib/features/auth/presentation/providers/auth_provider.dart` | Auth state stream |
| `gardnx_app/android/app/google-services.json` | Firebase config for Android — **replace when changing Firebase project** |
| `gardnx_app/android/app/build.gradle.kts` | Android app config (package name, SDK versions) |
| `gardnx_backend/.env` | Backend environment variables — **create this from .env.example** |
| `gardnx_backend/firebase-credentials.json` | Firebase service account key — **download from Firebase Console** |
| `gardnx_backend/app/data/plants_mauritius.json` | 40+ plant definitions for Mauritius |
| `gardnx_backend/app/data/companion_rules.json` | 80+ companion planting rules |
| `gardnx_backend/scripts/seed_database.py` | Populates Firestore with plant data |
| `firebase/firestore.rules` | Firestore security rules |
| `firebase/firestore.indexes.json` | Firestore composite indexes |
| `firebase/firebase.json` | Firebase CLI project config |

---

## 20. Environment Variables Reference

All variables go in `GardNx/gardnx_backend/.env`:

| Variable | Required | Description |
|---|---|---|
| `FIREBASE_CREDENTIALS_PATH` | Yes | Path to service account JSON key |
| `FIREBASE_STORAGE_BUCKET` | Yes | Firebase project storage bucket domain |
| `USE_MOCK_MODEL` | Yes | `true` = skip real ML model (recommended) |
| `MODEL_WEIGHTS_PATH` | No | Path to `.pth` weights file (only if `USE_MOCK_MODEL=false`) |
| `HOST` | Yes | `0.0.0.0` to allow LAN access |
| `PORT` | Yes | `8000` |
| `DEBUG` | Yes | `true` for development |
| `OPEN_METEO_BASE_URL` | Yes | Leave as default |
| `PERENUAL_API_KEY` | No | For global plant search (100 req/day free) |
| `GEMINI_API_KEY` | No | For smart recommendations (free tier available) |
| `HF_API_TOKEN` | No | For garden photo segmentation (free) |

---

## 21. Firestore Data Schema

```
Firestore Database
│
├── users/{uid}
│     displayName, email, region, gardeningLevel,
│     dietaryFocus, createdAt
│
├── gardens/{gardenId}
│     userId, name, area, location, createdAt, lastUpdated
│     │
│     ├── layouts/{layoutId}
│     │     gardenId, bedId, gridRows, gridCols, cellSizeCm,
│     │     placements[], savedAt
│     │
│     ├── events/{eventId}
│     │     gardenId, bedId, plantId, plantName, eventType,
│     │     date, notes, isCompleted
│     │
│     └── tasks/{taskId}
│           gardenId, bedId, title, description, taskType,
│           dueDate, isCompleted, completedAt, priority
│
├── plants/{plantId}
│     name, category, sunRequirement, sowMonths,
│     spacing{betweenPlants, betweenRows},
│     companionPlantIds[], imageUrl, careNotes, ...
│
├── companion_rules/{ruleId}
│     plant1, plant2, relationship, benefit
│
└── regions/{regionId}
      name, climate, soilType, averageRainfall
```

---

## 22. API Endpoints Reference

Base URL: `http://<your-pc-ip>:8000/api/v1`

| Method | Endpoint | Description |
|---|---|---|
| POST | `/analysis/upload` | Upload garden photo |
| POST | `/analysis/segment/{photo_id}` | Segment photo into zones |
| GET | `/analysis/result/{photo_id}` | Get segmentation result |
| GET | `/plants/catalog` | List plants with filters |
| GET | `/plants/search?q=` | Search plants (Perenual + local DB) |
| GET | `/plants/engine-status` | Check recommendation engine availability |
| GET | `/plants/{plant_id}` | Get single plant |
| POST | `/layout/recommend` | Get plant recommendations for a bed |
| POST | `/layout/generate` | Generate grid layout from selected plants |
| POST | `/layout/validate` | Check companion planting conflicts |
| POST | `/layout/spacing` | Calculate max plants for bed dimensions |
| GET | `/climate/current` | Current weather for lat/lon |
| GET | `/climate/monthly` | Monthly climate averages |
| POST | `/calendar/generate` | Generate planting event schedule |
| POST | `/calendar/tasks` | Generate task list from plants |

**Interactive docs** (while backend is running): `http://localhost:8000/docs`

---

## 23. Troubleshooting

### Flutter app won't build: "No matching client found for package name"

The `google-services.json` is from a different Firebase project or was registered with a different package name. Re-download it from Firebase Console → Project Settings → Your apps, and replace the file at `gardnx_app/android/app/google-services.json`.

### Flutter app can't connect to backend (timeout / no response)

1. Check the backend is running: open `http://localhost:8000/docs` in a browser on the PC
2. Check the IP in `api_constants.dart` matches your PC's current IP (`ipconfig`)
3. Check your phone and PC are on the same Wi-Fi network
4. Check Windows Firewall: allow inbound connections on port 8000
   - Windows Defender Firewall → Advanced settings → Inbound Rules → New Rule → Port → TCP → 8000

### Firestore `DeadlineExceeded` when seeding

The Firestore database is still provisioning after creation. Wait 2–3 minutes and run `seed_database.py` again.

### `flutter pub get` fails

Make sure Flutter SDK is on your PATH and you are using Flutter 3.27+:
```bash
flutter --version
flutter doctor
```
Follow any issues reported by `flutter doctor`.

### Backend starts but Gemini says "unavailable"

Check `GEMINI_API_KEY` in your `.env` file. The key should start with `AIza`. Get one from https://aistudio.google.com/app/apikey.

### Plants tab is empty

The database has not been seeded. Run:
```bash
cd GardNx/gardnx_backend
venv\Scripts\activate
python scripts/seed_database.py
```

### Gradle build fails: "SDK location not found"

Android SDK is not configured. Open Android Studio → SDK Manager → note the SDK path → set the `ANDROID_HOME` environment variable to that path.

### App crashes on launch: "Default FirebaseApp is not initialized"

The `google-services.json` is missing or incorrect. Make sure it is placed at `gardnx_app/android/app/google-services.json` and matches the Firebase project.

### Calendar tab shows empty

The calendar is populated only after you complete the full flow:
1. Create a garden → create a bed
2. Get plant recommendations → select plants → tap "Generate Layout"
3. In the layout editor → tap "Auto-Generate" or place plants manually
4. Tap the save/calendar button

After saving a layout, the calendar is generated automatically and the Calendar tab will show events.

---

## Quick Start Summary

```bash
# 1. Backend
cd GardNx/gardnx_backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
# create .env file (see Step 9)
# place firebase-credentials.json (see Step 5)
python scripts/seed_database.py
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 2. Flutter (new terminal)
cd GardNx/gardnx_app
# edit api_constants.dart — set your PC's IP
flutter pub get
dart run flutter_launcher_icons
flutter run
```

---

*Last updated: March 2026*
