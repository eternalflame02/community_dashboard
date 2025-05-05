# Community Dashboard

A cross-platform application for community incident reporting and management.

---

## Quick Start

1. **Clone the repository**
2. **Install prerequisites:**
   - [Flutter](https://flutter.dev/docs/get-started/install)
   - [Node.js & npm](https://nodejs.org/)
   - [MongoDB](https://www.mongodb.com/)
3. **Configure Firebase and MongoDB (see below)**
4. **Start backend:**
   ```sh
   cd backend
   npm install
   node server.js
   ```
5. **Run frontend:**
   ```sh
   flutter pub get
   flutter run
   ```

---

## Project Structure

- **lib/**: Flutter app source code (Dart)
- **backend/**: Node.js/Express server for API and MongoDB integration
- **android/**: Android-specific files
- **web/**: Web build and static assets
- **scripts/**: Utility scripts (e.g., MongoDB setup)
- **test/**: Flutter tests

---

## Features
- Incident reporting and management
- User authentication (Firebase)
- Data storage (Firebase & MongoDB)
- Web, Android, and backend support

---

## Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install)
- [Node.js & npm](https://nodejs.org/)
- [MongoDB](https://www.mongodb.com/)

---

## Environment Setup

### 1. Firebase Configuration (Frontend)
Create a `.env` file in the project root with:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_auth_domain
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket
FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
FIREBASE_APP_ID=your_app_id
```
*On Windows, use `%VAR%` for environment variables in the command line.*

### 2. MongoDB Configuration (Backend)
Set up your MongoDB connection string in `backend/config/mongodb.js` or as an environment variable (see backend code for details).

### 3. Backend Setup
```sh
cd backend
npm install
node server.js
```

### 4. Frontend Setup
Install dependencies:
```sh
flutter pub get
```

#### For web builds:
```sh
flutter build web --dart-define=FIREBASE_API_KEY=%FIREBASE_API_KEY% \
                 --dart-define=FIREBASE_AUTH_DOMAIN=%FIREBASE_AUTH_DOMAIN% \
                 --dart-define=FIREBASE_PROJECT_ID=%FIREBASE_PROJECT_ID% \
                 --dart-define=FIREBASE_STORAGE_BUCKET=%FIREBASE_STORAGE_BUCKET% \
                 --dart-define=FIREBASE_MESSAGING_SENDER_ID=%FIREBASE_MESSAGING_SENDER_ID% \
                 --dart-define=FIREBASE_APP_ID=%FIREBASE_APP_ID%
```
*On Windows, use `%VAR%` instead of `$VAR` for environment variables.*

#### For development (VS Code):
Create a `launch.json` with the appropriate `--dart-define` arguments.

---

## Local Configuration

- Copy `lib/config/api_config.dart.example` to `lib/config/api_config.dart` and set your API base URL.
- Copy `.env.example` to `.env` and set your backend secrets.

---

## Usage
- Start the backend server (`node backend/server.js`)
- Run the Flutter app (`flutter run` or use VS Code launch config)

---

## Running Tests
- Flutter: `flutter test`
- Backend (if tests exist): `cd backend && npm test`

---

## Troubleshooting
- **Port conflicts:** Ensure no other process is using the backend port (default: 3000).
- **MongoDB connection errors:** Check your connection string and that MongoDB is running.
- **Firebase errors:** Verify your `.env` values and `google-services.json` for Android.

---

## Contributing
Pull requests are welcome. For major changes, please open an issue first.

---

## License
[MIT](LICENSE)
