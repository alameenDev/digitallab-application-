import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:digital_lab_patient/main.dart';
import 'package:digital_lab_patient/patient_mobile/api.dart';
import 'package:digital_lab_patient/patient_mobile/store.dart';
import 'package:digital_lab_patient/patient_mobile/screens.dart';

class MemoryVault implements PatientSessionVault {
  String? value;
  @override Future<String?> read() async => value;
  @override Future<void> write(String next) async { value=next; }
}
Map<String,dynamic> profile({int id=1}) => {'token':'synthetic-token-$id',
  'expires_at':DateTime.now().add(const Duration(days:1)).toIso8601String(),
  'patient':{'id':id,'name':'مريض تجريبي $id','code':'P$id'},
  'lab':{'id':id,'name':'مختبر اختبار $id'}};
Map<String,dynamic> overview({int id=1}) => {
  'patient':{'id':id,'name':'مريض تجريبي $id','code':'P$id','phone':'07701234567'},
  'lab':{'id':id,'name':'مختبر اختبار $id','address':'عنوان تجريبي'},
  'loyalty':{'balance':120,'enabled':true,'yearly_points':120,
    'tier':{'label_ar':'الفضية','min_yearly_points':0},'next_tier':null,'catalog':[]},
  'reports':{'items':[
    {'id':11,'status':'ready','date':'2026-10-07','tests':[{'name':'Glucose'}],'total':10000,'paid':4000,'due':6000},
    {'id':12,'status':'pending','date':'2026-10-07','tests':[{'name':'CBC'}],'total':10000,'paid':10000,'due':0},
  ],'next_page':null},
};
http.Response response(Object value,{int status=200}) =>
  http.Response(jsonEncode(value),status,headers:{'content-type':'application/json; charset=utf-8'});
MockClient fixtureClient(List<http.Request> requests) => MockClient((r) async {
  requests.add(r);
  if(r.url.path.endsWith('/exchange')) return response(profile(),status:201);
  if(r.url.path.endsWith('/me')) return response(overview());
  if(r.url.path.endsWith('/points')) return response({'items':[],'next_page':null});
  if(r.url.path.endsWith('/session')) return response({'message':'revoked'});
  if(r.url.path.endsWith('/reports/11')) return response({
    'report':{'id':11,'date':'2026-10-07'},'sections':[{'name':'Glucose','items':[
      {'name':'Glucose','value':'91','unit':'mg/dL','ranges':[{'from':'70','to':'100'}],'parts':[],'comment':''}
    ]}]});
  return response({'message':'not found'},status:404);
});
Widget host(Widget child) => MaterialApp(locale:const Locale('ar'),supportedLocales:const [Locale('ar'),Locale('en')],
  localizationsDelegates:GlobalMaterialLocalizations.delegates,theme:buildTheme(Brightness.light),home:child);

