part of '../main.dart';

class HomeServiceCatalog extends StatelessWidget {
  const HomeServiceCatalog({super.key, this.initialTests = ''});
  final String initialTests;
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final available = s.homeVisitServices.where((v) => v.active).toList();
    return DetailPage(title: s.t('خدمات السحب المنزلي', 'Home collection services'), children: [
      Heading(s.t('العناية توصل لبابك', 'Care, at your doorstep'),
        subtitle: s.t('اختَر المختبر، راجع منطقة التغطية واطلب الزيارة.', 'Choose a lab, check coverage and request a visit.')),
      const CarePreviewNote(),
      if (available.isEmpty) EmptyState(s.t('لا توجد خدمات متاحة حالياً', 'No services available'),
        s.t('تظهر الخدمات هنا بعد تفعيلها من الإدارة.', 'Services appear here once enabled by the administrator.')),
      ...available.map((v) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Panel(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [const Glyph(Icons.home_outlined, size: 60), const SizedBox(width: 14),
            Expanded(child: Text(v.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))]),
          const SizedBox(height: 14), Text(v.lab.title(s), style: TextStyle(color: muted(context))),
          const SizedBox(height: 14), Wrap(spacing: 8, runSpacing: 8, children: v.areas.map(Tag.new).toList()),
          const Divider(), Text('${s.t('أجر السحب والزيارة', 'Collection & visit fee')}: ${s.money(v.fee)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 6), Text(s.t('أجور التحاليل تُؤكد بصورة منفصلة من المختبر.',
            'Test prices are confirmed separately by the laboratory.'), style: TextStyle(color: muted(context), fontSize: 12)),
          if (v.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(v.notes)),
          const SizedBox(height: 18), FilledButton.icon(key: ValueKey('request-home-${v.id}'),
            onPressed: () => go(context, HomeVisitRequestScreen(serviceId: v.id, initialTests: initialTests)), icon: const Icon(Icons.add),
            label: Text(s.t('طلب سحب منزلي', 'Request home collection'))),
        ])))),
      ActionRow(Icons.receipt_long_outlined, s.t('طلبات السحب الخاصة بي', 'My home collection requests'),
        onTap: () => go(context, const MyHomeRequestsScreen())),
    ]);
  }
}

