**SmartKumbh**

SmartKumbh is a Flutter app built to make onboarding easier at large gatherings like the Kumbh Mela. With it, people can quickly enter their details, generate a personal QR code, view their live location on a map, and raise an SOS alert if needed. The app is designed to be simple, fast, and offline-friendly.

**What the app does:**

-> Quick login form without any passwords

-> Generates a personal QR code directly on the device

-> Shows your current location on a live map using OpenStreetMap

-> SOS screen with a triple-tap confirmation flow

-> Profile screen with a logout option

-> Dark theme with smooth animations throughout

**Screens included:**

-> Splash screen

-> Login screen

-> Home screen (QR, Info, SOS, Map)

-> Profile screen

-> Full screen map

**Features:**

>> The QR code is created on the device itself, so it works even without internet. The map uses OpenStreetMap tiles and includes a recenter button with a simple current location marker.

>> The login form includes type-ahead inputs for state and city, plus some basic validation rules. Phone number must be 10 digits, Aadhaar only asks for the last four digits, and the family members field accepts only numbers.

>> Once a person logs in, their session is stored locally, so next time the app opens directly to the home screen. Logging out clears this session.

>> The design uses a mix of neumorphic cards and Material 3 widgets with a consistent dark theme. Page transitions have smooth fade and slide animations. The app also follows accessibility basics with large buttons, clear text, and good contrast.

>> Most of the app works offline. The map needs internet for tiles, but the rest of the interface stays usable without network.

**Map and attribution:**

The app uses tiles from OpenStreetMap. The attribution is shown in-app as “OpenStreetMap contributors.” A user agent is also set so the map servers can recognize the app.

**Project structure:**

lib/main.dart contains all widgets, navigation, and theme for now

assets/logo.png is used for the splash screen

**__How to run__**

1. Install Flutter and set up Android or iOS tooling.

2. Clone this repository and fetch the dependencies:

3. git clone https://github.com/<your-username>/smartkumbh.git
cd smartkumbh
flutter pub get


**Run the app:**

flutter run

**Permissions:**

Location access is required to show the current position on the map.

**On Android, add the following to AndroidManifest.xml:**

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>


**On iOS, add this to Info.plist:**

<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to show your position on the map.</string>

**Common issues:**

If map tiles are not loading, check the internet connection. Emulators sometimes block map traffic.

If your location does not appear, make sure to allow location permission and enable location services on the device.

If the app opens directly to the home screen after reinstall, clear app data or log out to reset the session.

**Build commands**

To analyze and format the project:

flutter analyze
dart format .


**To build a release version for Android:**

flutter build apk --release


**To build for iOS (on macOS):**

flutter build ios --release

**Roadmap**

**>>**More map layers and points of interest for event zones

**>>** Offline map tile caching

**>>** QR scanner for checkpoints

**>>** Unit and widget testing


**Credits**

OpenStreetMap contributors

Flutter community and package authors: flutter_map, geolocator, qr_flutter, shared_preferences
