**SmartKumbh**

**Team ID: TH1952**

**1. Overview**

SmartKumbh is a mobile application designed to improve safety and convenience during large gatherings such as the Kumbh Mela. The app helps users sign in quickly without passwords, generate a personal QR code that works even offline, view their live location on a map, and raise an SOS alert in case of emergencies. It is lightweight, accessible, and user-friendly, ensuring a smooth experience for both visitors and organizers.

**2. Problem & Solution**

_Problem Statement:_
Events like the Kumbh Mela bring together millions of people, often leading to problems such as people getting lost, difficulty in identification, poor connectivity, and delays in emergency assistance.

_Solution:_
SmartKumbh provides a simple yet effective solution through a mobile app. It allows quick onboarding, generates offline QR codes for identity verification, provides live location tracking using GPS, and enables an SOS alert feature for emergencies. This ensures better safety, quicker responses, and improved crowd management.

**3. Logic & Workflow**

_Data Collection:_
Basic user information (name, phone number, Aadhaar details, family members) collected during sign-up. Location accessed with the user’s permission.

_Processing:_
QR codes are generated directly on the device, ensuring they work without internet access. Location data is processed using GPS and OpenStreetMap. Session data is stored locally for faster access.

_Output:_
Users receive a personal QR code, real-time location on the map, and the ability to send SOS alerts.

_User Side:_
Quick login, personal QR code, live location map, SOS feature, and profile management.

_Admin Side:_
Verification of users by scanning QR codes, receiving SOS alerts, and monitoring crowd flow to support better management.

**4. Tech Stack**

-> Frontend: Flutter (Material Design 3 + Neumorphic UI)

-> Backend: Firebase or Supabase (Authentication, Database, Cloud Storage)

-> Database: Firestore (Firebase) or PostgreSQL (Supabase)

-> Maps & Location: OpenStreetMap and Geolocator

-> Utilities: SharedPreferences (local storage), QR Flutter (QR code generation)

**5. Future Scope**

Adding offline map support for areas with poor connectivity.

AI-based crowd monitoring and prediction for safety.

A dashboard for organizers to manage crowd flow and SOS alerts.

Scaling the app for other large events such as concerts, fairs, and religious gatherings.
