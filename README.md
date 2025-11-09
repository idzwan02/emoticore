# Emoticore 💖

Emoticore is a mobile mental health (mHealth) application built with Flutter and Firebase. This project is developed as part of a university course (`CSP`, Semester 6) to explore mobile app development for mental well-being. The app provides users with tools to track their mood, monitor mental health scores via the DASS-21 assessment, and customize their profile.

## 📸 Screenshots

*(You can add screenshots of your app here)*

| Login Page | Dashboard | Activities | DASS-21 Quiz | Profile |
| :---: | :---: | :---: | :---: | :---: |
| ![alt text](assets/login_page.png) | `[Insert screenshot of dashboard_page.dart]` | `[Insert screenshot of activities_page.dart]` | `[Insert screenshot of dass21_page.dart]` | `[Insert screenshot of profile_page.dart]` |

## ✨ Features

  * **Firebase Authentication:** Full email & password sign-up, login, and "Forgot Password" functionality.
  * **Animated Splash Screen:** A beautiful, multi-stage launch sequence using `flutter_native_splash` (for the instant-on native screen) and a Lottie (`open.json`) animation.
  * **Dynamic Dashboard (Home Tab):**
      * Welcomes the user with their name and selected avatar, fetched live from Firestore.
      * **Live DASS-21 Chart:** Displays the user's latest DASS-21 (Stress, Anxiety, Depression) scores in a bar chart (`fl_chart`) that updates automatically when a new test is completed.
      * **Daily Mood Tracker:** A "once-a-day" pop-up asks the user for their mood (using `shared_preferences` to track the date). The selected emoji is then displayed on the dashboard.
      * Section placeholders for "Your Badges," "Stats Cards," and "Articles."
  * **Activities Tab:**
      * A centered grid layout (`Wrap`) of all available app activities (Journaling, Moodboard, Quizzes, DASS-21, Daily Task).
  * **DASS-21 Assessment Page:**
      * A multi-page (`PageView`) 21-question assessment.
      * Custom-styled, animated answer selection.
      * Automatically calculates the Depression, Anxiety, and Stress scores based on the official template.
      * Saves the final results and raw answers to a user-specific subcollection in Firestore.
  * **Profile Tab:**
      * Displays the user's selected avatar, name, email, date of birth, and join date (fetched from Firestore).
      * **Avatar Selection System:** Allows the user to tap their avatar to open a dialog and select from a predefined list of local assets (stored in `assets/avatars/`). The choice is saved to Firestore and updates the dashboard avatar.
      * Secure logout functionality.
  * **Custom Animations:**
      * `Lottie` is used for all loading indicators.
      * `AnimatedSwitcher` provides a smooth fade transition between the Home, Activities, and Profile tabs.
      * `FadeRoute` (`PageRouteBuilder`) provides a custom fade animation for all page-to-page navigation.

## 🚀 Tech Stack

  * **Frontend:** Flutter & Dart
  * **Backend:** Firebase
      * **Authentication:** For user sign-in and registration.
      * **Cloud Firestore:** NoSQL database for storing user data, DASS-21 results, mood, and avatar preferences.
  * **State Management:** `StatefulWidget` (`setState`)
  * **Key Packages:**
      * `firebase_core`
      * `firebase_auth`
      * `cloud_firestore`
      * `lottie` (for all loading and splash animations)
      * `fl_chart` (for DASS-21 bar chart)
      * `shared_preferences` (for daily mood check timestamp)
      * `intl` (for date formatting)
      * `flutter_native_splash` (for the native splash screen)

## Firebase Setup 🔥

Before running the project, you **must** configure Firebase:

1.  **Create Project:** Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2.  **Add Flutter:** Follow the `flutterfire configure` CLI instructions, or add Android and iOS apps manually.
3.  **Download Config Files:**
      * **Android:** Download the `google-services.json` file and place it in the `android/app/` directory.
      * **iOS:** Download the `GoogleService-Info.plist` file and open the `ios/` folder in Xcode to add it to the `Runner` project.
4.  **Enable Services:** In the Firebase Console, go to the **Build** section:
      * **Authentication:** Enable the **Email/Password** sign-in method.
      * **Cloud Firestore:** Create a database. Start in **Test Mode** (or configure security rules to allow reads/writes for authenticated users).
      * **Storage (Optional):** If you plan to store other images, enable Firebase Storage.

## 🚦 Getting Started

1.  **Clone the Repository:**
    ```bash
    git clone [Your Repository URL]
    cd emoticore
    ```
2.  **Ensure Asset Folders:**
      * Make sure you have your Lottie files in `assets/animations/` (especially `loading.json` and `open.json`).
      * Make sure you have your avatar images in `assets/avatars/` (e.g., `default_avatar.png`, `avatar1.png`, etc.).
3.  **Configure `pubspec.yaml`:**
      * Ensure your `pubspec.yaml` file correctly lists your assets:
    <!-- end list -->
    ```yaml
    flutter:
      assets:
        - assets/
        - assets/avatars/
        - assets/animations/
    ```
4.  **Get Packages:**
    ```bash
    flutter pub get
    ```
5.  **Run the Native Splash Generator:**
    *(This is required after adding `flutter_native_splash` to your `pubspec.yaml`)*.
    ```bash
    flutter pub run flutter_native_splash:create
    ```
6.  **Run the App:**
    ```bash
    flutter run
    ```

## 📂 Project Structure

```
lib/
├── assets/
│   ├── avatars/
│   │   ├── default_avatar.png
│   │   └── ... (other avatars)
│   ├── animations/
│   │   ├── loading.json
│   │   └── open.json
│   └── brain_icon.png
│
├── lib/
│   ├── main.dart             # App entry point, initializes Firebase
│   ├── splash_screen.dart    # Lottie animation splash screen
│   ├── auth_gate.dart        # Checks auth state and directs user
│   ├── login_page.dart       # Login screen
│   ├── register_page.dart    # Registration screen
│   ├── forgot_password_page.dart # Password reset screen
│   ├── dashboard_page.dart   # Main page with BottomNavBar (Home, Activities, Profile)
│   ├── activities_page.dart  # Grid view for activities
│   ├── profile_page.dart     # User profile and avatar selection
│   ├── dass21_page.dart      # DASS-21 assessment
│   └── custom_page_route.dart  # Reusable fade animation for navigation
│
└── pubspec.yaml            # Project dependencies and asset declarations
```
