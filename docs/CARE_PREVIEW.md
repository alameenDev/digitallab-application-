# Doctor profiles and home collection — review guide

This addition belongs to the independent app design phase. It does not modify the laboratory ERP or activate its API. It is a session-local interactive preview, not a production admin service.

## Review together

Run `flutter run -d chrome -t lib/admin_main.dart`. The admin entry has no production authentication and must not be deployed for real patient operations. It starts with fictional profiles.

1. Open **Doctors**, add a profile, choose a local image (maximum 2 MB), specialty, clinic, fee, address, area and optional coordinates/social links. Save and preview it.
2. Open **Preview the app with this session's data**, then Explore → Doctors. The same profile appears, including its photo, map link and social links. Hide it in administration to remove it from the directory. Existing appointment snapshots remain readable.
3. Add or edit a home collection service: providing laboratory, coverage areas separated by Arabic/English commas, visit fee, hours and notes. Disable it to prevent new requests.
4. In the patient preview, open home collection. Choose a service, patient profile, telephone, requested tests, coverage area, full address and requested date/time. Landmark, coordinates and notes are optional. Acknowledge the demo and submit.
5. Open the request list under Bookings. Other family profiles cannot view or cancel this request.
6. Return to admin → Home collection requests. Confirm, assign a named demo collector, then progress through on the way, sample collected and visit completed. Visit completion never generates medical results. Patient cancellation ends once the collector is on the way; admin cancellation ends once the sample is collected.

The displayed fee covers collection/visit only. Test prices require a separate provider quote. Existing requests keep their original service/fee snapshot when configuration changes.

## Current boundaries

- No server persistence, real messages, collector dispatch, payments, background notifications, GPS permission requests or cross-tab/device synchronization.
- Images and requests disappear when the preview is reloaded. Only use fictional information.
- Coordinate links open Google Maps after a user click. This is not an embedded map or live tracking.
- Social links use HTTPS, validate the expected platform host and reject script/data/custom schemes. Missing details are omitted or shown as unavailable.
- The existing package-booking demonstration remains available. Its legacy appointment simulation is separate from the new managed home visit requests.
- `PATIENT_API_BASE_URL` still selects the existing isolated ERP pairing experience. New care features are not silently mixed with live medical records.
- Native targets are absent in the repository; Android/iOS packaging, image permissions/lost-picker-data handling and device tests remain before a native release.

## Next integration boundary

The future independent app backend should own doctor profiles and images, service configuration, requests, staff permissions and status history. Enforce provider/patient authorization, allowed transitions and authoritative pricing there; never trust preview state or an admin route flag. The ERP remains the authority for medical results and laboratory loyalty points.

Expected resources: doctors (including image and coordinates), home-collection services, patient-scoped requests, staff assignments and append-only request events. Add durable storage, image validation/storage, authenticated administration and a patient session before enabling real operations. No production database credentials belong in Flutter.

Validation: `flutter analyze`, `flutter test`, web builds for `lib/main.dart`, `lib/admin_main.dart`, and the existing ERP pairing build. The added tests exercise invalid links/coordinates, profile publication, fee snapshots, coverage/time checks, transitions, family isolation, editing, submission and narrow Arabic/English layouts.
