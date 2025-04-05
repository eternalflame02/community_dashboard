# Community Dashboard

A Flutter application for community incident reporting and management.

## Environment Setup

1. **Firebase Configuration**
   Create a `.env` file in the project root with the following variables:
   ```
   FIREBASE_API_KEY=your_api_key
   FIREBASE_AUTH_DOMAIN=your_auth_domain
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_STORAGE_BUCKET=your_storage_bucket
   FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
   FIREBASE_APP_ID=your_app_id
   ```

2. **Build Configuration**
   For web builds, add these arguments to your build command:
   ```bash
   flutter build web --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY \
                    --dart-define=FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN \
                    --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
                    --dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET \
                    --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
                    --dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID
   ```

3. **Development Setup**
   For development, you can create a `launch.json` configuration in VS Code:
   ```json
   {
     "configurations": [
       {
         "name": "Flutter Web",
         "type": "dart",
         "request": "launch",
         "program": "lib/main.dart",
         "args": [
           "--dart-define=FIREBASE_API_KEY=${env:FIREBASE_API_KEY}",
           "--dart-define=FIREBASE_AUTH_DOMAIN=${env:FIREBASE_AUTH_DOMAIN}",
           "--dart-define=FIREBASE_PROJECT_ID=${env:FIREBASE_PROJECT_ID}",
           "--dart-define=FIREBASE_STORAGE_BUCKET=${env:FIREBASE_STORAGE_BUCKET}",
           "--dart-define=FIREBASE_MESSAGING_SENDER_ID=${env:FIREBASE_MESSAGING_SENDER_ID}",
           "--dart-define=FIREBASE_APP_ID=${env:FIREBASE_APP_ID}"
         ]
       }
     ]
   }
   ```

## Getting Started

1. Clone the repository
2. Copy `.env.example` to `.env` and fill in your Firebase configuration
3. Run `flutter pub get` to install dependencies
4. Use VS Code's launch configuration or run with environment variables as shown above

## Features

- User authentication with email/password
- Incident reporting with location
- Real-time incident updates
- Geospatial incident querying
- Image attachments for incidents

## Development Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [Cloud Firestore Documentation](https://firebase.google.com/docs/firestore)
