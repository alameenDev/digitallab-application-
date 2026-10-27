part of '../main.dart';

class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar(this.doctor, {super.key, this.size = 72});
  final DoctorProfile? doctor;
  final double size;
  @override Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .28),
    child: SizedBox(width: size, height: size, child: doctor?.photo == null
      ? ColoredBox(color: mint, child: Icon(Icons.person_outline, size: size * .55, color: accent))
      : Image.memory(doctor!.photo!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: mint, child: Icon(Icons.person_outline, color: accent)))),
  );
}

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen(this.id, {super.key});
  final String id;
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final doctor = s.doctorById(id);
    if (doctor == null || !doctor.active) {
      return DetailPage(title: s.t('الطبيب', 'Doctor'), children: [
        EmptyState(s.t('الملف غير متاح حالياً', 'Profile currently unavailable'),
          s.t('اختر طبيباً آخر من دليل الأطباء.', 'Choose another doctor from the directory.')),
      ]);
    }
    return DetailPage(title: s.t('ملف الطبيب', 'Doctor profile'), actions: [
      IconButton(tooltip: s.t('المفضلة', 'Favorite'), onPressed: () => s.favorite(id),
        icon: Icon(s.favorites.contains(id) ? Icons.favorite : Icons.favorite_border)),
    ], children: [
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [DoctorAvatar(doctor, size: 90), const Spacer(), Tag(s.t('ملف تجريبي', 'DEMO'))]),
        const SizedBox(height: 20), Heading(doctor.title(s), subtitle: doctor.specialty),
        if (doctor.clinic.isNotEmpty) Text(doctor.clinic, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10), Text(doctor.bio, style: TextStyle(color: muted(context), height: 1.7)),
        const Divider(), Wrap(spacing: 10, runSpacing: 10, children: [
          Tag(doctor.area), Tag('${s.t('أجر الزيارة', 'Visit fee')}: ${s.money(doctor.fee)}'),
        ]),
      ])),
      Section(s.t('العنوان والموقع', 'Address & location')),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(doctor.address, style: const TextStyle(height: 1.7)),
        if (doctor.location != null) ...[
          const SizedBox(height: 8), SelectableText(doctor.location!.label, textDirection: TextDirection.ltr),
          const SizedBox(height: 14), FilledButton.icon(key: const ValueKey('doctor-map'),
            onPressed: () => openCareLink(context, doctor.location!.mapUrl),
            icon: const Icon(Icons.directions_outlined), label: Text(s.t('فتح الموقع على الخريطة', 'Open location in Maps'))),
        ] else Padding(padding: const EdgeInsets.only(top: 10),
          child: Text(s.t('لم تُضف إحداثيات الموقع بعد', 'Map coordinates have not been added yet'),
            style: TextStyle(color: muted(context), fontSize: 12))),
      ])),
      if (doctor.phone.isNotEmpty) ActionRow(Icons.phone_outlined, doctor.phone,
        subtitle: s.t('اضغط لنسخ رقم العيادة', 'Tap to copy the clinic number'), onTap: () async {
          await Clipboard.setData(ClipboardData(text: doctor.phone));
          if (context.mounted) toast(context, s.t('تم نسخ الرقم', 'Number copied'));
        }),
      if (doctor.socials.values.any((v) => v.isNotEmpty)) ...[
        Section(s.t('تواصل مع الطبيب', 'Connect with the doctor')),
        Wrap(spacing: 10, runSpacing: 10, children: doctor.socials.entries.where((v) => v.value.isNotEmpty).map((e) =>
          OutlinedButton.icon(key: ValueKey('doctor-social-${e.key}'),
            onPressed: () => openCareLink(context, careWebUri(e.value)!),
            icon: const Icon(Icons.open_in_new, size: 17), label: Text(socialLabels[e.key] ?? e.key))).toList()),
      ],
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: () => go(context, BookingScreen(doctor.service)),
        icon: const Icon(Icons.calendar_month_outlined), label: Text(s.t('طلب موعد', 'Request appointment'))),
      const CarePreviewNote(),
    ]);
  }
}

