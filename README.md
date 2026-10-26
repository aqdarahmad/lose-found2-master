# Lost & Found

A Flutter mobile app that helps people recover lost items. Users publish posts about things they lost or found, interact with each other's posts, and manage their own profile. Backend: a small Node.js/Express API with PostgreSQL (Neon), JWT sign-in, deployed on Render together with the Flutter web build.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.7-0175C2?logo=dart&logoColor=white)
![Node](https://img.shields.io/badge/Node.js-Express-339933?logo=nodedotjs&logoColor=white)
![Postgres](https://img.shields.io/badge/PostgreSQL-Neon-4169E1?logo=postgresql&logoColor=white)

## Features

- **Accounts:** sign up and sign in with email and password (bcrypt-hashed, JWT session)
- **Posts:** create a post with a title, description and image link; edit or delete your own posts
- **Interaction:** like posts, comment on them and save posts for later
- **Search:** find posts quickly
- **Profiles:** edit your own profile (username, bio, avatar) and open other users' profiles and posts
- **Settings:** change password, saved posts, help and support, report a problem, contact support
- **Design:** warm palette of dark red, ruby, beige and silk

## Tech stack

| Area | Tools |
|---|---|
| App | Flutter (web + mobile), Dart, Material |
| API | Node.js, Express 5, `pg`, `bcryptjs`, `jsonwebtoken`, `helmet`, `express-rate-limit` |
| Database | PostgreSQL on [Neon](https://neon.tech) (tables `lf_users`, `lf_posts`, `lf_likes`, `lf_comments`, `lf_saved_posts`, created automatically) |
| Hosting | Render (one web service serves the API and the Flutter web build) |

## Project structure

```
lib/
  main.dart              app entry and routes
  api.dart               REST client (session, posts, likes, comments, users)
  widgets.dart           shared image/avatar widgets and time formatting
  home.dart              feed and "Add new post"
  Search.dart            search users
  Messages.dart          messages screen (UI prototype with sample data)
  registration/          sign in, sign up
  Posts/                 post card + feed, comments sheet, saved posts, post actions
  Profile/               my profile, edit profile, edit post, my posts
  AnotherUsersProfiles/  other users' profiles and posts
  Setting/               settings, change password, help, report, support
server/
  index.js               Express app (API + serves build/web)
  routes.js              REST endpoints with validation and ownership checks
  db.js                  Neon/Postgres pool and schema
render-build.sh          installs Flutter, builds the web app, installs the server
render.yaml              Render blueprint
```

## Deploy on Render

1. Create a free Postgres database on [Neon](https://neon.tech) and copy its connection string.
2. Render → **New → Web Service** → connect this repo (branch `master`).
3. Runtime **Node**, Build Command `bash render-build.sh`, Start Command `node server/index.js`.
4. Environment variables: `DATABASE_URL` (the Neon string). `JWT_SECRET` is optional (derived from `DATABASE_URL` if omitted).
5. Open `/api/health` after the deploy; it should show `"db": true`.

The first build installs Flutter and takes several minutes.

## Run locally

```bash
git clone https://github.com/aqdarahmad/lose-found2-master.git
cd lose-found2-master
flutter pub get
flutter build web --release
cd server && npm install
DATABASE_URL=postgresql://... node index.js     # http://localhost:5000
```

For a mobile build point the app to your server:
`flutter run --dart-define=API_BASE_URL=https://<your-service>.onrender.com`

## Status and next steps

- The **Messages** screen is a UI prototype with sample data; real-time chat is not implemented yet.
- Posts use an image **link**; uploading photos from the device (Firebase Storage) is a planned improvement.
- Posts and feeds refresh on pull-to-refresh and after your own actions (no live push updates).

## Author

**Aqdar Ahmad** · [GitHub](https://github.com/aqdarahmad) · [LinkedIn](https://www.linkedin.com/in/aqdar-ahmad-b30832421)
