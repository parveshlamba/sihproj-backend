# Legal Metrology Compliance Checker — Mobile App

## What's in this build
- **Login screen** — mocked auth (any email/password works), role picker
  (Inspector/Controller/Admin). Not wired to a real backend yet — see
  `lib/services/auth_service.dart`.
- **Home screen** — entry point, quick stats placeholder, logout button.
- **Scan screen** — camera capture or gallery upload of a product label.
- **Real on-device OCR** (`lib/services/ocr_service.dart`) — uses Google
  ML Kit's text recognizer to actually read the text off the photo you take.
  Runs fully on-device, no internet or backend needed.
- **Rule-based compliance engine** (`lib/services/compliance_engine.dart`) —
  runs regex/keyword checks against the real OCR text to evaluate MRP, Net
  Quantity, Mfg Date, Address, and Consumer Care declarations. This is a
  first-pass rule set for demo purposes, not a certified legal
  interpretation — tune the regexes as you test against real labels.
- **Result screen** — per-declaration compliance checklist, expandable tiles
  showing extracted text, confidence score, rule reference, plus a "Raw
  extracted text" panel showing exactly what OCR read off the label.

### ⚠️ Real scanning only works on Android/iOS, not web
`google_mlkit_text_recognition` has no web implementation. If you run this
with `flutter run -d chrome`, tapping "Check Compliance" shows a clear error
dialog instead of a fake result. Always test the actual scan flow on your
physical phone via `flutter run` over USB.

## Setup

```bash
flutter pub get
flutter run
```

If `pub get` fails to resolve `google_mlkit_text_recognition`, run
`flutter pub add google_mlkit_text_recognition` instead — it'll pick the
latest version compatible with your Flutter SDK.

## Required platform permissions

**Android** — `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

Also check `android/app/build.gradle` — ML Kit requires
`minSdkVersion 21` or higher (Flutter's default template already sets this,
but confirm if `flutter run` errors out during the Android build).

**iOS** — `ios/Runner/Info.plist`, inside the top-level `<dict>`:
```xml
<key>NSCameraUsageDescription</key>
<string>Needed to scan product labels</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Needed to upload product label images</string>
```

## How scanning actually works now
1. You take/upload a photo on the Scan screen.
2. `OcrService` runs Google ML Kit's on-device text recognizer on the image
   and returns the raw text it found.
3. `ComplianceEngine` runs regex/keyword rules against that text for each
   declaration type and builds a `Declaration` object with a compliance
   verdict, the matched text, a confidence score, and the relevant rule
   reference.
4. The Result screen renders those as a checklist, plus a "Raw extracted
   text" panel so you can see exactly what OCR read — useful for debugging
   when a check misfires because of a misread character.

## Tips for getting good OCR results while testing
- Good, even lighting; avoid glare on glossy packaging.
- Fill the frame with the label — don't include much background.
- Hold the phone parallel to the label (avoid an angled/skewed shot).
- Flatten curved packaging (bottles/pouches) as much as possible.

## Not yet built (next steps)
- [ ] Wire login to a real backend (currently mocked, any credentials work)
- [ ] History/repository screen (list + search past scans)
- [ ] PDF report export (`pdf` + `printing` packages, hooked into
      the "Export Report" button in `result_screen.dart`)
- [ ] Font size / readability check (needs a size reference — e.g. barcode
      or a known object in frame — to convert pixels to real-world mm)
- [ ] Bounding-box detection model to localize each declaration on the
      label before OCR (current version OCRs the whole image at once)
- [ ] Manual correction dialog for officer overrides on misreads
- [ ] Web dashboard for enforcement officials

## Project structure
```
lib/
├── main.dart
├── models/            # Declaration, ScanResult, AppUser
├── services/
│   ├── ocr_service.dart          # real on-device OCR (ML Kit)
│   ├── compliance_engine.dart    # real rule-based compliance checks
│   ├── api_service.dart          # orchestrates OCR + rules; history still mocked
│   └── auth_service.dart         # mocked login
├── screens/
│   ├── auth/
│   ├── home/
│   ├── scan/
│   └── result/
└── widgets/           # DeclarationTile, ComplianceBadge
```
