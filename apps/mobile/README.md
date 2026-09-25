# PulmoCare Mobile

PulmoCare Mobile is the Flutter client for the PulmoCare clinical platform. It
uses the PulmoCare API gateway for authentication, reports, appointments,
patient/provider directories, prescriptions, and the server-backed clinical
assistant.

## Current product flows

The main authenticated workspace includes:

- role-aware sign-in for patients, doctors, and radiologists
- secure session storage and access-token refresh
- patient/provider directories exposed through scoped backend endpoints
- report listing, creation, viewing, editing, and deletion
- patient appointment booking, listing, and cancellation
- prescription creation with medication search, signature, and stamp capture
- a clinical documentation assistant available to clinical staff
- PDF/report utilities, handwriting, voice dictation, and OCR-related tools

The clinical assistant does **not** embed an AI provider key in the mobile
binary. Requests are sent to the authenticated reports API, and the backend
owns the provider configuration.

## Requirements

- Flutter 3.47 or newer
- Dart 3.11 or newer
- Android Studio for Android development
- Xcode for iOS development
- a running PulmoCare backend/API gateway

## Repository setup

```bash
git clone https://github.com/aliammari1/pulmocare.git
cd pulmocare/apps/mobile
flutter pub get
```

Run static analysis and tests:

```bash
flutter analyze
flutter test
```

## API configuration

The app reads the gateway URL from the compile-time `API_BASE_URL` value.

For an Android emulator with the local APISIX gateway:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:9080/api/
```

For Flutter web or desktop on the same machine:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:9080/api/
```

When `API_BASE_URL` is omitted in a debug build, these same platform-specific
local defaults are used automatically. Release builds require an explicit
HTTPS URL and fail fast if it is missing or uses plain HTTP.

For a physical device, use an address reachable by that device. Production
deployments should use the public HTTPS gateway, for example:

```bash
flutter build appbundle \
  --dart-define=API_BASE_URL=https://api.example.com/api/
```

The legacy `.env` file is not loaded by the Flutter runtime.

## Google Maps key

Android reads the Maps key from the gitignored
`android/local.properties` file, with an environment-variable fallback:

```properties
MAPS_API_KEY=your_android_restricted_maps_key
```

Restrict the key in Google Cloud to the Android application ID and signing
certificate fingerprints used by the app.

## Clinical assistant

The Flutter client calls:

```text
POST /api/reports/ai/assistant
```

The request is authenticated with the user's bearer token. The AI provider key
is configured only on the reports backend. If the backend provider is not
configured, the API returns a service-unavailable response instead of the
mobile app fabricating a fallback answer.

AI output is documentation support and must be reviewed by a qualified
healthcare professional before clinical use.

## Local backend

From the repository root, the development stack exposes APISIX on port 9080.
The mobile client should talk to APISIX rather than directly addressing
individual microservices.

Common local URLs:

- Android emulator: `http://10.0.2.2:9080/api/`
- Web/desktop: `http://localhost:9080/api/`

Individual service ports are implementation details of the backend and should
not be hard-coded in Flutter feature code.

## Android builds

Create a debug APK:

```bash
flutter build apk --debug
```

Release builds are intentionally not signed with the Android debug key.
Configure the production upload/release keystore in the publishing environment
before shipping to a store.

The Android application ID is:

```text
com.pulmocare.app
```

## Project structure

```text
lib/
├── models/        Data models
├── screens/       Application screens and feature flows
├── services/      API clients, state/view models, token storage
├── theme/         Shared visual theme
├── utils/         HTTP client and shared utilities
└── widgets/       Reusable UI components
```

State used by the current app shell is provided with `provider`.
`DioHttpClient` centralizes the API base URL, bearer-token attachment,
request IDs, timeouts, refresh-token rotation, and one-time retry after a 401.

## Security notes

The current source includes several important controls:

- authentication tokens are stored with `flutter_secure_storage`
- authenticated requests use a shared bearer-token interceptor
- release API URLs must use HTTPS
- AI provider credentials remain server-side
- report and appointment authorization is enforced by backend services
- sensitive Keycloak/user records should never be committed as seed data

These implementation controls are not, by themselves, a certification of
HIPAA, GDPR, or any other regulatory framework. Production compliance requires
deployment-specific security, privacy, operational, contractual, and legal
review.

## Development quality

Before opening a pull request:

```bash
flutter analyze --no-fatal-warnings
flutter test
flutter build apk --debug
```

GitHub Actions runs the same mobile checks so development does not require a
high-end local machine for routine analyzer/test/debug-build validation.