class HomeVisitRequestScreen extends StatefulWidget {
  const HomeVisitRequestScreen({super.key, required this.serviceId, this.initialTests = ''});
  final String serviceId, initialTests;
  @override State<HomeVisitRequestScreen> createState() => _HomeVisitRequestScreenState();
}
class _HomeVisitRequestScreenState extends State<HomeVisitRequestScreen> {
  final form = GlobalKey<FormState>();
  final fields = {for (final key in ['phone', 'address', 'landmark', 'tests', 'notes', 'lat', 'lng']) key: TextEditingController()};
  String? person, area;
  int? hour;
  int? quotedFee;
  DateTime date = DateTime.now().add(const Duration(days: 1));
  bool consent = false, submitted = false;
  @override void initState() { super.initState(); fields['tests']!.text = widget.initialTests; }
  @override void dispose() { for (final c in fields.values) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final service = s.homeVisitServices.where((v) => v.id == widget.serviceId && v.active).firstOrNull;
    if (service == null) return DetailPage(title: s.t('طلب سحب منزلي', 'Home collection request'), children: [
      EmptyState(s.t('الخدمة غير متاحة حالياً', 'Service currently unavailable'), s.t('اختر خدمة أخرى.', 'Please choose another service.')),
    ]);
    person ??= s.patientId; area ??= service.areas.first; hour ??= service.hours.first; quotedFee ??= service.fee;
    Widget field(String key, String ar, String en, {int lines = 1, bool required = false}) =>
      Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(
        key: ValueKey('home-$key'), controller: fields[key], maxLines: lines,
        keyboardType: key == 'phone' ? TextInputType.phone : lines > 1 ? TextInputType.multiline : TextInputType.text,
        decoration: InputDecoration(labelText: s.t(ar, en)), validator: (v) {
          final value = (v ?? '').trim();
          if (required && value.isEmpty) return s.t('هذا الحقل مطلوب', 'Required field');
          if (key == 'phone' && !validIraqiPhone(careDigits(value))) return s.t('أدخل رقماً عراقياً صالحاً', 'Enter a valid Iraqi number');
          if (key == 'address' && value.length < 8) return s.t('أدخل عنواناً واضحاً', 'Enter a complete address');
          if (key == 'tests' && value.length < 3) return s.t('اكتب التحاليل المطلوبة', 'Describe the requested tests');
          return null;
        }));
    return DetailPage(title: s.t('طلب سحب منزلي', 'Request home collection'), children: [
      Heading(service.name, subtitle: service.lab.title(s)), const CarePreviewNote(),
      Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Section(s.t('المريض ومعلومات التواصل', 'Patient & contact')),
        DropdownButtonFormField<String>(value: person, isExpanded: true,
          decoration: InputDecoration(labelText: s.t('الخدمة لمن؟', 'Who is this for?')),
          items: s.patients.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
          onChanged: (v) => setState(() => person = v)), const SizedBox(height: 14),
        field('phone', 'رقم الهاتف *', 'Phone number *', required: true),
        field('tests', 'التحاليل المطلوبة أو اسم الباقة *', 'Requested tests or package *', required: true, lines: 3),
        Section(s.t('عنوان الزيارة', 'Visit address')),
        DropdownButtonFormField<String>(value: service.areas.contains(area) ? area : null, isExpanded: true,
          decoration: InputDecoration(labelText: s.t('منطقة ضمن التغطية *', 'Coverage area *')),
          items: service.areas.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          validator: (v) => v == null ? s.t('اختَر المنطقة', 'Choose an area') : null,
          onChanged: (v) => setState(() => area = v)), const SizedBox(height: 14),
        field('address', 'الشارع ورقم الدار أو الشقة *', 'Street, house or apartment *', required: true, lines: 2),
        field('landmark', 'أقرب نقطة دالة — اختياري', 'Nearest landmark — optional'),
        LocationFields(latitude: fields['lat']!, longitude: fields['lng']!, prefix: 'home'),
        Section(s.t('موعد الزيارة المطلوب', 'Requested visit time')),
        ActionRow(Icons.calendar_month_outlined, s.t('اليوم', 'Day'), subtitle: '${date.day}/${date.month}/${date.year}', onTap: () async {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day + 1);
          final end = DateTime(now.year, now.month, now.day + 30);
          final chosen = await showDatePicker(context: context, initialDate: date.isBefore(start) ? start : date,
            firstDate: start, lastDate: end);
          if (chosen != null && mounted) setState(() => date = chosen);
        }),
        Wrap(spacing: 8, runSpacing: 8, children: service.hours.map((h) => ChoiceChip(
          label: Text('${h.toString().padLeft(2, '0')}:00'), selected: hour == h,
          onSelected: (_) => setState(() => hour = h))).toList()),
        const SizedBox(height: 18), field('notes', 'ملاحظات للفني — اختياري', 'Notes for the collector — optional', lines: 2),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${s.t('أجر السحب والزيارة', 'Collection & visit fee')}: ${s.money(service.fee)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8), Text(s.t('هذا أجر الزيارة فقط. سعر التحاليل وموعد الزيارة يحتاجان تأكيد المختبر.',
            'This is the visit fee only. Test prices and visit availability require lab confirmation.')),
          if (service.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(service.notes)),
        ])),
        CheckboxListTile(key: const ValueKey('home-consent'), contentPadding: EdgeInsets.zero,
          value: consent, onChanged: (v) => setState(() => consent = v ?? false),
          title: Text(s.t('أوافق على إنشاء طلب تجريبي. لن يتم إرسال فني أو خصم مبلغ.',
            'I agree to create a demo request. No collector is dispatched and no payment is taken.'))),
        const SizedBox(height: 12), FilledButton.icon(key: const ValueKey('home-submit'),
          onPressed: submitted ? null : () {
            if (!form.currentState!.validate()) return;
            if (!consent) { toast(context, s.t('أكّد الموافقة أولاً', 'Please acknowledge the demo first')); return; }
            if (quotedFee != service.fee) {
              setState(() { quotedFee = service.fee; consent = false; });
              toast(context, s.t('تغيّرت أجور الزيارة، راجع السعر وأكّد مجدداً', 'The visit fee changed. Review it and confirm again.')); return;
            }
            try {
              final request = s.submitHomeVisit(serviceId: service.id, forPatient: person!,
                phone: fields['phone']!.text, address: fields['address']!.text, area: area!,
                tests: fields['tests']!.text, landmark: fields['landmark']!.text, notes: fields['notes']!.text,
                scheduledAt: DateTime(date.year, date.month, date.day, hour!),
                location: GeoPoint.parse(fields['lat']!.text, fields['lng']!.text));
              setState(() => submitted = true);
              Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => HomeVisitDetailScreen(request.id)));
            } on FormatException {
              toast(context, s.t('راجع الموعد والمنطقة والبيانات؛ قد يكون توفر الخدمة تغيّر.',
                'Check the time, area and details; service availability may have changed.'));
            }
          }, icon: const Icon(Icons.check_circle_outline), label: Text(s.t('تأكيد الطلب التجريبي', 'Confirm demo request'))),
      ])),
    ]);
  }
}

