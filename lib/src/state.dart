part of '../main.dart';

const accent = Color(0xFF087F7B);
const midnight = Color(0xFF112F3B);
const mint = Color(0xFFE6F5EF);
const amber = Color(0xFFBC7728);

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key,required AppStore store,required super.child}) : super(notifier: store);
  static AppStore of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class Service {
  const Service(this.id,this.kind,this.ar,this.en,this.subAr,this.subEn,
    this.price,this.icon,this.detailsAr,this.detailsEn);
  final String id,kind,ar,en,subAr,subEn,detailsAr,detailsEn;
  final int price;
  final IconData icon;
  String title(AppStore s) => s.t(ar,en);
  String subtitle(AppStore s) => s.t(subAr,subEn);
}
const services = <Service>[
  Service('wellness','packages','اطمئنان شامل','Everyday wellness',
    'مختبر الحياة التجريبي • 12 فحصاً','Demo Life Lab • 12 tests',45000,
    Icons.spa_outlined,'باقة عرض تشمل صورة الدم، السكر، الدهون ومؤشرات الكبد والكلى. تعليمات التحضير تُؤكّد مع المختبر عند الربط.',
    'Demo panel with blood count, glucose, lipids, liver and kidney markers. Preparation must be confirmed with the lab.'),
  Service('vitamins','packages','طاقة وتوازن','Energy & balance',
    'مختبر الحياة التجريبي • 4 فحوصات','Demo Life Lab • 4 tests',35000,
    Icons.wb_sunny_outlined,'عرض لباقة فيتامينات ومخزون الحديد. قائمة الفحوصات والأسعار تجريبية.',
    'A demonstration vitamin and iron panel. Test lists and prices are illustrative.'),
  Service('liver','packages','صحة الكبد','Liver health',
    'مختبر النور التجريبي • 6 فحوصات','Demo Noor Lab • 6 tests',30000,
    Icons.favorite_border,'باقة لعرض رحلة الحجز وظهور النتائج. لا تمثل توصية بإجراء الفحص.',
    'A panel for demonstrating booking and results. This is not a recommendation to get tested.'),
  Service('doctor1','doctors','د. لينا — شخصية تجريبية','Dr Lina — demo profile',
    'طب الأسرة • بغداد، المنصور','Family medicine • Baghdad, Mansour',35000,
    Icons.medical_services_outlined,'ملف طبيب توضيحي. حضوري، محادثة، صوت وفيديو. المؤهلات والمواعيد تحتاج تحققاً قبل الإطلاق.',
    'Illustrative doctor profile. Clinic, chat, voice and video visits. Credentials and availability need verification before launch.'),
  Service('doctor2','doctors','د. عمر — شخصية تجريبية','Dr Omar — demo profile',
    'الباطنية • بغداد، الكرادة','Internal medicine • Baghdad, Karrada',40000,
    Icons.health_and_safety_outlined,'ملف طبيب تجريبي لاستعراض الحجز ومشاركة التقارير بموافقة المريض.',
    'Fictional doctor profile to preview appointments and patient-approved report sharing.'),
  Service('lab1','labs','مختبر الحياة التجريبي','Demo Life Laboratory',
    'المنصور • فرع تجريبي','Mansour • Demo branch',0,
    Icons.biotech,'فرع المنصور: 08:00–20:00. سحب منزلي واستلام نتائج. العنوان والمواعيد للعرض فقط.',
    'Mansour branch: 08:00–20:00. Home collection and results. Address and hours are illustrative.'),
  Service('lab2','labs','مختبر النور التجريبي','Demo Noor Laboratory',
    'الكرادة • فرع تجريبي','Karrada • Demo branch',0,
    Icons.science_outlined,'فرع الكرادة: 09:00–18:00. حجز زيارة مختبر. جميع بيانات الفرع تجريبية.',
    'Karrada branch: 09:00–18:00. Lab visit booking. All branch information is fictional.'),
];
class Patient {
  Patient(this.id,this.name,{this.relation = ''});
  final String id;
  String name,relation;
  final Map<String,String> medical = {};
}
class Report {
  const Report(this.id,this.patientId,this.ar,this.en,this.ready,this.date);
  final String id,patientId,ar,en,date;
  final bool ready;
}
const reports = [
  Report('DL-24081','p1','صورة الدم الكاملة','Complete blood count',true,'05/10/2026'),
  Report('DL-24092','p1','وظائف الكبد','Liver function',false,'07/10/2026'),
];
class Marker {
  const Marker(this.name,this.value,this.previous,this.unit,this.low,this.high);
  final String name,unit;
  final double value,previous,low,high;
}
const markers = [
  Marker('Hemoglobin',14.2,13.8,'g/dL',12,16),
  Marker('WBC',7.2,6.8,'10³/µL',4,11),
  Marker('RBC',4.8,4.6,'10⁶/µL',4.2,5.4),
  Marker('Platelets',250,235,'10³/µL',150,400),
];
class Booking {
  Booking({required this.id,required this.serviceId,required this.patientId,
    required this.date,required this.phone,required this.address,required this.notes,
    required this.mode,required this.payment,required this.total,required this.discount});
  final String id,serviceId,patientId,phone,address,notes,mode,payment;
  final int total,discount;
  DateTime date;
  String status = 'upcoming';
  int progress = 0;
  bool get home => mode == 'home';
  Service get service => services.firstWhere((e) => e.id == serviceId);
}
class ShareGrant {
  ShareGrant(this.patientId,this.recipient,this.scope,this.expires);
  final String patientId,recipient,scope;
  final DateTime expires;
  bool revoked = false;
  bool get active => !revoked && expires.isAfter(DateTime.now());
}
class ReminderItem {
  ReminderItem(this.title,this.date);
  final String title;
  final DateTime date;
  bool done = false;
}
class AppStore extends ChangeNotifier {
  bool arabic = true;
  ThemeMode themeMode = ThemeMode.light;
  double textScale = 1;
  final patients = [Patient('p1','أحمد علي',relation:'self')];
  String patientId = 'p1';
  final List<Booking> bookings = [];
  final Set<String> favorites = {},recent = {},readNotifications = {};
  final List<ShareGrant> shares = [];
  final List<ReminderItem> reminders = [];
  final List<String> documents = [],tickets = [],claims = [],messages = [],reviews = [];
  final List<String> rewards = [];
  final Map<String,bool> preferences = {
    'results':true,'bookings':true,'offers':false,'marketing':false,'ai':false,'biometric':false,
  };
  int points = 2450;
  bool loggedInDemo = true;
  String t(String ar,String en) => arabic ? ar : en;
  Patient get patient => patients.firstWhere((p) => p.id == patientId);
  int get unreadCount => 3 - readNotifications.length;
  List<Report> get patientReports => reports.where((r) => r.patientId == patientId).toList();
  String money(int value) => '${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'),(m) => '${m[1]},')} ${t('د.ع','IQD')}';
  void update() => notifyListeners();
  void toggleLanguage() { arabic = !arabic; update(); }
  void selectPatient(String id) { patientId = id; update(); }
  void favorite(String id) { favorites.contains(id) ? favorites.remove(id) : favorites.add(id); update(); }
  void addPatient(String name,String relation) {
    patients.add(Patient('p${patients.length+1}',name,relation:relation)); update();
  }
  void addBooking(Booking value) { bookings.add(value); update(); }
  void cancelBooking(Booking value) { value.status = 'cancelled'; update(); }
  void redeem() {
    if (points < 500) return;
    points -= 500; rewards.add('DEMO-${rewards.length+1}'); update();
  }
}
String dateLabel(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} • ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
bool validIraqiPhone(String value) => RegExp(r'^(?:\+964|00964|0)7[3-9]\d{8}$').hasMatch(value.replaceAll(RegExp(r'[\s-]'),''));
int promoDiscount(Service service,String code) =>
  service.kind == 'packages' && code.trim().toUpperCase() == 'DIGITAL10'
    ? math.min(10000,(service.price * .1).round()) : 0;
