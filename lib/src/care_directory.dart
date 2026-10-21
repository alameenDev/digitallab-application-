part of '../main.dart';

String careDigits(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩', persian = '۰۱۲۳۴۵۶۷۸۹';
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  return value.replaceAll('٫', '.').trim();
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude, longitude;
  bool get valid => latitude.isFinite && longitude.isFinite &&
      latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  static GeoPoint? parse(String latitude, String longitude) {
    if (latitude.trim().isEmpty && longitude.trim().isEmpty) return null;
    final lat = double.tryParse(careDigits(latitude));
    final lng = double.tryParse(careDigits(longitude));
    if (lat == null || lng == null || !GeoPoint(lat, lng).valid) {
      throw const FormatException('Invalid coordinates');
    }
    return GeoPoint(lat, lng);
  }
  Uri get mapUrl => Uri.https('www.google.com', '/maps/search/',
      {'api': '1', 'query': '$latitude,$longitude'});
  String get label => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

const socialLabels = <String, String>{
  'facebook': 'Facebook', 'instagram': 'Instagram', 'whatsapp': 'WhatsApp',
  'tiktok': 'TikTok', 'website': 'Website',
};
Uri? careWebUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
      uri.userInfo.isNotEmpty || RegExp(r'\s').hasMatch(value.trim())) return null;
  return uri;
}
bool validSocialLink(String key, String value) {
  if (value.trim().isEmpty) return true;
  final uri = careWebUri(value);
  if (uri == null) return false;
  const hosts = <String, List<String>>{
    'facebook': ['facebook.com', 'fb.com'], 'instagram': ['instagram.com'],
    'whatsapp': ['wa.me', 'whatsapp.com'], 'tiktok': ['tiktok.com'],
  };
  return key == 'website' || (hosts[key] ?? []).any(
      (host) => uri.host == host || uri.host.endsWith('.$host'));
}
Future<void> openCareLink(BuildContext context, Uri uri) async {
  final s = AppScope.of(context);
  try {
    if (uri.scheme == 'https' && await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) { /* A blocked browser popup should not crash the page. */ }
  if (context.mounted) {
    showDialog<void>(context: context, builder: (c) => AlertDialog(
      title: Text(s.t('تعذّر فتح الرابط', 'Could not open link')),
      content: SelectableText(uri.toString(), textDirection: TextDirection.ltr),
      actions: [TextButton(onPressed: () async {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (c.mounted) Navigator.pop(c);
      }, child: Text(s.t('نسخ الرابط', 'Copy link')))],
    ));
  }
}

class DoctorProfile {
  const DoctorProfile({required this.id, required this.name, required this.specialty,
    required this.address, required this.area, this.nameEn = '', this.bio = '',
    this.clinic = '', this.phone = '', this.photo, this.location,
    this.socials = const {}, this.fee = 0, this.active = true});
  final String id, name, nameEn, specialty, address, area, bio, clinic, phone;
  final Uint8List? photo;
  final GeoPoint? location;
  final Map<String, String> socials;
  final int fee;
  final bool active;
  String title(AppStore s) => !s.arabic && nameEn.isNotEmpty ? nameEn : name;
  bool get valid => name.trim().isNotEmpty && specialty.trim().isNotEmpty &&
      address.trim().length >= 8 && area.trim().isNotEmpty && fee >= 0 &&
      (phone.isEmpty || validIraqiPhone(careDigits(phone))) &&
      (location == null || location!.valid) &&
      socials.entries.every((e) => validSocialLink(e.key, e.value));
  Service get service => Service(id, 'doctors', name, nameEn.isEmpty ? name : nameEn,
      '$specialty • $area', '$specialty • $area', fee, Icons.medical_services_outlined, bio, bio);
  DoctorProfile withActive(bool value) => DoctorProfile(id: id, name: name,
    nameEn: nameEn, specialty: specialty, address: address, area: area,
    bio: bio, clinic: clinic, phone: phone, photo: photo, location: location,
    socials: socials, fee: fee, active: value);
}
List<DoctorProfile> initialDoctors() => [
  const DoctorProfile(id: 'doctor1', name: 'د. لينا — ملف تجريبي', nameEn: 'Dr Lina — demo',
    specialty: 'طب الأسرة / Family medicine', area: 'المنصور / Mansour',
    clinic: 'عيادة تجريبية', address: 'بغداد، المنصور — عنوان توضيحي', fee: 35000,
    bio: 'ملف توضيحي لتجربة البحث والحجز. لا يمثل طبيباً أو عيادة حقيقية.'),
  const DoctorProfile(id: 'doctor2', name: 'د. عمر — ملف تجريبي', nameEn: 'Dr Omar — demo',
    specialty: 'الباطنية / Internal medicine', area: 'الكرادة / Karrada',
    clinic: 'عيادة تجريبية', address: 'بغداد، الكرادة — عنوان توضيحي', fee: 40000,
    bio: 'ملف توضيحي لتجربة البحث والحجز. لا يمثل طبيباً أو عيادة حقيقية.'),
];

class HomeVisitService {
  const HomeVisitService({required this.id, required this.name, required this.labId,
    required this.areas, required this.fee, this.notes = '', this.active = true,
    this.hours = const [9, 10, 11, 13, 15, 17]});
  final String id, name, labId, notes;
  final List<String> areas;
  final List<int> hours;
  final int fee;
  final bool active;
  bool get valid => name.trim().isNotEmpty && fee >= 0 && areas.isNotEmpty &&
      areas.every((a) => a.trim().isNotEmpty) && hours.isNotEmpty &&
      hours.every((h) => h >= 0 && h <= 23) &&
      services.any((s) => s.id == labId && s.kind == 'labs');
  Service get lab => services.firstWhere((s) => s.id == labId);
  HomeVisitService withActive(bool value) => HomeVisitService(id: id, name: name,
      labId: labId, areas: areas, fee: fee, notes: notes, hours: hours, active: value);
}
List<HomeVisitService> initialHomeVisitServices() => [
  const HomeVisitService(id: 'home-life', name: 'سحب منزلي — مختبر الحياة التجريبي',
      labId: 'lab1', areas: ['المنصور', 'الحارثية'], fee: 10000,
      notes: 'يؤكد المختبر متطلبات التحضير حسب التحاليل المطلوبة.'),
  const HomeVisitService(id: 'home-noor', name: 'سحب منزلي — مختبر النور التجريبي',
      labId: 'lab2', areas: ['الكرادة', 'الجادرية'], fee: 12000,
      notes: 'موعد الزيارة المطلوب يخضع لتأكيد المختبر.'),
];
enum HomeVisitStatus { pending, confirmed, assigned, onWay, collected, completed, cancelled }
String visitStatusLabel(AppStore s, HomeVisitStatus status) => switch (status) {
  HomeVisitStatus.pending => s.t('بانتظار التأكيد', 'Awaiting confirmation'),
  HomeVisitStatus.confirmed => s.t('مؤكد', 'Confirmed'),
  HomeVisitStatus.assigned => s.t('تم تعيين الفني', 'Collector assigned'),
  HomeVisitStatus.onWay => s.t('الفني بالطريق', 'On the way'),
  HomeVisitStatus.collected => s.t('تم سحب العينة', 'Sample collected'),
  HomeVisitStatus.completed => s.t('اكتملت الزيارة', 'Visit completed'),
  HomeVisitStatus.cancelled => s.t('ملغي', 'Cancelled'),
};
class VisitEvent {
  VisitEvent(this.status, this.at);
  final HomeVisitStatus status;
  final DateTime at;
}
class HomeVisitRequest {
  HomeVisitRequest({required this.id, required this.patientId, required this.patientName,
    required this.service, required this.phone, required this.address, required this.area,
    required this.tests, required this.scheduledAt, required this.createdAt,
    this.landmark = '', this.notes = '', this.location}) {
    history.add(VisitEvent(HomeVisitStatus.pending, createdAt));
  }
  final String id, patientId, patientName, phone, address, area, tests, landmark, notes;
  // Snapshot: editing a service never changes the fee or provider of an old request.
  final HomeVisitService service;
  final DateTime scheduledAt, createdAt;
  final GeoPoint? location;
  HomeVisitStatus status = HomeVisitStatus.pending;
  String collector = '';
  final List<VisitEvent> history = [];
  bool get closed => status == HomeVisitStatus.cancelled || status == HomeVisitStatus.completed;
  bool get patientCanCancel => status == HomeVisitStatus.pending ||
      status == HomeVisitStatus.confirmed || status == HomeVisitStatus.assigned;
}

extension CareStore on AppStore {
  List<Service> get catalogServices => [
    ...services.where((v) => v.kind != 'doctors'),
    ...doctors.where((v) => v.active).map((v) => v.service),
  ];
  DoctorProfile? doctorById(String id) {
    for (final doctor in doctors) { if (doctor.id == id) return doctor; }
    return null;
  }
  void saveDoctor(DoctorProfile doctor) {
    if (!doctor.valid) throw const FormatException('Invalid doctor');
    final i = doctors.indexWhere((d) => d.id == doctor.id);
    i < 0 ? doctors.add(doctor) : doctors[i] = doctor;
    update();
  }
  void saveHomeService(HomeVisitService service) {
    if (!service.valid) throw const FormatException('Invalid service');
    final i = homeVisitServices.indexWhere((d) => d.id == service.id);
    i < 0 ? homeVisitServices.add(service) : homeVisitServices[i] = service;
    update();
  }
  HomeVisitRequest submitHomeVisit({required String serviceId, required String forPatient,
    required String phone, required String address, required String area, required String tests,
    required DateTime scheduledAt, String landmark = '', String notes = '', GeoPoint? location,
    DateTime? now}) {
    final clock = now ?? DateTime.now();
    final service = homeVisitServices.where((v) => v.id == serviceId && v.active).firstOrNull;
    final person = patients.where((p) => p.id == forPatient).firstOrNull;
    final tomorrow = DateTime(clock.year, clock.month, clock.day + 1);
    final last = DateTime(clock.year, clock.month, clock.day + 31);
    if (service == null || person == null || !validIraqiPhone(careDigits(phone)) ||
        address.trim().length < 8 || tests.trim().length < 3 || !service.areas.contains(area) ||
        scheduledAt.isBefore(tomorrow) || !scheduledAt.isBefore(last) ||
        !service.hours.contains(scheduledAt.hour) || scheduledAt.minute != 0 ||
        (location != null && !location.valid)) {
      throw const FormatException('Invalid or unavailable request');
    }
    final request = HomeVisitRequest(id: 'HV-${careSequence++}', patientId: person.id,
      patientName: person.name, service: service, phone: careDigits(phone), address: address.trim(),
      area: area, tests: tests.trim(), scheduledAt: scheduledAt, createdAt: clock,
      landmark: landmark.trim(), notes: notes.trim(), location: location);
    homeVisitRequests.insert(0, request); update(); return request;
  }
  bool advanceHomeVisit(HomeVisitRequest request, {String? collector}) {
    if (!homeVisitRequests.contains(request) || request.closed) return false;
    if (request.status == HomeVisitStatus.confirmed) {
      if ((collector ?? '').trim().length < 2) return false;
      request.collector = collector!.trim();
    }
    request.status = HomeVisitStatus.values[request.status.index + 1];
    request.history.add(VisitEvent(request.status, DateTime.now())); update(); return true;
  }
  bool cancelHomeVisit(HomeVisitRequest request, {bool byAdmin = false}) {
    if (!homeVisitRequests.contains(request) || request.closed ||
        request.status.index >= HomeVisitStatus.collected.index ||
        (!byAdmin && (request.patientId != patientId || !request.patientCanCancel))) return false;
    request.status = HomeVisitStatus.cancelled;
    request.history.add(VisitEvent(request.status, DateTime.now())); update(); return true;
  }
}

class CarePreviewNote extends StatelessWidget {
  const CarePreviewNote({super.key});
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Note(s.t('معاينة ببيانات تجريبية. التعديلات والطلبات محفوظة خلال الجلسة فقط، ولا تُرسل لمختبر أو فني.',
      'Design preview. Changes and requests last for this session only; nothing is sent to a lab or collector.'));
  }
}