class HomeVisitRequestCard extends StatelessWidget {
  const HomeVisitRequestCard(this.request, {super.key, this.admin = false});
  final HomeVisitRequest request;
  final bool admin;
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context), r = request;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Panel(
      onTap: () => go(context, HomeVisitDetailScreen(r.id, admin: admin)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [Tag(r.id), Tag(visitStatusLabel(s, r.status),
          color: r.status == HomeVisitStatus.pending || r.status == HomeVisitStatus.cancelled ? amber : accent)]),
        const SizedBox(height: 14), Text(r.service.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8), Text('${r.patientName} • ${r.area}'),
        const SizedBox(height: 8), Text(dateLabel(r.scheduledAt), textDirection: TextDirection.ltr),
        const SizedBox(height: 8), Text('${s.t('أجر الزيارة', 'Visit fee')}: ${s.money(r.service.fee)}'),
      ])));
  }
}
class MyHomeRequestsScreen extends StatelessWidget {
  const MyHomeRequestsScreen({super.key});
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context), requests = s.homeVisitRequests.where((r) => r.patientId == s.patientId).toList();
    return DetailPage(title: s.t('طلباتي المنزلية', 'My home requests'), children: [
      const PatientPicker(), const SizedBox(height: 20),
      if (requests.isEmpty) EmptyState(s.t('لا توجد طلبات لهذا الملف', 'No requests for this profile'),
        s.t('ابدأ باختيار خدمة سحب منزلي.', 'Start by choosing a home collection service.')),
      ...requests.map(HomeVisitRequestCard.new),
      FilledButton(onPressed: () => go(context, const HomeServiceCatalog()), child: Text(s.t('طلب سحب منزلي جديد', 'New home collection request'))),
    ]);
  }
}
class HomeVisitDetailScreen extends StatelessWidget {
  const HomeVisitDetailScreen(this.id, {super.key, this.admin = false});
  final String id;
  final bool admin;
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.homeVisitRequests.where((r) => r.id == id && (admin || r.patientId == s.patientId)).firstOrNull;
    if (r == null) return DetailPage(title: s.t('تفاصيل الطلب', 'Request details'), children: [
      EmptyState(s.t('الطلب غير متاح لهذا الملف', 'Request unavailable for this profile'), s.t('ارجع إلى طلباتك.', 'Return to your requests.')),
    ]);
    return DetailPage(title: s.t('تفاصيل طلب السحب', 'Collection request details'), children: [
      Heading(r.id, subtitle: r.service.name),
      Wrap(spacing: 8, runSpacing: 8, children: [Tag(visitStatusLabel(s, r.status)), Tag(s.t('طلب تجريبي', 'DEMO REQUEST'))]),
      const SizedBox(height: 18), Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(r.patientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 12), SelectableText(r.phone, textDirection: TextDirection.ltr),
        const SizedBox(height: 8), Text(dateLabel(r.scheduledAt)), const Divider(),
        Text('${r.area} • ${r.address}'),
        if (r.landmark.isNotEmpty) Text('${s.t('نقطة دالة', 'Landmark')}: ${r.landmark}'),
        if (r.location != null) TextButton.icon(onPressed: () => openCareLink(context, r.location!.mapUrl),
          icon: const Icon(Icons.map_outlined), label: Text(s.t('فتح موقع الزيارة', 'Open visit location'))),
        const Divider(), Text('${s.t('التحاليل المطلوبة', 'Requested tests')}: ${r.tests}'),
        if (r.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(r.notes)),
        const Divider(), Text('${s.t('أجر الزيارة فقط', 'Visit fee only')}: ${s.money(r.service.fee)}',
          style: const TextStyle(fontWeight: FontWeight.w800)),
        if (r.collector.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12),
          child: Text('${s.t('الفني المعيّن', 'Assigned collector')}: ${r.collector}')),
      ])),
      Section(s.t('متابعة الطلب', 'Request progress')),
      ...r.history.map((e) => ActionRow(Icons.check_circle_outline, visitStatusLabel(s, e.status),
        subtitle: dateLabel(e.at), trailing: const SizedBox.shrink())),
      if (admin && !r.closed) FilledButton.icon(key: const ValueKey('home-advance'), onPressed: () async {
        String? collector;
        if (r.status == HomeVisitStatus.confirmed) {
          collector = await prompt(context, s.t('اسم الفني التجريبي', 'Demo collector name'));
          if (collector == null || !context.mounted) return;
        }
        if (!s.advanceHomeVisit(r, collector: collector) && context.mounted) {
          toast(context, s.t('تحقق من اسم الفني وحالة الطلب', 'Check the collector name and request status'));
        }
      }, icon: const Icon(Icons.arrow_forward), label: Text(r.status == HomeVisitStatus.pending
        ? s.t('تأكيد الطلب', 'Confirm request') : r.status == HomeVisitStatus.confirmed
        ? s.t('تعيين فني', 'Assign collector') : visitStatusLabel(s, HomeVisitStatus.values[r.status.index + 1]))),
      if ((admin && !r.closed && r.status.index < HomeVisitStatus.collected.index) || (!admin && r.patientCanCancel))
        Padding(padding: const EdgeInsets.only(top: 10), child: OutlinedButton(key: const ValueKey('home-cancel'), onPressed: () async {
          if (await confirm(context, s.t('إلغاء طلب السحب؟', 'Cancel home collection?'),
            s.t('يُنقل الطلب إلى الملغاة داخل هذه الجلسة.', 'The request will move to cancelled in this session.'))) {
            s.cancelHomeVisit(r, byAdmin: admin);
          }
        }, child: Text(s.t('إلغاء الطلب', 'Cancel request')))),
      const CarePreviewNote(),
    ]);
  }
}

