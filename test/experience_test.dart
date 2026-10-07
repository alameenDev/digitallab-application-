import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_lab_patient/main.dart';

Widget preview(AppStore s,Widget page,{bool reduceMotion=false})=>AppScope(store:s,child:MaterialApp(
  locale:Locale(s.arabic?'ar':'en'),supportedLocales:const [Locale('ar'),Locale('en')],
  localizationsDelegates:GlobalMaterialLocalizations.delegates,
  theme:buildTheme(Brightness.light),
  builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(
    disableAnimations:reduceMotion,textScaler:TextScaler.linear(s.textScale)),child:child!),
  home:page));

void phoneSize(WidgetTester tester,{double width=390,double height=1000}){
  tester.view.physicalSize=Size(width,height);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
}

void main(){
  test('care checklist and questions are isolated per person',(){
    final s=AppStore();s.addPatient('Child','Child');
    s.checkCare('p1',0,true);s.visitQuestions['p1']='Question for the visit';
    s.selectPatient('p2');
    expect(s.careChecks[s.patientId],isNull);
    expect(s.visitQuestions[s.patientId],isNull);
    s.checkCare('p2',1,true);
    expect(s.careChecks['p1'],{0});expect(s.careChecks['p2'],{1});
  });
  test('loyalty vouchers spend points once; use and cancellation control availability',(){
    final s=AppStore();
    final v=s.claimReward(500)!;
    expect(s.points,1950);expect(s.tierIndex,2);expect(s.tierProgress,.15);
    expect(s.discountFor(services[0],v.code),5000);
    expect(s.discountFor(services[3],v.code),0);
    s.useVoucher(v.code);expect(s.discountFor(services[0],v.code),0);
    final b=Booking(id:'demo',serviceId:'wellness',patientId:'p1',date:DateTime.now(),
      phone:'07701234567',address:'',notes:'',mode:'clinic',payment:'provider',
      total:40000,discount:5000,voucherCode:v.code);
    s.addBooking(b);s.cancelBooking(b);
    expect(s.discountFor(services[0],v.code),5000);expect(s.points,1950);
    expect(s.claimReward(99999),isNull);
    s.claimReward(1500);expect(s.claimReward(500),isNull);
  });
  testWidgets('three banner buttons open the matching feature',(tester) async {
    phoneSize(tester,height:1200);
    final s=AppStore()..arabic=false;
    await tester.pumpWidget(preview(s,const Scaffold(body:ScreenBody(children:[CampaignCarousel(autoplay:false)]))));
    await tester.pumpAndSettle();
    for(var i=0;i<3;i++){
      await tester.tap(find.byKey(ValueKey('campaign-dot-$i')));await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('campaign-open-$i')));await tester.pumpAndSettle();
      expect(i==0?find.byType(HomeCollectionHub):i==1?find.byType(FamilyHub):find.byType(LoyaltyExperience),findsOneWidget);
      await tester.pageBack();await tester.pumpAndSettle();
    }
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('banner autoplay respects pause and reduced motion',(tester) async {
    phoneSize(tester,height:1200);
    final s=AppStore()..arabic=false;
    await tester.pumpWidget(preview(s,const Scaffold(body:ScreenBody(children:[CampaignCarousel()]))));
    await tester.pump(const Duration(seconds:7));await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('campaign-open-1')).hitTestable(),findsOneWidget);
    await tester.tap(find.byTooltip('Pause banners'));await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds:8));await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('campaign-open-1')).hitTestable(),findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(preview(s,const Scaffold(body:ScreenBody(children:[CampaignCarousel()])),reduceMotion:true));
    await tester.pump(const Duration(seconds:8));await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('campaign-open-0')).hitTestable(),findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('story opens a real feature and records viewing',(tester) async {
    final s=AppStore()..arabic=false;
    await tester.pumpWidget(preview(s,const Scaffold(body:StoryStrip())));
    await tester.tap(find.byKey(const ValueKey('story-0')));await tester.pumpAndSettle();
    expect(s.viewedStories,{0});
    await tester.ensureVisible(find.byKey(const ValueKey('story-cta')));
    await tester.tap(find.byKey(const ValueKey('story-cta')));await tester.pumpAndSettle();
    expect(find.byType(HomeCollectionHub),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  testWidgets('comparison selection changes the table and empty state',(tester) async {
    phoneSize(tester);
    final s=AppStore()..arabic=false;
    await tester.pumpWidget(preview(s,const PackageComparisonScreen()));await tester.pumpAndSettle();
    expect(find.byType(DataTable),findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('compare-vitamins')));await tester.pumpAndSettle();
    expect(find.byType(DataTable),findsNothing);
    await tester.tap(find.byKey(const ValueKey('compare-liver')));await tester.pumpAndSettle();
    expect(find.byType(DataTable),findsOneWidget);
    expect(s.compareIds,{'wellness','liver'});
    expect(tester.takeException(),isNull);
  });
  testWidgets('voucher from reward is prefilled and consumed by checkout',(tester) async {
    phoneSize(tester,width:500,height:1400);
    final s=AppStore()..arabic=false;
    final v=s.claimReward(500)!;
    await tester.pumpWidget(preview(s,BookingScreen(services[0],couponCode:v.code)));
    await tester.enterText(find.byKey(const ValueKey('booking-phone')),'07701234567');
    await tester.tap(find.byKey(const ValueKey('booking-next')));await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('booking-next')));await tester.pumpAndSettle();
    expect(find.text(v.code),findsOneWidget);
    await tester.ensureVisible(find.byType(CheckboxListTile));await tester.tap(find.byType(CheckboxListTile));
    await tester.ensureVisible(find.byKey(const ValueKey('booking-next')));
    await tester.tap(find.byKey(const ValueKey('booking-next')));await tester.pumpAndSettle();
    expect(s.bookings.single.total,40000);expect(v.used,isTrue);
    expect(s.bookings.single.voucherCode,v.code);
    expect(tester.takeException(),isNull);
  });
  testWidgets('new feature pages fit narrow Arabic and English layouts',(tester) async {
    phoneSize(tester,width:360,height:1000);
    final s=AppStore();
    final pages=<Widget>[const FamilyHub(),const CarePlanScreen(),const PackageComparisonScreen(),
      const HomeCollectionHub(),const LoyaltyExperience()];
    for(final arabic in [true,false]){
      s.arabic=arabic;
      for(final page in pages){
        await tester.pumpWidget(preview(s,page));await tester.pumpAndSettle();
        expect(tester.takeException(),isNull,reason:'${page.runtimeType} / $arabic');
      }
    }
  });
}