class LocationFields extends StatelessWidget {
  const LocationFields({super.key, required this.latitude, required this.longitude, this.prefix = 'location'});
  final TextEditingController latitude, longitude;
  final String prefix;
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    String? validate(String? _) {
      try { GeoPoint.parse(latitude.text, longitude.text); return null; }
      catch (_) { return s.t('أدخل إحداثيين صالحين أو اتركهما فارغين', 'Enter both valid coordinates or leave both blank'); }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextFormField(key: ValueKey('$prefix-lat'), controller: latitude,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        textDirection: TextDirection.ltr, validator: validate,
        decoration: InputDecoration(labelText: s.t('خط العرض — اختياري', 'Latitude — optional'), hintText: '33.3152')),
      const SizedBox(height: 12),
      TextFormField(key: ValueKey('$prefix-lng'), controller: longitude,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        textDirection: TextDirection.ltr, validator: validate,
        decoration: InputDecoration(labelText: s.t('خط الطول — اختياري', 'Longitude — optional'), hintText: '44.3661')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () {
        try {
          final point = GeoPoint.parse(latitude.text, longitude.text);
          if (point == null) { toast(context, s.t('أدخل الإحداثيات أولاً', 'Enter coordinates first')); return; }
          openCareLink(context, point.mapUrl);
        } catch (_) { toast(context, s.t('تحقق من الإحداثيات', 'Check the coordinates')); }
      }, icon: const Icon(Icons.map_outlined), label: Text(s.t('معاينة الموقع على الخريطة', 'Preview location on map'))),
      Text(s.t('انسخ الإحداثيات من خرائط Google: خط العرض أولاً ثم خط الطول.',
        'Copy coordinates from Google Maps: latitude first, then longitude.'), style: TextStyle(fontSize: 12, color: muted(context))),
    ]);
  }
}