class CareAdminScreen extends StatelessWidget {
  const CareAdminScreen({super.key});
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return DetailPage(title: s.t('إدارة تطبيق Digital Lab', 'Digital Lab app management'), actions: [
      IconButton(tooltip: s.t('تغيير اللغة', 'Change language'), onPressed: s.toggleLanguage, icon: const Icon(Icons.translate)),
    ], children: [
      Heading(s.t('دليل الرعاية والزيارات المنزلية', 'Care directory & home visits'),
        subtitle: s.t('أضف مقدمي الخدمة، رتّب تفاصيلهم وتابع الطلبات.', 'Manage provider details, service coverage and requests.')),
      const CarePreviewNote(),
      TileGrid(minWidth: 240, children: [
        FeatureTile(Icons.medical_services_outlined, '${s.doctors.where((d) => d.active).length}',
          s.t('طبيب ظاهر بالتطبيق', 'Visible doctors'), onTap: () => go(context, const DoctorAdminScreen())),
        FeatureTile(Icons.home_outlined, '${s.homeVisitServices.where((v) => v.active).length}',
          s.t('خدمة سحب منزلي', 'Home collection services'), onTap: () => go(context, const HomeServiceAdminScreen())),
        FeatureTile(Icons.inbox_outlined, '${s.homeVisitRequests.where((r) => !r.closed).length}',
          s.t('طلب يحتاج متابعة', 'Open requests'), onTap: () => go(context, const HomeRequestsAdminScreen())),
      ]),
      Section(s.t('إدارة المحتوى والخدمات', 'Manage content & services')),
      ActionRow(Icons.person_add_alt, s.t('الأطباء', 'Doctors'),
        subtitle: s.t('الصور، التخصص، العنوان، التواصل والموقع', 'Photos, specialties, addresses, social links and maps'),
        onTap: () => go(context, const DoctorAdminScreen())),
      ActionRow(Icons.add_home_work_outlined, s.t('خدمات السحب المنزلي', 'Home collection services'),
        subtitle: s.t('المختبر، مناطق التغطية، الأجور والأوقات', 'Laboratories, coverage areas, fees and times'),
        onTap: () => go(context, const HomeServiceAdminScreen())),
      ActionRow(Icons.route_outlined, s.t('طلبات السحب المنزلي', 'Home collection requests'),
        subtitle: s.t('التأكيد، تعيين الفني ومتابعة مراحل الطلب', 'Confirmation, collector assignment and request stages'),
        onTap: () => go(context, const HomeRequestsAdminScreen())),
      const SizedBox(height: 16), OutlinedButton.icon(onPressed: () => go(context, const AppShell()),
        icon: const Icon(Icons.phone_android), label: Text(s.t('معاينة التطبيق بنفس بيانات الجلسة', 'Preview the app with this session’s data'))),
    ]);
  }
}

