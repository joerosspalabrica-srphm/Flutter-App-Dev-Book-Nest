
# Book Nest 📚

>A peer-to-peer book sharing platform for students, built with Flutter and Firebase.

---


## Table of Contents
- [Features](#features)
- [Getting Started](#getting-started)
- [Folder Structure](#folder-structure)
- [Technologies Used](#technologies-used)
- [Contributing](#contributing)
- [License](#license)

---

## Features
- 📖 List and share books with other students
- 🔍 Search and browse available books
- 💬 In-app chat for book exchange coordination
- ⭐ Favorites and rating system
- 🔔 Notifications for new messages and activity
- 🔐 Secure authentication (Firebase Auth)
- 🏷️ Profile management and settings

---



## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Android Studio or VS Code

### Installation
1. **Clone the repository:**
	```sh
	git clone https://github.com/joerosspalabrica-srphm/Flutter-App-Dev-Book-Nest.git
	cd Flutter-App-Dev-Book-Nest
	```
2. **Install dependencies:**
	```sh
	flutter pub get
	```
3. **Configure Firebase:**
	- Add your `google-services.json` to `android/app/`.
	- (For iOS) Add `GoogleService-Info.plist` to `ios/Runner/`.
	- (For Web) Run `flutterfire configure` and ensure `lib/firebase_options.dart` is generated.
4. **Run the app:**
	```sh
	flutter run
	```

---

## Folder Structure
```
lib/
  main.dart                # App entry point
  main_navigation.dart     # Main navigation logic
  homepage_module/         # Home screen and dashboard
  chat_module.dart         # In-app chat
  favorite_module.dart     # Favorites feature
  ...                      # Other feature modules
assets/                    # Images, fonts, etc.
android/                   # Android native files
ios/                       # iOS native files
test/                      # Unit and widget tests
```

---

## Technologies Used
- [Flutter](https://flutter.dev/) (Dart)
- [Firebase Core, Auth, Database, Storage](https://firebase.google.com/)
- [Google Fonts](https://pub.dev/packages/google_fonts)
- [Image Picker](https://pub.dev/packages/image_picker)
- [Shared Preferences](https://pub.dev/packages/shared_preferences)

---



