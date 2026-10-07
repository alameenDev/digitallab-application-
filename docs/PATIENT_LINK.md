# Patient portal pairing (0.4, staging only)

Patient enters the phone number already registered on the laboratory record and a one-time 12-digit code generated in that record's existing portal. This is portal-authorized pairing, not SMS OTP or independent proof of phone ownership.

This branch is paired with alameenDev/erp-lab branch feature/patient-mobile-link-20261007. Do not use the existing portal dashboard/OTP endpoints as the mobile API. No staff credential or database password belongs in this app.

## Run against the isolated test backend
flutter pub get
flutter run -d chrome --web-port 5174 --dart-define=PATIENT_API_BASE_URL=https://YOUR-STAGING-HOST/api

Replace YOUR-STAGING-HOST with the real test server. No live hostname is configured in source. Allow http://localhost:5174 in the test backend's CORS configuration if using local Chrome. HTTP is permitted only for localhost in debug builds.

Without PATIENT_API_BASE_URL the app keeps the explicitly labelled interactive design demo. With it, the app starts in patient pairing mode and displays only server-provided linked records, reports and points. It never falls back to demo patient data on errors.

For a web release use:
flutter build web --release --pwa-strategy=none --dart-define=PATIENT_API_BASE_URL=https://YOUR-STAGING-HOST/api
Do not cache the API with a service worker or proxy. The web session is in memory and ends on page reload. On Android/iOS, credentials use flutter_secure_storage and are namespaced by server URL; results are never persisted by this implementation. Native targets are not present in the original repository and native installation/build validation remains a separate step. Follow the storage plugin's platform setup, especially Android backup exclusions and network permissions, before shipping a native build.

## Implemented
- Pairing, explicit validation, retryable errors and expired/revoked session handling.
- Independent linked patient/laboratory profiles. A shared phone never automatically merges records.
- Patient and laboratory details, paginated report history, readiness status, approved structured result details including grouped/package measurements and range text.
- Per-laboratory points, tier, reward catalog and paginated ledger.
- Server-side logout; portal can revoke devices.
- Secure native credential persistence, no browser persistence and no credentials in URL parameters.
- Late network responses cannot replace another selected patient's data.

No SMS delivery, spending points, booking, PDF rendering, attachments or changes to laboratory records are implemented in this linking mode. Culture and nested range formats need representative synthetic acceptance samples before production rollout; the app currently renders the structured fields exposed by the new API.

## Validation
flutter analyze
flutter test
CI builds both the unchanged demo entry and the configured linking entry. The test API hostname is synthetic and never receives real patient requests.