class DoctorAdminScreen extends StatefulWidget {
  const DoctorAdminScreen({super.key});
  @override State<DoctorAdminScreen> createState() => _DoctorAdminScreenState();
}
class _DoctorAdminScreenState extends State<DoctorAdminScreen> {
  String query = '';
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.doctors.where((d) => '${d.name} ${d.nameEn} ${d.specialty} ${d.address}'.toLowerCase().contains(query.toLowerCase())).toList();
    return DetailPage(title: s.t('إدارة الأطباء', 'Manage doctors'), children: [
      Heading(s.t('كل تفاصيل الطبيب، بمكان واحد', 'Every doctor detail, in one place')),
      FilledButton.icon(key: const ValueKey('doctor-add'), onPressed: () => go(context, const DoctorEditorScreen()),
        icon: const Icon(Icons.add), label: Text(s.t('إضافة طبيب', 'Add doctor'))),
      const SizedBox(height: 16), TextField(onChanged: (v) => setState(() => query = v),
        decoration: InputDecoration(labelText: s.t('ابحث بالاسم أو التخصص أو العنوان', 'Search name, specialty or address'), prefixIcon: const Icon(Icons.search))),
      const SizedBox(height: 18),
      if (list.isEmpty) EmptyState(s.t('لا توجد ملفات مطابقة', 'No matching profiles'), s.t('غيّر البحث أو أضف طبيباً.', 'Change your search or add a doctor.')),
      ...list.map((d) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Panel(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [DoctorAvatar(d, size: 58), const SizedBox(width: 14), Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.title(s), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(d.specialty, style: TextStyle(color: muted(context))),
            ]))]),
          const SizedBox(height: 14), Text(d.address), const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Tag(d.active ? s.t('ظاهر', 'Visible') : s.t('مخفي', 'Hidden'), color: d.active ? accent : amber),
            if (d.location != null) Tag(s.t('موقع مضاف', 'Map added')),
          ]),
          const Divider(), Wrap(spacing: 10, runSpacing: 8, children: [
            OutlinedButton.icon(key: ValueKey('doctor-edit-${d.id}'), onPressed: () => go(context, DoctorEditorScreen(doctor: d)),
              icon: const Icon(Icons.edit_outlined), label: Text(s.t('تعديل', 'Edit'))),
            TextButton(onPressed: () => s.saveDoctor(d.withActive(!d.active)),
              child: Text(d.active ? s.t('إخفاء من التطبيق', 'Hide from app') : s.t('إظهار بالتطبيق', 'Show in app'))),
            if (d.active) TextButton(onPressed: () => go(context, DoctorDetailScreen(d.id)), child: Text(s.t('معاينة', 'Preview'))),
          ]),
        ])))),
      const CarePreviewNote(),
    ]);
  }
}

