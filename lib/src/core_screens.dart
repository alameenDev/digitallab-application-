part of '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key,required this.onTab});
  final ValueChanged<int> onTab;
  @override Widget build(BuildContext context) => ExperienceHome(onTab:onTab);
}
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key,this.initialKind='packages',this.standalone=false,this.collection});
  final String initialKind;
  final bool standalone;
  final String? collection;
  @override State<ExploreScreen> createState()=>_ExploreScreenState();
}
class _ExploreScreenState extends State<ExploreScreen> {
  late String kind=widget.initialKind;
  String query='';
  String area='all';
  @override
  Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final source=services.where((v)=>
      (widget.collection=='favorites' ? s.favorites.contains(v.id) :
       widget.collection=='recent' ? s.recent.contains(v.id) :
       v.kind==(kind=='home'?'packages':kind)) &&
      '${v.ar} ${v.en} ${v.subAr} ${v.subEn}'.toLowerCase().contains(query.toLowerCase()) &&
      (area=='all' || (area=='mansour' ? v.subEn.contains('Mansour') : v.subEn.contains('Karrada')))).toList();
    final title=widget.collection=='favorites'?s.t('المفضلة','Favorites'):
      widget.collection=='recent'?s.t('شاهدتها مؤخراً','Recently viewed'):s.t('اكتشف رعايتك','Discover your care');
    final children=<Widget>[
      Heading(title,subtitle:s.t('خيارات واضحة. القرار إلك.','Clear choices. Care on your terms.')),
      TextField(onChanged:(v)=>setState(()=>query=v),
        decoration:InputDecoration(hintText:s.t('ابحث عن باقة، طبيب أو مختبر','Search packages, doctors or labs'),
          prefixIcon:const Icon(Icons.search))),
      const SizedBox(height:16),
      if(widget.collection==null) SingleChildScrollView(scrollDirection:Axis.horizontal,
        child:Row(children:[
          for(final item in [
            ('packages',s.t('الفحوصات','Packages')),('doctors',s.t('الأطباء','Doctors')),
            ('labs',s.t('المختبرات','Labs')),('home',s.t('سحب منزلي','At home')),
          ]) Padding(padding:const EdgeInsetsDirectional.only(end:8),child:ChoiceChip(
            label:Text(item.$2),selected:kind==item.$1,onSelected:(_)=>setState((){kind=item.$1;area='all';}))),
        ])),
      if(kind=='labs'||kind=='doctors') Padding(padding:const EdgeInsets.only(top:12),
        child:DropdownButtonFormField<String>(value:area,decoration:InputDecoration(labelText:s.t('المنطقة','Area')),
          items:[DropdownMenuItem(value:'all',child:Text(s.t('كل المناطق','All areas'))),
            DropdownMenuItem(value:'mansour',child:Text(s.t('المنصور','Mansour'))),
            DropdownMenuItem(value:'karrada',child:Text(s.t('الكرادة','Karrada')))],
          onChanged:(v)=>setState(()=>area=v!))),
      if(kind=='home') Note(s.t('اختر الباقة، ثم اختر السحب المنزلي في خطوات الحجز.',
        'Choose a package, then select home collection during booking.')),
      const SizedBox(height:20),
      if(kind=='packages'||kind=='home') ActionRow(Icons.compare_arrows,s.t('قارن الباقات جنباً إلى جنب','Compare packages side by side'),
        subtitle:s.t('الأسعار، عدد الفحوصات والمختبر','Prices, test counts and laboratories'),
        onTap:()=>go(context,const PackageComparisonScreen())),
      if(source.isEmpty) EmptyState(s.t('لا توجد نتائج','No matches'),
        s.t('جرّب كلمة أخرى أو غيّر الفلاتر.','Try another keyword or change the filters.'),icon:Icons.search_off)
      else TileGrid(minWidth:260,children:source.map(ServiceCard.new).toList()),
      Note(s.t('جميع مقدمي الخدمة والأسعار ملفات تجريبية لعرض التصميم.',
        'All providers and prices are fictional profiles for design review.')),
    ];
    return widget.standalone?DetailPage(title:title,children:children):ScreenBody(children:children);
  }
}
class ServiceScreen extends StatelessWidget {
  const ServiceScreen(this.service,{super.key});
  final Service service;
  @override
  Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final doctor=service.kind=='doctors',lab=service.kind=='labs';
    return DetailPage(title:s.t('تفاصيل الخدمة','Service details'),actions:[
      IconButton(tooltip:s.t('المفضلة','Favorite'),onPressed:()=>s.favorite(service.id),
        icon:Icon(s.favorites.contains(service.id)?Icons.favorite:Icons.favorite_border)),
    ],children:[
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Glyph(service.icon,size:76),const Spacer(),Tag(s.t('ملف تجريبي','DEMO PROFILE'))]),
        const SizedBox(height:24),Heading(service.title(s),subtitle:service.subtitle(s)),
        Text(s.t(service.detailsAr,service.detailsEn),style:TextStyle(color:muted(context),height:1.9)),
        const Divider(),
        Row(children:[Expanded(child:Text(lab?s.t('زيارة المختبر','Lab visit'):s.t('سعر الخدمة','Service price'))),
          Text(service.price==0?s.t('بدون دفع في النموذج','No payment in demo'):s.money(service.price),
            style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))]),
      ])),
      Section(s.t('ماذا تتوقع؟','What to expect')),
      TileGrid(children:[
        FeatureTile(doctor?Icons.videocam_outlined:Icons.schedule,
          doctor?s.t('مرونة الاستشارة','Flexible visits'):s.t('موعد يناسبك','Your schedule'),
          doctor?s.t('حضوري، صوت، فيديو، محادثة','Clinic, voice, video or chat'):s.t('اختيار اليوم والوقت','Choose a day and time'),
          onTap:()=>go(context,BookingScreen(service))),
        FeatureTile(Icons.lock_outline,s.t('موافقتك أولاً','Your permission first'),
          s.t('تحكم بمشاركة بياناتك','Control your data sharing'),
          onTap:()=>go(context,const SharingScreen())),
      ]),
      if(lab) ...[
        Section(s.t('الباقات المتوفرة','Available packages')),
        ...services.where((v)=>v.kind=='packages' && (service.id=='lab1'?v.id!='liver':v.id=='liver')).map(ServiceCard.new),
        ActionRow(Icons.location_on_outlined,s.t('معلومات الفرع','Branch information'),
          subtitle:service.subtitle(s),onTap:()=>go(context,const LocationsScreen())),
      ],
      Section(s.t('التقييمات','Reviews')),
      EmptyState(s.t('لا توجد تقييمات موثقة بعد','No verified reviews yet'),
        s.t('تظهر التقييمات بعد اكتمال الزيارات عند ربط النظام.','Reviews will appear after completed visits when connected.'),
        icon:Icons.star_outline),
      const SizedBox(height:22),
      FilledButton.icon(onPressed:()=>go(context,BookingScreen(service)),
        icon:const Icon(Icons.calendar_month_outlined),label:Text(s.t('اختيار الموعد','Choose an appointment'))),
      if(!doctor&&!lab) Padding(padding:const EdgeInsets.only(top:10),child:OutlinedButton.icon(
        onPressed:()=>go(context,BookingScreen(service,home:true)),icon:const Icon(Icons.home_outlined),
        label:Text(s.t('أفضّل السحب المنزلي','I prefer home collection')))),
    ]);
  }
}
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override State<ResultsScreen> createState()=>_ResultsScreenState();
}
class _ResultsScreenState extends State<ResultsScreen> {
  String filter='all';
  @override
  Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final list=s.patientReports.where((r)=>filter=='all'||(filter=='ready'?r.ready:!r.ready)).toList();
    return ScreenBody(children:[
      Heading(s.t('الصورة الأوضح لصحتك','Your health, in focus'),
        subtitle:s.t('تقاريرك وتاريخك الصحي، بمكان واحد.','Your reports and history, thoughtfully together.')),
      const PatientPicker(),const SizedBox(height:18),
      Wrap(spacing:8,runSpacing:8,children:[
        for(final item in [('all',s.t('الكل','All')),('ready',s.t('جاهزة','Ready')),('pending',s.t('قيد الإجراء','In progress'))])
          ChoiceChip(label:Text(item.$2),selected:filter==item.$1,onSelected:(_)=>setState(()=>filter=item.$1)),
      ]),
      const SizedBox(height:20),
      if(list.isEmpty) EmptyState(s.t('لا توجد تقارير هنا','No reports here'),
        s.t('ستظهر نتائج هذا الملف عند توفرها.','Reports for this profile will appear when available.'))
      else ...list.map((r)=>Padding(padding:const EdgeInsets.only(bottom:14),
        child:Panel(onTap:()=>go(context,ReportScreen(r)),child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Glyph(r.ready?Icons.description_outlined:Icons.hourglass_top),
              const Spacer(),Tag(r.ready?s.t('جاهزة','Ready'):s.t('قيد الإجراء','Processing'),
                color:r.ready?accent:amber)]),
            const SizedBox(height:17),Text(s.t(r.ar,r.en),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
            const SizedBox(height:7),Text('${r.id} • ${r.date}',style:TextStyle(color:muted(context),fontSize:12)),
            const Divider(),Row(children:[Expanded(child:Text(r.ready?s.t('عرض التقرير','Open report'):
              s.t('متابعة الحالة','Track status'),style:const TextStyle(color:accent,fontWeight:FontWeight.w700))),
              const Icon(Icons.arrow_outward,size:18,color:accent)]),
          ])))),
      ActionRow(Icons.timeline,s.t('الخط الزمني الصحي','Health timeline'),
        subtitle:s.t('النتائج والزيارات السابقة','Reports and visits over time'),
        onTap:()=>go(context,const TimelineScreen())),
    ]);
  }
}
class ReportScreen extends StatelessWidget {
  const ReportScreen(this.report,{super.key});
  final Report report;
  @override
  Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final patient=s.patients.firstWhere((p)=>p.id==report.patientId);
    return DetailPage(title:s.t('تفاصيل النتيجة','Report details'),children:[
      Heading(s.t(report.ar,report.en),subtitle:'${patient.name} • ${report.id} • ${report.date}'),
      if(!report.ready) ...[
        Panel(child:Column(children:[
          const Glyph(Icons.hourglass_top,size:80),const SizedBox(height:20),
          Text(s.t('نعمل على تجهيز النتيجة','Your report is being prepared'),
            style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
          const SizedBox(height:12),Text(s.t('لا توجد قيم متاحة لهذا التقرير بعد.','There are no values available for this report yet.')),
        ])),
        const SizedBox(height:20),
        ...[s.t('استلام العينة','Sample received'),s.t('قيد التحليل','Processing'),s.t('مراجعة المختبر','Lab review'),
          s.t('جاهزة للاطلاع','Ready to view')].asMap().entries.map((e)=>ActionRow(
            e.key<1?Icons.check_circle_outline:e.key==1?Icons.hourglass_top:Icons.radio_button_unchecked,
            e.value,trailing:Tag(e.key==1?s.t('الحالية','Current'):e.key<1?s.t('مكتمل','Done'):s.t('لاحقاً','Next'),
              color:e.key==1?amber:accent))),
      ] else ...[
        Panel(child:Row(children:[const Glyph(Icons.fact_check_outlined),const SizedBox(width:14),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(s.t('4 مؤشرات في التقرير التجريبي','4 markers in this demo report'),
              style:const TextStyle(fontWeight:FontWeight.w800)),
            const SizedBox(height:6),Text(s.t('القيم والمديات للتصميم فقط، وليست تقييماً صحياً.',
              'Values and ranges illustrate the design, not a health assessment.'),
              style:TextStyle(color:muted(context),fontSize:12,height:1.6)),
          ]))])),
        Section(s.t('تفاصيل المؤشرات','Marker details')),
        ...markers.map((m)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Panel(
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Expanded(child:Text(m.name,style:const TextStyle(fontWeight:FontWeight.w800))),
              Text('${m.value} ${m.unit}',textDirection:TextDirection.ltr,
                style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18))]),
            const SizedBox(height:16),
            ClipRRect(borderRadius:BorderRadius.circular(6),child:LinearProgressIndicator(
              value:((m.value-m.low)/(m.high-m.low)).clamp(0.0,1.0),minHeight:7,
              color:accent,backgroundColor:accent.withAlpha(18))),
            const SizedBox(height:10),Text(s.t('المدى التوضيحي: ${m.low}–${m.high} • السابق: ${m.previous}',
              'Illustrative range: ${m.low}–${m.high} • Previous: ${m.previous}'),
              style:TextStyle(color:muted(context),fontSize:12)),
          ])))),
        const SizedBox(height:12),
        FilledButton.icon(onPressed:()=>go(context,const TrendsScreen()),
          icon:const Icon(Icons.insights),label:Text(s.t('قارن مع النتيجة السابقة','Compare with previous result'))),
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:()=>go(context,const SharingScreen()),
          icon:const Icon(Icons.ios_share),label:Text(s.t('إدارة مشاركة النتائج','Manage report sharing'))),
        ActionRow(Icons.picture_as_pdf_outlined,s.t('معاينة نسخة التقرير','Preview report document'),
          subtitle:s.t('التنزيل والطباعة بعد الربط','Download and printing after integration'),
          onTap:()=>go(context,ReportDocumentScreen(report))),
        ActionRow(Icons.auto_awesome_outlined,s.t('شرح النتيجة','Understand the report'),
          subtitle:s.t('واجهة مساعد تجريبية','Demo assistant interface'),
          onTap:()=>go(context,const AssistantScreen())),
      ],
    ]);
  }
}
class ReportDocumentScreen extends StatelessWidget {
  const ReportDocumentScreen(this.report,{super.key});
  final Report report;
  @override
  Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('معاينة المستند','Document preview'),children:[
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const BrandMark(),const SizedBox(height:16),
        const Text('DIGITAL LAB',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900,letterSpacing:2)),
        Text(s.t('تقرير توضيحي • ليس مستنداً طبياً','ILLUSTRATIVE REPORT • NOT A MEDICAL DOCUMENT')),
        const Divider(),Text('${report.id} • ${report.date}'),
        const SizedBox(height:16),
        ...markers.map((m)=>Padding(padding:const EdgeInsets.symmetric(vertical:12),
          child:Wrap(spacing:20,runSpacing:5,children:[
            Text(m.name,style:const TextStyle(fontWeight:FontWeight.w700)),
            Text('${m.value} ${m.unit}'),Text('${m.low} – ${m.high}'),
          ]))),
      ])),
      Note(s.t('هذه معاينة داخل التطبيق. توليد PDF والتوقيع والتنزيل والطباعة تحتاج خدمة التقارير في مرحلة الربط.',
        'This is an in-app preview. PDF generation, signatures, download and printing require the report service.')),
    ]);
  }
}
class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('مقارنة النتائج','Compare results'),children:[
      Heading(s.t('تغيّر المؤشرات مع الوقت','Markers over time'),
        subtitle:s.t('زيارتان تجريبيتان • ليست بيانات مريض حقيقي','Two fictional visits • Not real patient data')),
      ...markers.map((m)=>Padding(padding:const EdgeInsets.only(bottom:16),
        child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(m.name,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
          const SizedBox(height:10),
          Wrap(spacing:18,runSpacing:8,children:[
            Text(s.t('05 أغسطس: ${m.previous}','05 Aug: ${m.previous}')),
            Text(s.t('05 أكتوبر: ${m.value} ${m.unit}','05 Oct: ${m.value} ${m.unit}')),
            Tag('${((m.value-m.previous)/m.previous*100).toStringAsFixed(1)}%'),
          ]),
          const SizedBox(height:18),
          Semantics(label:'${m.name}: ${m.previous} to ${m.value} ${m.unit}. Range ${m.low} to ${m.high}',
            child:SizedBox(height:110,width:double.infinity,
              child:CustomPaint(painter:TrendPainter(m,Theme.of(context).colorScheme.onSurface)))),
          const SizedBox(height:8),Text(s.t('المنطقة المظللة: المدى التوضيحي ${m.low}–${m.high}',
            'Shaded area: illustrative range ${m.low}–${m.high}'),
            style:TextStyle(fontSize:11,color:muted(context))),
        ])))),
    ]);
  }
}
class TrendPainter extends CustomPainter {
  TrendPainter(this.marker,this.textColor);
  final Marker marker;
  final Color textColor;
  @override
  void paint(Canvas canvas,Size size) {
    final span=marker.high-marker.low;
    final lower=math.min(marker.low,math.min(marker.value,marker.previous))-span*.2;
    final upper=math.max(marker.high,math.max(marker.value,marker.previous))+span*.2;
    double y(double value)=>size.height-10-(value-lower)/(upper-lower)*(size.height-20);
    canvas.drawRect(Rect.fromLTRB(20,y(marker.high),size.width-20,y(marker.low)),
      Paint()..color=accent.withAlpha(18));
    for(final v in [marker.low,marker.high]) {
      canvas.drawLine(Offset(20,y(v)),Offset(size.width-20,y(v)),Paint()..color=accent.withAlpha(60));
    }
    final a=Offset(35,y(marker.previous)), b=Offset(size.width-35,y(marker.value));
    canvas.drawLine(a,b,Paint()..color=accent..strokeWidth=3);
    for(final p in [a,b]) {
      canvas.drawCircle(p,6,Paint()..color=accent);
      canvas.drawCircle(p,3,Paint()..color=Colors.white);
    }
  }
  @override bool shouldRepaint(covariant TrendPainter old)=>old.marker!=marker||old.textColor!=textColor;
}
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override State<BookingsScreen> createState()=>_BookingsScreenState();
}
class _BookingsScreenState extends State<BookingsScreen> {
  String status='upcoming';
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final list=s.bookings.where((b)=>b.status==status&&b.patientId==s.patientId).toList()
      ..sort((a,b)=>a.date.compareTo(b.date));
    return ScreenBody(children:[
      Heading(s.t('كل موعد، خطوة للعناية','Every visit, a step toward care'),
        subtitle:s.t('رتّب زياراتك وتابع طلباتك بسهولة.','Organize your visits and follow your requests.')),
      const PatientPicker(),const SizedBox(height:18),
      Wrap(spacing:8,runSpacing:8,children:[
        for(final item in [('upcoming',s.t('القادمة','Upcoming')),('completed',s.t('المكتملة','Completed')),
          ('cancelled',s.t('الملغاة','Cancelled'))])
          ChoiceChip(label:Text(item.$2),selected:status==item.$1,
            onSelected:(_)=>setState(()=>status=item.$1)),
      ]),
      const SizedBox(height:20),
      if(list.isEmpty) EmptyState(s.t('مساحة لموعدك القادم','Space for your next visit'),
        s.t('لا توجد حجوزات ضمن هذا القسم.','There are no bookings in this section.'),
        icon:Icons.calendar_month_outlined,action:FilledButton(
          onPressed:()=>go(context,const ExploreScreen(standalone:true)),child:Text(s.t('استكشف الخدمات','Explore services'))))
      else ...list.map(BookingCard.new),
    ]);
  }
}
class BookingCard extends StatelessWidget {
  const BookingCard(this.booking,{super.key});
  final Booking booking;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return Padding(padding:const EdgeInsets.only(bottom:14),child:Panel(
      onTap:()=>go(context,BookingDetailScreen(booking)),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Wrap(spacing:10,runSpacing:8,children:[Tag(booking.id),
            Tag(booking.home?s.t('سحب منزلي','Home collection'):s.t('موعد','Appointment'))]),
          const SizedBox(height:16),
          Text(booking.service.title(s),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
          const SizedBox(height:8),Text(dateLabel(booking.date),textDirection:TextDirection.ltr,
            style:TextStyle(color:muted(context))),
          const Divider(),Text(s.t('عرض تفاصيل الحجز','View appointment details'),
            style:const TextStyle(color:accent,fontWeight:FontWeight.w700)),
        ])));
  }
}
class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen(this.booking,{super.key});
  final Booking booking;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final b=booking;
    return DetailPage(title:s.t('تفاصيل الحجز','Booking details'),children:[
      Heading(b.service.title(s),subtitle:b.id),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Tag(b.status=='cancelled'?s.t('ملغي','Cancelled'):b.status=='completed'?s.t('مكتمل','Completed'):s.t('قادم','Upcoming')),
        const SizedBox(height:18),
        Text(s.patients.firstWhere((p)=>p.id==b.patientId).name,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
        const SizedBox(height:8),Text(dateLabel(b.date),textDirection:TextDirection.ltr),
        const Divider(),
        Text(s.t('الهاتف: ${b.phone}','Phone: ${b.phone}')),
        const SizedBox(height:8),Text(s.t('نوع الموعد: ${modeLabel(s,b.mode)}','Visit type: ${modeLabel(s,b.mode)}')),
        if(b.address.isNotEmpty) Padding(padding:const EdgeInsets.only(top:8),child:Text(b.address)),
        if(b.notes.isNotEmpty) Padding(padding:const EdgeInsets.only(top:8),child:Text(b.notes)),
        const Divider(),
        Text(s.t('الإجمالي التجريبي: ${s.money(b.total)}','Demo total: ${s.money(b.total)}'),
          style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
        const SizedBox(height:8),Text(s.t('طريقة الدفع: ${b.payment=='provider'?'عند مقدم الخدمة':'إلكتروني تجريبي'}',
          'Payment: ${b.payment=='provider'?'At provider':'Simulated online'}')),
      ])),
      Note(s.t('لم يُرسل هذا الحجز ولم يُخصم أي مبلغ. يُحفظ في جلسة العرض فقط.',
        'This booking was not sent and no payment was taken. It exists only in this demo session.')),
      if(b.home) ActionRow(Icons.route_outlined,s.t('تتبع السحب المنزلي','Track home collection'),
        subtitle:s.t('عرض مراحل الطلب','View request stages'),onTap:()=>go(context,TrackingScreen(b))),
      if(b.status=='upcoming') ...[
        FilledButton.icon(onPressed:() async {
          final date=await showDatePicker(context:context,initialDate:b.date,
            firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:90)));
          if(date==null||!context.mounted)return;
          final time=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(b.date));
          if(time==null)return;
          b.date=DateTime(date.year,date.month,date.day,time.hour,time.minute);s.update();
        },icon:const Icon(Icons.edit_calendar),label:Text(s.t('تغيير الموعد','Reschedule'))),
        const SizedBox(height:10),
        OutlinedButton(onPressed:() async {
          if(await confirm(context,s.t('إلغاء الحجز؟','Cancel this booking?'),
            s.t('سيُنقل الحجز إلى الملغاة. لا يوجد مبلغ مدفوع في النسخة التجريبية.',
              'The booking moves to Cancelled. No payment was taken in this demo.'))) s.cancelBooking(b);
        },child:Text(s.t('إلغاء الحجز','Cancel booking'))),
        TextButton(onPressed:(){b.status='completed';if(b.home)b.progress=8;s.update();},
          child:Text(s.t('تجربة: محاكاة اكتمال الزيارة','Demo: simulate completed visit'))),
      ],
      if(b.service.kind=='doctors' && b.status!='cancelled') ActionRow(
        Icons.forum_outlined,s.t('غرفة الاستشارة','Consultation room'),
        subtitle:s.t('معاينة المحادثة والصوت والفيديو','Preview chat, voice and video'),
        onTap:()=>go(context,const ConsultationScreen())),
      if(b.status=='completed') ActionRow(Icons.star_outline,s.t('قيّم تجربتك','Rate your experience'),
        onTap:()=>go(context,FeedbackScreen(bookingId:b.id))),
      if(b.status=='cancelled') Note(s.t('الاسترداد: غير منطبق لأن الطلب تجريبي وغير مدفوع.',
        'Refund: not applicable because this demo booking was not charged.')),
    ]);
  }
}
class TrackingScreen extends StatelessWidget {
  const TrackingScreen(this.booking,{super.key});
  final Booking booking;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final stages=[s.t('تم إرسال الطلب','Submitted'),s.t('تم قبول الطلب','Accepted'),
      s.t('تم تعيين فني','Collector assigned'),s.t('الفني في الطريق','On the way'),
      s.t('وصل الفني','Collector arrived'),s.t('تم سحب العينة','Sample collected'),
      s.t('وصلت العينة للمختبر','Sample received'),s.t('قيد التحليل','Processing'),s.t('النتيجة جاهزة','Result ready')];
    return DetailPage(title:s.t('رحلة العينة','The sample journey'),children:[
      Heading(booking.id,subtitle:booking.address),
      Note(s.t('تسلسل تجريبي. لا يوجد فني فعلي أو تتبع موقع مباشر.',
        'Simulated stages. No real collector or live location tracking.')),
      ...stages.asMap().entries.map((e)=>ActionRow(
        e.key<=booking.progress?Icons.check_circle_outline:Icons.radio_button_unchecked,e.value,
        trailing:e.key==booking.progress?Tag(s.t('الحالية','Current')):const SizedBox.shrink())),
      if(booking.progress<8 && booking.status=='upcoming') FilledButton(
        onPressed:(){booking.progress++;if(booking.progress==8)booking.status='completed';s.update();},
        child:Text(s.t('محاكاة المرحلة التالية','Simulate next stage'))),
      if(booking.status=='cancelled') Tag(s.t('تم إلغاء الطلب','Request cancelled'),color:amber),
    ]);
  }
}
