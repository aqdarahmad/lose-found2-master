# Lost & Found

A Flutter mobile app that helps people recover lost items. Users publish posts about things they lost or found, interact with each other's posts, and manage their own profile. Backend: Firebase Authentication and Cloud Firestore.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.7-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase&logoColor=black)

## Features

- **Accounts:** sign up and sign in with email and password (Firebase Authentication)
- **Posts:** create a post with a title, description and image link; edit or delete your own posts
- **Interaction:** like posts, comment on them and save posts for later
- **Search:** find posts quickly
- **Profiles:** edit your own profile (username, bio, avatar) and open other users' profiles and posts
- **Settings:** change password, saved posts, help and support, report a problem, contact support
- **Design:** warm palette of dark red, ruby, beige and silk

## Tech stack

| Area | Tools |
|---|---|
| App | Flutter, Dart, Material |
| Auth | `firebase_auth` |
| Database | `cloud_firestore` (collections: `users`, `posts`, `comments`, `likes`, `savedPosts`) |

## Project structure

```
lib/
  main.dart              app entry and routes
  home.dart              feed and "Add new post"
  Search.dart            search
  Messages.dart          messages screen (UI prototype with sample data)
  registration/          sign in, sign up
  Posts/                 posts, comments sheet, saved posts, post actions
  Profile/               my profile, edit profile, edit post, my posts
  AnotherUsersProfiles/  other users' profiles and posts
  Setting/               settings, change password, help, report, support
  firebase_options.dart  Firebase configuration
```

## Run locally

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and run `flutter doctor`.
2. Clone and install packages:
   ```bash
   git clone https://github.com/aqdarahmad/lose-found2-master.git
   cd lose-found2-master
   flutter pub get
   ```
3. Use your own Firebase project (recommended): create a project, enable **Email/Password** sign-in and **Cloud Firestore**, then run
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   which regenerates `lib/firebase_options.dart`.
4. Start the app:
   ```bash
   flutter run
   ```

## Status and next steps

- The **Messages** screen is a UI prototype with sample data; real-time chat is not implemented yet.
- Posts use an image **link**; uploading photos from the device (Firebase Storage) is a planned improvement.
- Firestore security rules should be tightened before any public release.

## Author

**Aqdar Ahmad** · [GitHub](https://github.com/aqdarahmad) · [LinkedIn](https://www.linkedin.com/in/aqdar-ahmad-b30832421)