class HomeServiceAdminScreen extends StatelessWidget {
  const HomeServiceAdminScreen({super.key});
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return DetailPage(title: s.t('إدارة خدمات السحب المنزلي', 'Manage home collection services'), children: [
      FilledButton.icon(key: const ValueKey('home-service-add'), onPressed: () => go(context, const HomeServiceEditorScreen()),
        icon: const Icon(Icons.add), label: Text(s.t('إضافة خدمة سحب منزلي', 'Add home collection service'))),
      const SizedBox(height: 18),
      ...s.homeVisitServices.map((v) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Panel(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10), Text('${v.lab.title(s)} • ${s.money(v.fee)}'),
          const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: v.areas.map(Tag.new).toList()),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: v.active, onChanged: (active) => s.saveHomeService(v.withActive(active)),
            title: Text(s.t('متاحة بالتطبيق', 'Available in app'))),
          OutlinedButton.icon(onPressed: () => go(context, HomeServiceEditorScreen(service: v)),
            icon: const Icon(Icons.edit_outlined), label: Text(s.t('تعديل الخدمة', 'Edit service'))),
        ])))), const CarePreviewNote(),
    ]);
  }
}
class HomeServiceEditorScreen extends StatefulWidget {
  const HomeServiceEditorScreen({super.key, this.service});
  final HomeVisitService? service;
  @override State<HomeServiceEditorScreen> createState() => _HomeServiceEditorScreenState();
}
class _HomeServiceEditorScreenState extends State<HomeServiceEditorScreen> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  late String labId;
  late Set<int> hours;
  bool active = true;
  @override void initState() {
    super.initState(); final v = widget.service;
    for (final e in {'name': v?.name ?? '', 'areas': v?.areas.join('، ') ?? '',
      'fee': '${v?.fee ?? 10000}', 'notes': v?.notes ?? ''}.entries) {
      fields[e.key] = TextEditingController(text: e.value);
    }
    labId = v?.labId ?? 'lab1'; hours = (v?.hours ?? [9, 10, 11, 13, 15, 17]).toSet(); active = v?.active ?? true;
  }
  @override void dispose() { for (final c in fields.values) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return DetailPage(title: s.t('تفاصيل خدمة السحب', 'Home collection service details'), children: [
      Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final e in [('name', 'اسم الخدمة *', 'Service name *'), ('fee', 'أجر الزيارة — د.ع *', 'Visit fee — IQD *'),
          ('areas', 'مناطق التغطية، مفصولة بفاصلة *', 'Coverage areas, separated by commas *'),
          ('notes', 'ملاحظات وتعليمات الخدمة', 'Service notes')])
          Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(
            key: ValueKey('service-${e.$1}'), controller: fields[e.$1],
            maxLines: e.$1 == 'notes' || e.$1 == 'areas' ? 3 : 1,
            keyboardType: e.$1 == 'fee' ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(labelText: s.t(e.$2, e.$3)), validator: (value) {
              final text = (value ?? '').trim();
              if (e.$1 != 'notes' && text.isEmpty) return s.t('هذا الحقل مطلوب', 'Required field');
              if (e.$1 == 'fee' && (int.tryParse(careDigits(text)) == null || int.parse(careDigits(text)) < 0)) return s.t('أدخل مبلغاً صحيحاً', 'Enter a valid amount');
              if (e.$1 == 'areas' && text.split(RegExp('[,،\n]')).every((v) => v.trim().isEmpty)) return s.t('أضف منطقة واحدة على الأقل', 'Add at least one area');
              return null;
            })),
        DropdownButtonFormField<String>(value: labId, isExpanded: true,
          decoration: InputDecoration(labelText: s.t('المختبر مقدم الخدمة', 'Providing laboratory')),
          items: services.where((v) => v.kind == 'labs').map((v) => DropdownMenuItem(value: v.id, child: Text(v.title(s)))).toList(),
          onChanged: (v) => setState(() => labId = v!)),
        Section(s.t('الأوقات الممكن طلبها', 'Requestable visit times')),
        Wrap(spacing: 8, runSpacing: 8, children: List.generate(15, (i) => i + 7).map((h) => FilterChip(
          label: Text('${h.toString().padLeft(2, '0')}:00'), selected: hours.contains(h),
          onSelected: (selected) => setState(() { selected ? hours.add(h) : hours.remove(h); }))).toList()),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: active, onChanged: (v) => setState(() => active = v),
          title: Text(s.t('تفعيل الخدمة بالتطبيق', 'Enable service in app'))),
        const SizedBox(height: 18), FilledButton.icon(key: const ValueKey('home-service-save'), onPressed: () {
          if (!form.currentState!.validate()) return;
          if (hours.isEmpty) { toast(context, s.t('اختَر وقتاً واحداً على الأقل', 'Select at least one time')); return; }
          s.saveHomeService(HomeVisitService(id: widget.service?.id ?? 'home-${DateTime.now().microsecondsSinceEpoch}',
            name: fields['name']!.text.trim(), fee: int.parse(careDigits(fields['fee']!.text)),
            areas: fields['areas']!.text.split(RegExp('[,،\n]')).map((v) => v.trim()).where((v) => v.isNotEmpty).toSet().toList(),
            labId: labId, notes: fields['notes']!.text.trim(), active: active, hours: hours.toList()..sort()));
          Navigator.pop(context); toast(context, s.t('تم حفظ الخدمة في الجلسة', 'Service saved in this session'));
        }, icon: const Icon(Icons.check), label: Text(s.t('حفظ الخدمة', 'Save service'))),
      ])), const CarePreviewNote(),
    ]);
  }
}

