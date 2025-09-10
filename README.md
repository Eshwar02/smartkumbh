SmartKumbh
SmartKumbh is a Flutter app for quick onboarding at large gatherings. It lets people fill basic details, generate a personal QR, see their location on a map, and trigger an SOS flow—fast and simple.

What you get
Fast sign‑in form (no password)

Personal QR code generated on the device

Live map with current location (OpenStreetMap tiles)

SOS screen with triple‑tap confirmation

Profile and info screens

Clean dark theme with smooth animations

Screens
Splash

Login

Home (QR, Info, SOS, Map)

Profile (with logout)

Full‑screen Map

Features (frontend only)
On‑device QR: The QR image is rendered locally, so the QR page works even without internet.

Location map: Map uses OpenStreetMap via flutter_map with a recenter button and a simple current‑location marker.

Autocomplete inputs: State and City fields include type‑ahead pickers for quick selection.

Validation:

Phone must be exactly 10 digits

Aadhaar requires last 4 digits

Family members field accepts only numbers

Local session cache: After first login, the app opens straight to the main shell; logout clears the session.

Neumorphic cards + Material 3: Soft UI components, rounded surfaces, and a consistent dark palette.

Smooth transitions: Custom fade + slide route animations for page changes and a subtle splash fade.

Accessibility basics: Large tap targets, clear labels, and good contrast in dark mode.

Offline‑friendly UX: Most UI works offline; the map needs network for tiles, but the app stays responsive.

Lightweight deps:

flutter_map + latlong2 (maps)

geolocator (location)

qr_flutter (QR rendering)

shared_preferences (local cache)

Map and attribution
This app uses OpenStreetMap tiles. Please keep attribution visible if you change the UI.

Tiles: https://tile.openstreetmap.org/{z}/{x}/{y}.png

Attribution shown in‑app: “OpenStreetMap contributors”

A user‑agent string is set in the tile layer so map servers can identify the app.

Project structure (short)
lib/main.dart — all widgets, services, navigation, and theme live here for now

assets/logo.png — app logo for the splash

Setup
Install Flutter and set up Android/iOS tooling.

Clone the repo and fetch packages:

bash
git clone https://github.com/<your-username>/smartkumbh.git
cd smartkumbh
flutter pub get
Run:

bash
flutter run
Permissions
Location access is required to show “My Location” on the map.

Android (AndroidManifest.xml):

xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
iOS (Info.plist):

xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to show your position on the map.</string>
Troubleshooting
Map tiles don’t appear

Check network connectivity and try again. Emulators sometimes block traffic or have DNS hiccups.

“My Location” not shown

Accept the permission prompt and ensure location services are enabled on the device/emulator.

App opens straight to Home after reinstall

Clear app data or use the Logout button to reset the local session cache.

Build commands
bash
# Analyze and format
flutter analyze
dart format .

# Android release (APK)
flutter build apk --release

# iOS release (from macOS)
flutter build ios --release
Roadmap
Multi‑language UI copy

Map layers and POIs for event zones

Better offline behavior (map tile caching)

QR scanner view for checkpoints

Unit and widget tests

Contributing
Issues and PRs are welcome. Please keep PRs small and focused. If you change UI behavior, include a short screen recording or screenshots.

License
Add your preferred license (e.g., MIT) in a LICENSE file at the repo root.

Credits
OpenStreetMap contributors

Flutter community and package authors (flutter_map, geolocator, qr_flutter, shared_preferences)