void main() {
  test('Arabic and international phone numbers normalize consistently',(){
    for(final v in ['07701234567','+9647701234567','00964 7701234567','٠٧٧٠١٢٣٤٥٦٧','۰۷۷۰۱۲۳۴۵۶۷']) {
      expect(normalizePatientPhone(v),'9647701234567');
    }
    for(final v in ['123','+17701234567','077012345678','invalid']) { expect(normalizePatientPhone(v),isNull); }
    expect(normalizePairingCode('١٢٣٤ ٥٦٧٨ ٩٠١٢'),'123456789012');
  });
  test('API rejects insecure remote URL and credential-bearing URL',(){
    for(final base in ['http://lab.example.test/api','https://user:secret@lab.example.test/api','https://lab.example.test/api?token=secret']) {
      expect(()=>PatientApi(base),throwsA(isA<PatientApiException>()));
    }
  });
  test('pairing secrets use JSON and session credentials use Authorization only',() async {
    final requests=<http.Request>[],vault=MemoryVault();
    final s=LinkedPatientStore(PatientApi('https://lab.example.test/api',client:fixtureClient(requests)),vault);
    await s.restore(); await s.link('9647701234567','123456789012');
    expect(s.overview!['loyalty']['balance'],120);
    expect(requests.first.url.query,isEmpty);
    expect(jsonDecode(requests.first.body),{'phone':'9647701234567','code':'123456789012'});
    expect(requests.first.headers.containsKey('Authorization'),isFalse);
    expect(requests[1].headers['Authorization'],'Bearer synthetic-token-1');
    expect(requests.every((r)=>!r.followRedirects),isTrue);
    expect(vault.value,contains('synthetic-token-1'));
    expect(vault.value, isNot(contains('Glucose')));
    await s.logout();
    expect(s.selected,isNull); expect(s.overview,isNull); expect(s.reports,isEmpty);
    expect(requests.last.method,'DELETE');
    expect(jsonDecode(vault.value!),isEmpty);
    s.dispose();
  });
  test('expired session clears cached patient data and credential',() async {
    final vault=MemoryVault()..value=jsonEncode([profile()]);
    final s=LinkedPatientStore(PatientApi('https://lab.example.test/api',
      client:MockClient((_)async=>response({'message':'expired'},status:401))),vault);
    await s.restore();
    expect(s.selected,isNull); expect(s.overview,isNull); expect(s.profiles,isEmpty);
    expect(s.error,contains('انتهى'));
    s.dispose();
  });
  test('late response cannot overwrite a newly selected patient',() async {
    final waiting=Completer<http.Response>();
    final api=PatientApi('https://lab.example.test/api',client:MockClient((r) async {
      final first=r.headers['Authorization']=='Bearer synthetic-token-1';
      if(r.url.path.endsWith('/points')) return response({'items':[],'next_page':null});
      return first?waiting.future:response(overview(id:2));
    }));
    final s=LinkedPatientStore(api,MemoryVault());
    final one=LinkedPatient.fromJson(profile()),two=LinkedPatient.fromJson(profile(id:2));
    final loading=s.select(one);
    await s.select(two);
    waiting.complete(response(overview()));
    await loading;
    expect(s.selected!.patientId,2);expect(s.overview!['patient']['id'],2);
    s.dispose();
  });
  testWidgets('390px Arabic pairing form validates before calling the server',(tester)async{
    tester.view.physicalSize=const Size(390,900);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final requests=<http.Request>[];
    final s=LinkedPatientStore(PatientApi('https://lab.example.test/api',client:fixtureClient(requests)),MemoryVault());
    await tester.pumpWidget(host(Scaffold(body:SingleChildScrollView(padding:const EdgeInsets.all(20),child:PatientLinkForm(store:s)))));
    await tester.tap(find.byKey(const ValueKey('patient-link-submit')));await tester.pumpAndSettle();
    expect(requests,isEmpty);
    expect(find.text('أدخل رقم هاتف عراقي صحيحاً.'),findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('patient-phone')),'07701234567');
    await tester.enterText(find.byKey(const ValueKey('patient-pairing-code')),'1234 5678 9012');
    await tester.ensureVisible(find.byKey(const ValueKey('patient-link-submit')));
    await tester.tap(find.byKey(const ValueKey('patient-link-submit')));await tester.pumpAndSettle();
    expect(s.selected!.patientId,1);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());s.dispose();
  });
  testWidgets('linked dashboard displays real balance, pending report is disabled and ready details load',(tester)async{
    tester.view.physicalSize=const Size(390,900);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final requests=<http.Request>[],vault=MemoryVault()..value=jsonEncode([profile()]);
    final s=LinkedPatientStore(PatientApi('https://lab.example.test/api',client:fixtureClient(requests)),vault);
    await tester.pumpWidget(host(PatientMobileRoot(baseUrl:'https://lab.example.test/api',store:s)));
    await tester.pumpAndSettle();
    expect(find.text('120 نقطة'),findsOneWidget);
    expect(find.text('مختبر اختبار 1'),findsWidgets);
    await tester.tap(find.text('تقاريري'));await tester.pumpAndSettle();
    final pending=find.widgetWithText(FilledButton,'بانتظار اعتماد التقرير');
    await tester.ensureVisible(pending);
    expect(tester.widget<FilledButton>(pending).onPressed,isNull);
    expect(requests.where((r)=>r.url.path.endsWith('/reports/12')),isEmpty);
    final ready=find.widgetWithText(FilledButton,'عرض النتائج');
    await tester.ensureVisible(ready);await tester.tap(ready);await tester.pumpAndSettle();
    expect(find.text('91 mg/dL'),findsOneWidget);
    expect(find.textContaining('Reference range'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());s.dispose();
  });
}
