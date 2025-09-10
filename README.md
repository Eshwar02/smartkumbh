SmartKumbh — Round 2 Prototype
Team: <TeamName>    TeamID: <TeamID>
Public repo: https://github.com/<your-org>/<repo-name>

One-line summary:
SmartKumbh is a devotional-event assistant for Ujjain MahaKumbh — live map, QR check-ins, emergency SOS, user profiles.

How to run (short):
1. Clone repo: git clone https://github.com/...
2. cd repo
3. flutter pub get
4. Add firebase config:
   - android: place google-services.json into android/app/
   - iOS: place GoogleService-Info.plist into ios/Runner/
5. (Mapbox) Set public token in lib/config.dart or in environment variable MAPBOX_TOKEN (do NOT commit secret keys).
6. flutter run

Key features implemented:
- Splash + login + local session persistence
- QR generation + upload to Firebase Storage
- Firestore user doc creation
- Full-screen Mapbox map with recenter
- SOS with triple tap confirmation

Repo link: https://github.com/<your-org>/<repo-name>

Contact: <Team Lead Name and Email>
