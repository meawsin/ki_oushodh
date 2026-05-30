# কি ঔষধ — Ki Oushodh

**An accessible medicine identifier for elderly and low-literacy users in Bangladesh.**

Ki Oushodh (কি ঔষধ — "What medicine?") lets users point their phone camera at any medicine blister pack or box and instantly hear what the medicine is and what it is used for — in Bangla or English.

---

## The Problem

Elderly and low-literacy individuals in Bangladesh routinely struggle to identify their own medicines. Blister pack text is small, pharmaceutical names are complex, and existing apps require typing or reading — skills that create barriers for a large portion of the population.

## The Solution

A frictionless scan-and-speak experience:
1. Open the app
2. Point the camera at a medicine strip
3. Tap once
4. The app speaks the result aloud in Bangla or English

No typing. No reading required. Works on low-end devices with poor internet.

---

## Features

- **Camera OCR** — on-device text recognition via Google ML Kit (no internet needed for scanning)
- **13,929 Bangladeshi medicines** — local database of BD brand names mapped to generic names, sourced from the [Assorted Medicine Dataset of Bangladesh](https://www.kaggle.com/datasets/ahmedshahriarsakib/assorted-medicine-dataset-of-bangladesh)
- **Wikipedia fallback** — for medicines not in the local DB (requires internet)
- **Text-to-Speech** — reads results aloud in Bangla (bn-BD) or English, with automatic fallback to English on devices without a Bengali voice pack
- **Natural TTS voice** — sanitized output (mg → milligram, ellipsis removed) at a warm speech rate; not robotic
- **Medicine-only validation** — rejects non-medicine packaging (chips, beverages, etc.)
- **30-day scan history** — saved locally, auto-deleted after 30 days; swipe to delete individual entries
- **Accessibility settings** — font size (Normal / Large / X-Large), dark/light mode, high contrast
- **Fully offline for BD medicines** — no API key, no cloud dependency for the core feature
- **Low-end device optimised** — 720p capture, single-shot (no streaming), memory-safe

---

## Screenshots

<p align="center">
  <img src="screenshots/ki_oushodh(Scanning).png" width="250" alt="Scanning Medicine Blister Pack" />
  <img src="screenshots/ki_oushodh(Result).png" width="250" alt="Medicine Result Screen (Dark Mode)" />
  <img src="screenshots/ki_oushodh(settings).png" width="250" alt="Accessibility Settings" />
</p>

<p align="center">
  <img src="screenshots/ki_oushodh(lightMode).png" width="250" alt="Scanner Screen (Light Mode)" />
  <img src="screenshots/ki_oushodh(lightModeResult).png" width="250" alt="Medicine Result Screen (Light Mode)" />
  <img src="screenshots/ki_oushodh(lightModeHistory).png" width="250" alt="30-Day Scan History" />
</p>

<p align="center">
  <img src="screenshots/ki_oushodh(lightModeFailed).png" width="250" alt="Error Handling & User Feedback" />
</p>

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State management | Riverpod |
| Camera | CameraX via `camera` package |
| OCR | Google ML Kit Text Recognition (Latin) |
| Local database | Hive (NoSQL) — adapter written manually, no build_runner required |
| Medicine lookup | Local JSON asset (13,929 entries) + Wikipedia REST API |
| Text-to-Speech | flutter_tts (OS native engine) |
| Preferences | shared_preferences |

---

## Architecture

Feature-first with MVVM pattern.

```
lib/
├── core/
│   ├── constants/      # Bangla translations map
│   ├── theme/          # Light / dark / high-contrast themes
│   └── utils/          # Date utils, 30-day history cleanup
├── data/
│   └── local/          # Hive setup
├── domain/
│   └── models/         # ScanResult, ScanHistoryModel + hand-written Hive adapter
├── features/
│   ├── scanner/        # Camera screen + ViewModel (3-step processing states)
│   ├── results/        # Results screen (TTS play/stop, copy to clipboard)
│   ├── history/        # 30-day history (swipe-to-delete, tap to re-read)
│   └── settings/       # Accessibility settings
└── services/
    ├── camera_service.dart
    ├── ocr_service.dart
    ├── llm_service.dart      # Local DB lookup + Wikipedia fallback
    ├── tts_service.dart      # TTS with sanitization + Bangla detection
    └── storage_service.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.3.0`
- Android SDK (minSdk 21)
- A physical Android device (camera required)

### Setup

```bash
git clone https://github.com/meawsin/ki_oushodh.git
cd ki_oushodh
flutter pub get
```

> No `build_runner` step needed — the Hive adapter is written manually in `scan_history_model.g.dart`.

### Run

```bash
flutter run
```

### Build release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Bangla Text-to-Speech

The app detects whether the device has Bengali TTS installed. If not, it automatically falls back to reading the English summary aloud — silence is never used as a fallback, and Unicode is never passed to an engine that can't render it.

**To enable Bangla speech on your device:**
Play Store → Google Text-to-Speech → Settings → Install voice data → Bengali

---

## Data Source

Medicine data sourced from the [Assorted Medicine Dataset of Bangladesh](https://www.kaggle.com/datasets/ahmedshahriarsakib/assorted-medicine-dataset-of-bangladesh) on Kaggle — 21,714 medicines from 220+ Bangladeshi manufacturers.

---

## Scope — Iteration 1

**In scope:**
- Language toggle (Bangla / English)
- Camera capture + on-device OCR
- Medicine identification from local database
- Text-to-Speech result readout
- 30-day scan history with swipe-to-delete
- Accessibility settings (font size, theme, contrast)

**Intentionally excluded (future versions):**
- Dosage / frequency instructions (regulatory liability)
- User accounts or cloud sync
- Barcode / QR scanning
- Languages beyond Bangla and English

---

## License

MIT License — see [LICENSE](LICENSE)

---

## Built With

Built in collaboration with [Claude](https://claude.ai) (Anthropic).