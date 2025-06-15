# health-tracker-app
A cross-platform Flutter application for tracking user health data via HealthKit/Google Fit, with Firebase authentication, user questionnaire, and health insights dashboard.

🩺 Flutter Health Tracker App

A cross-platform Flutter mobile app that helps track and sync health data using Health Connect (Android) or HealthKit (iOS). It supports user authentication, collects questionnaire data, and displays health metrics in a dashboard format.

🚀 App Features

🧭 Screens Overview
- Login Screen
- Registration Screen
- Health Questionnaire Screen
- Home Page with bottom navigation:
- Dashboard Tab
- Profile Tab

🔄 App Flow (User Journey)

The Login Screen is the entry point of the app.
- If the user is not logged in, they must log in using email/password or Facebook login.
- If the user has logged in but hasn't submitted the health questionnaire, they are redirected to the Health Questionnaire Screen.
- If the user has logged in and submitted the questionnaire, they are redirected to the Home Page.
- On the Login Screen, there is an option to sign up via the Sign Up text.
- After a successful registration, the user is taken directly to the Health Questionnaire Screen.

The Questionnaire Screen collects 10 key user details:
- Full Name, Age, Gender, Height, Weight
- Physical Activity Level, Medical History, Dietary Preference
- Smoking Status, Chronic Conditions
- Upon submission of the questionnaire, the user is redirected to the Home Page.

The Home Page has two bottom navigation tabs:
Dashboard Tab:
- Displays Step Count, Heart Rate, Active Energy Burned, and Sleep Analysis
- A Sync button is provided to manually sync the health data using Health Connect (Android) or HealthKit (iOS)

Profile Tab:
- Displays the submitted questionnaire data for the current user.

🔐 Data Handling
Firebase Authentication is used to store user login credentials.

Cloud Firestore is used to store:
- Questionnaire responses under the questionnaires collection using the user's UID.
- Synced health data under a corresponding collection.

⚙️ Tech Stack

- Flutter (Dart)
- Firebase
- Authentication (Email/Password & Facebook)
- Cloud Firestore for data storage
- Health Connect (Android) (Note: Google Fit is deprecated and not used)
- HealthKit (iOS) (for iPhone users)
- Facebook Auth SDK

🔧 Setup Instructions

- Clone the repository
- git clone https://github.com/your-username/flutter-health-tracker-app.git
- Install dependencies
- flutter pub get
- Firebase setup
- Add your google-services.json in the android/app/ folder.
- Add your GoogleService-Info.plist in the ios/Runner/ folder.
- Set up Facebook app ID and secret in Firebase Auth settings and in your project files.
- Run the app
- flutter run


📲 Permissions Used

- INTERNET – for Firebase and Facebook Auth
- ACTIVITY_RECOGNITION – for step and movement tracking
- BODY_SENSORS – for heart rate
- ACCESS_FINE_LOCATION (if needed by some sensors)
- Health permissions via Health Connect (Android) or HealthKit (iOS)


🗂 Firebase Collections

- questionnaires
- Document ID: user.uid
- Stores all questionnaire responses for each user.
- health_data
- Document ID: user.uid
- Stores latest health metrics synced from Health Connect or HealthKit.

🔐 Firebase Schema

Firestore collections:

* questionnaires — stores form data per user
* health_data — stores synced health metrics per user UID