class HomeRequestsAdminScreen extends StatefulWidget {
  const HomeRequestsAdminScreen({super.key});
  @override State<HomeRequestsAdminScreen> createState() => _HomeRequestsAdminScreenState();
}
class _HomeRequestsAdminScreenState extends State<HomeRequestsAdminScreen> {
  HomeVisitStatus? filter;
  String query = '';
  @override Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final requests = s.homeVisitRequests.where((r) => (filter == null || r.status == filter) &&
      '${r.id} ${r.patientName} ${r.phone} ${r.area}'.toLowerCase().contains(query.toLowerCase())).toList();
    return DetailPage(title: s.t('إدارة طلبات السحب', 'Manage collection requests'), children: [
      Heading(s.t('طلبات الزيارات المنزلية', 'Home visit requests'),
        subtitle: s.t('تابع كل طلب من الاستلام إلى اكتمال الزيارة.', 'Follow each request from receipt to visit completion.')),
      TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search), labelText: s.t('رقم الطلب، اسم المريض أو الهاتف', 'Request ID, patient name or phone'))),
      const SizedBox(height: 14), DropdownButtonFormField<HomeVisitStatus>(value: filter, isExpanded: true,
        decoration: InputDecoration(labelText: s.t('الحالة', 'Status')),
        items: [DropdownMenuItem<HomeVisitStatus>(value: null, child: Text(s.t('جميع الحالات', 'All statuses'))),
          ...HomeVisitStatus.values.map((v) => DropdownMenuItem(value: v, child: Text(visitStatusLabel(s, v))))],
        onChanged: (v) => setState(() => filter = v)),
      const SizedBox(height: 18),
      if (requests.isEmpty) EmptyState(s.t('لا توجد طلبات مطابقة', 'No matching requests'),
        s.t('أنشئ طلباً من معاينة المريض ضمن الجلسة نفسها.', 'Create a request in the patient preview within this session.')),
      ...requests.map((r) => HomeVisitRequestCard(r, admin: true)),
      const CarePreviewNote(),
    ]);
  }
}