class DoctorEditorScreen extends StatefulWidget {
  const DoctorEditorScreen({super.key, this.doctor});
  final DoctorProfile? doctor;
  @override State<DoctorEditorScreen> createState() => _DoctorEditorScreenState();
}
class _DoctorEditorScreenState extends State<DoctorEditorScreen> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  Uint8List? photo;
  bool active = true, picking = false;
  @override void initState() {
    super.initState(); final d = widget.doctor;
    final initial = <String, String>{'name': d?.name ?? '', 'nameEn': d?.nameEn ?? '',
      'specialty': d?.specialty ?? '', 'clinic': d?.clinic ?? '', 'area': d?.area ?? '',
      'address': d?.address ?? '', 'phone': d?.phone ?? '', 'bio': d?.bio ?? '',
      'fee': '${d?.fee ?? 0}', 'lat': d?.location?.latitude.toString() ?? '',
      'lng': d?.location?.longitude.toString() ?? '',
      for (final key in socialLabels.keys) key: d?.socials[key] ?? ''};
    for (final e in initial.entries) { fields[e.key] = TextEditingController(text: e.value); }
    photo = d?.photo; active = d?.active ?? true;
  }
  @override void dispose() { for (final c in fields.values) { c.dispose(); } super.dispose(); }
  Future<void> pickPhoto() async {
    final s = AppScope.of(context); setState(() => picking = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery,
          maxWidth: 1200, maxHeight: 1200, imageQuality: 85, requestFullMetadata: false);
      if (file == null) return;
      if (await file.length() > 2 * 1024 * 1024) throw const FormatException('Photo too large');
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 512);
      try { final frame = await codec.getNextFrame(); frame.image.dispose(); } finally { codec.dispose(); }
      if (mounted) setState(() => photo = bytes);
    } catch (_) {
      if (mounted) toast(context, s.t('اختَر صورة صالحة بحجم لا يتجاوز 2 MB', 'Choose a valid image no larger than 2 MB'));
    } finally { if (mounted) setState(() => picking = false); }
  }
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget field(String key, String ar, String en, {bool required = false, int lines = 1, TextInputType? type}) =>
      Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(
        key: ValueKey('doctor-$key'), controller: fields[key], maxLines: lines, keyboardType: type,
        decoration: InputDecoration(labelText: s.t(ar, en)),
        validator: (v) {
          final text = (v ?? '').trim();
          if (required && text.isEmpty) return s.t('هذا الحقل مطلوب', 'Required field');
          if (key == 'address' && text.length < 8) return s.t('أدخل عنواناً واضحاً', 'Enter a complete address');
          if (key == 'fee' && (int.tryParse(careDigits(text)) == null || int.parse(careDigits(text)) < 0)) return s.t('أدخل مبلغاً صحيحاً', 'Enter a valid amount');
          if (key == 'phone' && text.isNotEmpty && !validIraqiPhone(careDigits(text))) return s.t('أدخل رقماً عراقياً صالحاً', 'Enter a valid Iraqi number');
          if (socialLabels.containsKey(key) && !validSocialLink(key, text)) return s.t('أدخل رابط HTTPS صحيحاً للمنصة', 'Enter a valid HTTPS URL for this platform');
          return null;
        }));
    return DetailPage(title: s.t(widget.doctor == null ? 'إضافة طبيب' : 'تعديل الطبيب',
      widget.doctor == null ? 'Add doctor' : 'Edit doctor'), children: [
      const CarePreviewNote(),
      Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Panel(child: Column(children: [
          DoctorAvatar(DoctorProfile(id: 'preview', name: '', specialty: '', address: '', area: '', photo: photo), size: 110),
          const SizedBox(height: 16), OutlinedButton.icon(onPressed: picking ? null : pickPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined), label: Text(s.t('اختيار صورة الطبيب', 'Choose doctor photo'))),
          if (photo != null) TextButton(onPressed: () => setState(() => photo = null), child: Text(s.t('إزالة الصورة', 'Remove photo'))),
          Text(s.t('صورة واضحة، حتى 2 MB', 'Clear portrait, up to 2 MB'), style: TextStyle(color: muted(context), fontSize: 12)),
        ])),
        Section(s.t('المعلومات الأساسية', 'Profile details')),
        field('name', 'اسم الطبيب *', 'Doctor name *', required: true),
        field('nameEn', 'الاسم بالإنكليزي — اختياري', 'English name — optional'),
        field('specialty', 'التخصص *', 'Specialty *', required: true),
        field('clinic', 'اسم العيادة', 'Clinic name'),
        field('fee', 'أجر الزيارة — د.ع', 'Visit fee — IQD', type: TextInputType.number),
        field('phone', 'رقم هاتف العيادة', 'Clinic phone', type: TextInputType.phone),
        field('bio', 'نبذة عن الطبيب', 'About the doctor', lines: 3),
        Section(s.t('عنوان العيادة', 'Clinic location')),
        field('area', 'المدينة والمنطقة *', 'City and area *', required: true),
        field('address', 'العنوان الكامل *', 'Full address *', required: true, lines: 2),
        LocationFields(latitude: fields['lat']!, longitude: fields['lng']!, prefix: 'doctor'),
        Section(s.t('روابط التواصل', 'Social links')),
        for (final e in socialLabels.entries) field(e.key, '${e.value} — رابط اختياري', '${e.value} — optional URL', type: TextInputType.url),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (v) => setState(() => active = v),
          title: Text(s.t('إظهار الطبيب بالتطبيق', 'Show doctor in app'))),
        const SizedBox(height: 20),
        FilledButton.icon(key: const ValueKey('doctor-save'), onPressed: picking ? null : () {
          if (!form.currentState!.validate()) return;
          final d = DoctorProfile(id: widget.doctor?.id ?? 'doctor-${DateTime.now().microsecondsSinceEpoch}',
            name: fields['name']!.text.trim(), nameEn: fields['nameEn']!.text.trim(),
            specialty: fields['specialty']!.text.trim(), clinic: fields['clinic']!.text.trim(),
            area: fields['area']!.text.trim(), address: fields['address']!.text.trim(),
            phone: careDigits(fields['phone']!.text), bio: fields['bio']!.text.trim(),
            fee: int.parse(careDigits(fields['fee']!.text)), photo: photo, active: active,
            location: GeoPoint.parse(fields['lat']!.text, fields['lng']!.text),
            socials: {for (final key in socialLabels.keys) key: fields[key]!.text.trim()});
          s.saveDoctor(d); Navigator.pop(context);
          toast(context, s.t('تم حفظ الطبيب في جلسة المعاينة', 'Doctor saved in this preview session'));
        }, icon: const Icon(Icons.check), label: Text(s.t('حفظ الطبيب', 'Save doctor'))),
      ])),
    ]);
  }
}
