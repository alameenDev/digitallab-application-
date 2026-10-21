import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_lab_patient/main.dart';

Widget careHost(AppStore s, Widget page) => AppScope(store: s, child: MaterialApp(
  locale: Locale(s.arabic ? 'ar' : 'en'), supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: buildTheme(Brightness.light), home: page));

HomeVisitRequest request(AppStore s, {String patient = 'p1'}) => s.submitHomeVisit(
  serviceId: 'home-life', forPatient: patient, phone: '٠٧٧٠١٢٣٤٥٦٧',
  address: 'Demo street, house 12', area: 'المنصور', tests: 'CBC',
  location: const GeoPoint(33.3, 44.3),
  scheduledAt: DateTime(2026, 10, 22, 9), now: DateTime(2026, 10, 21));

void main() {
  test('coordinate and social validation rejects malformed and unsafe inputs', () {
    expect(GeoPoint.parse('٣٣٫٣١٥٢', '٤٤٫٣٦٦١')!.valid, isTrue);
    expect(GeoPoint.parse('', ''), isNull);
    for (final values in [('91', '40'), ('33', '181'), ('NaN', '40'), ('33', ''), ('Infinity', '2')]) {
      expect(() => GeoPoint.parse(values.$1, values.$2), throwsFormatException);
    }
    expect(validSocialLink('instagram', 'https://www.instagram.com/demo'), isTrue);
    for (final value in ['javascript:alert(1)', 'http://instagram.com/demo',
      'https://instagram.com.attacker.test/a', 'https://user:password@instagram.com/a']) {
      expect(validSocialLink('instagram', value), isFalse);
    }
    expect(const GeoPoint(33.3, 44.3).mapUrl.queryParameters['query'], '33.3,44.3');
  });

  test('admin doctor changes appear in catalog and archived bookings retain snapshots', () {
    final s = AppStore();
    const d = DoctorProfile(id: 'new-doctor', name: 'Demo doctor', specialty: 'Demo specialty',
      address: 'Demo complete address', area: 'New area', fee: 20000,
      location: GeoPoint(33.3, 44.3), socials: {'instagram': 'https://instagram.com/example'});
    s.saveDoctor(d);
    expect(s.catalogServices.where((v) => v.id == d.id), hasLength(1));
    final booking = Booking(id: 'snapshot', serviceId: d.id, serviceSnapshot: d.service,
      patientId: 'p1', date: DateTime(2026, 10, 22), phone: '07701234567', address: '',
      notes: '', mode: 'clinic', payment: 'provider', total: 20000, discount: 0);
    s.addBooking(booking); s.saveDoctor(d.withActive(false));
    expect(s.catalogServices.where((v) => v.id == d.id), isEmpty);
    expect(booking.service.ar, 'Demo doctor');
    expect(AppStore().doctorById(d.id), isNull);
  });

  test('home requests validate coverage, timing and enabled service at submission', () {
    final s = AppStore();
    final r = request(s);
    expect(r.phone, '07701234567'); expect(r.status, HomeVisitStatus.pending);
    s.saveHomeService(s.homeVisitServices.first.withActive(false));
    expect(() => request(s), throwsFormatException);
    s.saveHomeService(s.homeVisitServices.first.withActive(true));
    for (final input in [('outside coverage', 9), ('المنصور', 2)]) {
      expect(() => s.submitHomeVisit(serviceId: 'home-life', forPatient: 'p1',
        phone: '07701234567', address: 'Demo address', area: input.$1, tests: 'CBC',
        scheduledAt: DateTime(2026, 10, 22, input.$2), now: DateTime(2026, 10, 21)), throwsFormatException);
    }
    expect(s.homeVisitRequests, hasLength(1));
  });

  test('request fee is fixed and status cannot skip collector or reopen terminal states', () {
    final s = AppStore(), r = request(s);
    s.saveHomeService(const HomeVisitService(id: 'home-life', name: 'Updated service',
      labId: 'lab1', areas: ['المنصور'], fee: 25000));
    expect(r.service.fee, 10000);
    expect(s.advanceHomeVisit(r), isTrue);
    expect(s.advanceHomeVisit(r), isFalse);
    expect(s.advanceHomeVisit(r, collector: 'Demo collector'), isTrue);
    expect(r.collector, 'Demo collector');
    expect(s.advanceHomeVisit(r), isTrue);
    expect(s.cancelHomeVisit(r), isFalse);
    expect(s.advanceHomeVisit(r), isTrue);
    expect(s.cancelHomeVisit(r, byAdmin: true), isFalse);
    expect(s.advanceHomeVisit(r), isTrue);
    expect(r.status, HomeVisitStatus.completed);
    expect(s.advanceHomeVisit(r), isFalse);
    expect(r.history, hasLength(6));
  });

  test('another family profile cannot cancel a request and cancellation is terminal', () {
    final s = AppStore(), r = request(s);
    s.addPatient('Child demo', 'Child'); s.selectPatient('p2');
    expect(s.cancelHomeVisit(r), isFalse);
    s.selectPatient('p1'); expect(s.cancelHomeVisit(r), isTrue);
    expect(s.advanceHomeVisit(r), isFalse);
    expect(s.cancelHomeVisit(r), isFalse);
  });

  testWidgets('doctor editor validates links and saves an editable patient-facing profile', (tester) async {
    tester.view.physicalSize = const Size(500, 1500); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final s = AppStore()..arabic = false;
    await tester.pumpWidget(careHost(s, const DoctorAdminScreen()));
    await tester.tap(find.byKey(const ValueKey('doctor-add'))); await tester.pumpAndSettle();
    for (final e in {'name': 'Demo new doctor', 'specialty': 'Family medicine',
      'area': 'New district', 'address': 'Demo street house 20', 'lat': '33.3', 'lng': '44.3',
      'instagram': 'javascript:alert(1)'}.entries) {
      await tester.ensureVisible(find.byKey(ValueKey('doctor-${e.key}')));
      await tester.enterText(find.byKey(ValueKey('doctor-${e.key}')), e.value);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('doctor-save')));
    await tester.tap(find.byKey(const ValueKey('doctor-save'))); await tester.pumpAndSettle();
    expect(s.doctors, hasLength(2));
    await tester.ensureVisible(find.byKey(const ValueKey('doctor-instagram')));
    await tester.enterText(find.byKey(const ValueKey('doctor-instagram')), 'https://instagram.com/example');
    await tester.ensureVisible(find.byKey(const ValueKey('doctor-save')));
    await tester.tap(find.byKey(const ValueKey('doctor-save'))); await tester.pumpAndSettle();
    expect(s.doctors, hasLength(3));
    expect(s.doctors.last.location!.latitude, 33.3);
    expect(s.catalogServices.last.ar, 'Demo new doctor');
    expect(tester.takeException(), isNull);
  });

  testWidgets('home request requires consent and saves contact, location and requested tests once', (tester) async {
    tester.view.physicalSize = const Size(500, 1500); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final s = AppStore()..arabic = false;
    await tester.pumpWidget(careHost(s, const HomeVisitRequestScreen(serviceId: 'home-life')));
    for (final e in {'phone': '07701234567', 'tests': 'CBC and glucose', 'address': 'Demo street house 12',
      'landmark': 'Demo gate', 'lat': '33.3', 'lng': '44.3', 'notes': 'Call at the door'}.entries) {
      await tester.ensureVisible(find.byKey(ValueKey('home-${e.key}')));
      await tester.enterText(find.byKey(ValueKey('home-${e.key}')), e.value);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('home-submit')));
    await tester.tap(find.byKey(const ValueKey('home-submit'))); await tester.pumpAndSettle();
    expect(s.homeVisitRequests, isEmpty);
    await tester.ensureVisible(find.byKey(const ValueKey('home-consent')));
    await tester.tap(find.byKey(const ValueKey('home-consent'))); await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('home-submit')));
    await tester.tap(find.byKey(const ValueKey('home-submit'))); await tester.pumpAndSettle();
    expect(s.homeVisitRequests, hasLength(1));
    final r = s.homeVisitRequests.single;
    expect(r.tests, 'CBC and glucose'); expect(r.notes, 'Call at the door');
    expect(r.location!.longitude, 44.3); expect(r.service.fee, 10000);
    expect(find.byKey(const ValueKey('home-advance')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('patient request list and details stay isolated when switching family profiles', (tester) async {
    final s = AppStore()..arabic = false;
    final r = request(s); s.addPatient('Child', 'Child'); s.selectPatient('p2');
    await tester.pumpWidget(careHost(s, const MyHomeRequestsScreen())); await tester.pumpAndSettle();
    expect(find.text(r.id), findsNothing);
    await tester.pumpWidget(careHost(s, HomeVisitDetailScreen(r.id))); await tester.pumpAndSettle();
    expect(find.text(r.phone), findsNothing);
    expect(find.text('Request unavailable for this profile'), findsOneWidget);
  });

  testWidgets('doctor and home administration fit narrow Arabic and English screens', (tester) async {
    tester.view.physicalSize = const Size(360, 900); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final s = AppStore(), r = request(s);
    for (final arabic in [true, false]) {
      s.arabic = arabic;
      for (final page in <Widget>[const CareAdminScreen(), const DoctorAdminScreen(),
        const DoctorDetailScreen('doctor1'), const HomeServiceCatalog(), const HomeServiceAdminScreen(),
        const HomeRequestsAdminScreen(), HomeVisitDetailScreen(r.id, admin: true)]) {
        await tester.pumpWidget(careHost(s, page)); await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${page.runtimeType} / $arabic');
      }
    }
  });
}
