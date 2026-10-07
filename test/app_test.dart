import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_lab_patient/main.dart';

Widget host(AppStore store,Widget page) => AppScope(store:store,child:MaterialApp(
  locale:Locale(store.arabic?'ar':'en'),
  supportedLocales:const [Locale('ar'),Locale('en')],
  localizationsDelegates:GlobalMaterialLocalizations.delegates,
  theme:buildTheme(Brightness.light),home:page));

void main() {
  test('Iraqi phone validation accepts local and international forms',(){
    for(final v in ['07701234567','+9647701234567','009647701234567','0770 123 4567']) {
      expect(validIraqiPhone(v),isTrue,reason:v);
    }
    for(final v in ['123','0770123456','+17012345678','']) {
      expect(validIraqiPhone(v),isFalse,reason:v);
    }
  });
  test('coupon applies only to package base price',(){
    expect(promoDiscount(services[0],' digital10 '),4500);
    expect(promoDiscount(services[3],'DIGITAL10'),0);
    expect(promoDiscount(services[0],'invalid'),0);
  });
  test('patient reports are isolated and reward points cannot go negative',(){
    final s=AppStore();
    expect(s.patientReports.length,2);
    s.addPatient('Family demo','Child');
    s.selectPatient('p2');
    expect(s.patientReports,isEmpty);
    for(var i=0;i<10;i++){s.redeem();}
    expect(s.points,450);
    expect(s.rewards.length,4);
  });
  test('expired and revoked sharing permissions are inactive',(){
    final expired=ShareGrant('p1','Demo','all',DateTime.now().subtract(const Duration(hours:1)));
    expect(expired.active,isFalse);
    final active=ShareGrant('p1','Demo','latest',DateTime.now().add(const Duration(hours:1)));
    expect(active.active,isTrue);
    active.revoked=true;
    expect(active.active,isFalse);
  });
  testWidgets('Arabic home switches direction to English without overflow',(tester) async {
    tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final s=AppStore();
    await tester.pumpWidget(DigitalLabApp(store:s));await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(find.byType(AppShell))),TextDirection.rtl);
    expect(tester.takeException(),isNull);
    await tester.tap(find.byTooltip('تغيير اللغة'));await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(find.byType(AppShell))),TextDirection.ltr);
    expect(find.text('Home'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  testWidgets('pending report never exposes ready-report values',(tester) async {
    final s=AppStore()..arabic=false;
    await tester.pumpWidget(host(s,ReportScreen(reports[1])));
    await tester.pumpAndSettle();
    expect(find.text('Your report is being prepared'),findsOneWidget);
    expect(find.textContaining('Hemoglobin'),findsNothing);
    expect(find.textContaining('14.2'),findsNothing);
  });
  testWidgets('home booking validates, saves all details and can be cancelled',(tester) async {
    tester.view.physicalSize=const Size(500,1200);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final s=AppStore()..arabic=false;
    await tester.pumpWidget(host(s,BookingScreen(services[0],home:true)));
    await tester.tap(find.byKey(const ValueKey('booking-next')));await tester.pumpAndSettle();
    expect(find.textContaining('Enter a valid Iraqi'),findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('booking-phone')),'07701234567');
    await tester.tap(find.byKey(const ValueKey('booking-next')));await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('booking-next')));await tester.pumpAndSettle();
    expect(find.text('Enter a complete address'),findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('booking-address')),'Demo Baghdad street 12');
    await tester.enterText(find.byKey(const ValueKey('booking-notes')),'Call at the gate');
    await tester.tap(find.byKey(const ValueKey('booking-next')));await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('booking-coupon')),'DIGITAL10');
    await tester.tap(find.text('Apply'));await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('booking-next')));
    await tester.tap(find.byKey(const ValueKey('booking-next')));await tester.pumpAndSettle();
    expect(s.bookings.length,1);
    final b=s.bookings.single;
    expect(b.total,50500);expect(b.discount,4500);
    expect(b.address,'Demo Baghdad street 12');expect(b.notes,'Call at the gate');
    expect(b.phone,'07701234567');expect(b.home,isTrue);
    await tester.ensureVisible(find.text('Cancel booking'));
    await tester.tap(find.text('Cancel booking'));await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));await tester.pumpAndSettle();
    expect(b.status,'cancelled');
    expect(tester.takeException(),isNull);
  });
  testWidgets('family switch hides another person reports',(tester) async {
    final s=AppStore()..arabic=false;
    s.addPatient('Child demo','Child');
    await tester.pumpWidget(host(s,const Scaffold(body:ResultsScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Complete blood count'),findsOneWidget);
    s.selectPatient('p2');await tester.pumpAndSettle();
    expect(find.text('Complete blood count'),findsNothing);
    expect(find.text('No reports here'),findsOneWidget);
  });
  testWidgets('desktop uses rail; dark large-text mobile has no overflow',(tester) async {
    final s=AppStore()..arabic=false;
    tester.view.physicalSize=const Size(1280,900);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(DigitalLabApp(store:s));await tester.pumpAndSettle();
    expect(find.byType(NavigationRail),findsOneWidget);
    expect(tester.takeException(),isNull);
    tester.view.physicalSize=const Size(360,900);
    s.themeMode=ThemeMode.dark;s.textScale=1.3;s.update();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
