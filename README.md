#  Lost & Found

<p align="center">
  <strong>A little help can bring something precious back home.</strong>
  <br />
  A Flutter application that connects people who have lost items with those who have found them.
</p>

<p align="center">
  <a href="https://github.com/aqdarahmad/lose-found2-master">
    <img src="https://img.shields.io/badge/Project-Lost%20%26%20Found-8B2635?style=for-the-badge" alt="Lost and Found" />
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.7-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Node.js-Express-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js and Express" />
  <img src="https://img.shields.io/badge/PostgreSQL-Neon-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
</p>

<p align="center">
  🌐 <a href="https://github.com/aqdarahmad/lose-found2-master">Source Code</a>
</p>

---

## 🌷 About the Project

**Lost & Found** is a mobile and web application designed to make recovering lost belongings easier.

Users can share posts about lost or found items, discover relevant posts, interact with other users, and manage their profiles — all in one place.

The application combines a Flutter frontend with a Node.js and Express backend, backed by PostgreSQL on Neon. Authentication uses password hashing and JSON Web Tokens (JWT).

The interface features a warm visual identity built around dark red, ruby, beige, and silk-inspired tones.

## ✨ Features

### 🔐 Authentication
- Create an account and sign in using an email and password.
- Secure password hashing with `bcryptjs`.
- JWT-based authentication.

### 📝 Posts
- Create posts with a title, description, and image link.
- Edit and delete your own posts.
- Browse posts shared by other users.

### 💬 Community Interaction
- Like posts.
- Comment on posts.
- Save posts to revisit later.

### 🔎 Search
- Search for posts and discover relevant content.
- Find users through the search interface.

### 👩🏻 Profile Management
- Edit your username, bio, and avatar.
- View other users' profiles and posts.
- Manage your own posts.

### ⚙️ Settings & Support
- Change your password.
- View saved posts.
- Access help and support.
- Report a problem or contact support.

## 📸 Screenshots

<p align="center">
  <img width="48%" src="https://github.com/user-attachments/assets/411bf6d0-a85c-493a-a5d9-70c9b17b0896" alt="Lost and Found application screenshot 1" />
  <img width="48%" src="https://github.com/user-attachments/assets/a7432e38-6393-46d2-a517-6d34a5a78d0e" alt="Lost and Found application screenshot 2" />
</p>

<p align="center">
  <img width="48%" src="https://github.com/user-attachments/assets/38d08b6e-3827-426c-89e8-3b3f5fe4fe1a" alt="Lost and Found application screenshot 3" />
  <img width="48%" src="https://github.com/user-attachments/assets/87b80bc4-abee-4e49-92b1-ec4cb5c62aa7" alt="Lost and Found application screenshot 4" />
</p>

## 🛠️ Tech Stack

| Area | Technologies |
|---|---|
| Frontend | Flutter, Dart, Material |
| Backend | Node.js, Express 5 |
| Database | PostgreSQL on [Neon](https://neon.tech) |
| Authentication | JWT, bcryptjs |
| API & Security | `pg`, `helmet`, `express-rate-limit` |
| Hosting | Render |
| Version Control | Git, GitHub |

## 🏗️ Project Architecture

The application is organized into three main parts:

- **Flutter app:** User interface, navigation, posts, profiles, and interactions.
- **Express API:** Authentication, REST endpoints, request validation, and ownership checks.
- **PostgreSQL database:** Persistent storage for users, posts, likes, comments, and saved posts.

### Database Tables

The backend creates the required tables automatically:

- `lf_users`
- `lf_posts`
- `lf_likes`
- `lf_comments`
- `lf_saved_posts`

### Project Structure

```text
lib/
├── main.dart
├── api.dart
├── widgets.dart
├── home.dart
├── Search.dart
├── Messages.dart
├── registration/
├── Posts/
├── Profile/
├── AnotherUsersProfiles/
└── Setting/

server/
├── index.js
├── routes.js
└
