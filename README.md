# Personal Expense Tracker

A full-stack personal expense tracking application built with **Flutter** and **Node.js/Express**. The mobile and cross-platform frontend supports expense management, authentication, reporting, Firebase notifications, and Google Sign-In. The backend provides REST APIs, MongoDB persistence, Firebase Admin authentication, image uploads, and validation.

## Technology Stack

### Frontend

- Flutter / Dart
- Firebase Authentication and Messaging
- Google Sign-In
- HTTP (Dio)
- charts and internationalization packages
- Android, iOS, web, Windows, macOS, and Linux targets

### Backend

- Node.js
- Express.js
- MongoDB with Mongoose
- Firebase Admin SDK
- JWT-compatible Firebase authentication support
- Multer file uploads
- Jest and Supertest testing
- Helmet, CORS, Morgan, and Express Rate Limit

## Project Structure

```text
Personal-Expense-Tracker.com/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   └── validators/
│   ├── tests/
│   ├── uploads/
│   ├── server.js
│   └── .env.example
└── frontend/
    ├── lib/
    │   ├── app/
    │   ├── core/
    │   ├── data/
    │   └── modules/
    ├── android/
    ├── ios/
    ├── web/
    ├── test/
    └── pubspec.yaml
```

## Features

- User registration and authentication
- Email/password and Google Sign-In support
- Expense and income tracking
- Category management
- Expense history and summaries
- Charts and visual reports
- Firebase push notifications
- Image-based attachments or uploads
- Cross-platform Flutter application support

## Prerequisites

Make sure the following tools are installed:

- Node.js 18 or newer
- npm
- Flutter SDK 3.3.0 or newer
- A MongoDB database
- A Firebase project
- Android Studio or another supported IDE for mobile development

## Backend Setup

1. Open the backend directory:

   ```bash
   cd backend
   ```
2. Install dependencies:

   ```bash
   npm install
   ```
3. Create a local environment file:

   ```bash
   cp .env.example .env
   ```
4. Update the values in `backend/.env`.

### Backend Environment Variables

| Variable | Description |
|---|---|
| `NODE_ENV` | Runtime environment, such as `development` or `production` |
| `PORT` | Port used by the Express server; default is `5000` |
| `MONGO_URI` | MongoDB connection string |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to the Firebase service-account JSON file |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Optional inline Firebase service-account JSON |
| `CORS_ORIGIN` | Allowed CORS origin or a comma-separated origin list |

Do not commit real database credentials or Firebase private keys to GitHub.

### Run the Backend

Development mode:

```bash
npm run dev
```

Production-style start:

```bash
npm start
```

The default server URL is:

```text
http://localhost:5000
```

### Backend Tests

```bash
npm test
```

## Frontend Setup

1. Open the frontend directory:

   ```bash
   cd frontend
   ```
2. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```
3. Configure Firebase for each platform you plan to run.

   The project includes `lib/firebase_options.dart` and `firebase.json`; replace or regenerate Firebase configuration files for your own Firebase project when needed.

4. Run the app:

   ```bash
   flutter run
   ```

### Run on a Specific Platform

```bash
flutter run -d chrome
flutter run -d windows
flutter run -d android
flutter run -d ios
```

### Frontend Tests

```bash
flutter test
```

### Flutter Code Analysis

```bash
flutter analyze
```

## Android Release Build

The repository contains a Windows batch script for creating a Play Store app bundle:

```bash
build_playstore_bundle.bat
```

You can also build it manually:

```bash
flutter build appbundle --release
```

Before publishing, update the application package name, signing key, app label, Firebase configuration, and Play Store credentials.

## Development Notes

- Keep MongoDB credentials, Firebase credentials, API secrets, and signing keys outside source control.
- Rotate any database or service-account credential that has previously been committed to a public repository.
- Configure `CORS_ORIGIN` to match the frontend origin in production.
- Update Firebase configuration before distributing the app.
- Run both backend tests and Flutter tests before deployment.

## License

The backend package metadata specifies the **ISC** license. Add a separate `LICENSE` file if you want an explicit repository-level license notice.
