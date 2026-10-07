part of '../main.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final items=[
      ('result',Icons.description_outlined,s.t('تقرير جديد بانتظارك','A new report is ready'),
        s.t('صورة الدم الكاملة • ملف أحمد التجريبي','Blood count • Demo Ahmed profile')),
      ('care',Icons.calendar_month_outlined,s.t('رتّب موعد العناية القادم','Plan your next care visit'),
        s.t('استكشف باقات المختبر','Explore laboratory packages')),
      ('reward',Icons.workspace_premium_outlined,s.t('مكافآت عضويتك','Your membership rewards'),
        s.t('تعرف على رصيد النقاط التجريبي','View your demo points balance')),
    ];
    return DetailPage(title:s.t('الإشعارات','Notifications'),actions:[
      IconButton(tooltip:s.t('قراءة الكل','Mark all read'),onPressed:(){
        s.readNotifications.addAll(items.map((v)=>v.$1));s.update();
      },icon:const Icon(Icons.done_all)),
    ],children:[
      Heading(s.t('كل جديد، هنا','Your latest, right here')),
      ...items.map((e)=>ActionRow(e.$2,e.$3,subtitle:e.$4,
        trailing:s.readNotifications.contains(e.$1)?const Icon(Icons.done,size:18):const Icon(Icons.circle,color:accent,size:9),
        onTap:(){s.readNotifications.add(e.$1);s.update();
          if(e.$1=='result'){s.selectPatient('p1');go(context,const ReportScreen(Report('DL-24081','p1','صورة الدم الكاملة','Complete blood count',true,'05/10/2026')));}
          if(e.$1=='care')go(context,const ExploreScreen(standalone:true));
          if(e.$1=='reward')go(context,const RewardsScreen());
        })),
      ActionRow(Icons.tune,s.t('تفضيلات التنبيهات','Notification preferences'),
        onTap:()=>go(context,const SettingsScreen())),
    ]);
  }
}
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('العروض والإحالات','Offers & referrals'),children:[
      Panel(color:midnight,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Icon(Icons.local_offer_outlined,color:Color(0xFFBDECD6),size:44),
        const SizedBox(height:20),
        Text(s.t('اهتمام أكثر،\nبتفاصيل ألطف.','A little more care.\nA thoughtful little extra.'),
          style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:28,height:1.5)),
        const SizedBox(height:16),const Text('DIGITAL10',style:TextStyle(color:Color(0xFFBDECD6),
          fontSize:25,fontWeight:FontWeight.w800,letterSpacing:3)),
        const SizedBox(height:12),
        Text(s.t('خصم تجريبي 10% على الباقات، بحد 10,000 د.ع. لا يشمل رسوم السحب.',
          'Demo 10% discount on packages, capped at IQD 10,000. Collection fees excluded.'),
          style:const TextStyle(color:Colors.white70,height:1.7)),
      ])),
      const SizedBox(height:16),
      FilledButton(onPressed:()=>go(context,const ExploreScreen(standalone:true)),
        child:Text(s.t('استكشف الباقات','Explore packages'))),
      Section(s.t('شارك فكرة العناية','Share the idea of care')),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(s.t('رمز إحالتك التجريبي','Your demo referral code'),style:const TextStyle(fontWeight:FontWeight.w700)),
        const SizedBox(height:12),const SelectableText('DL-DEMO-2026',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),
        const SizedBox(height:12),OutlinedButton.icon(onPressed:() async {
          await Clipboard.setData(const ClipboardData(text:'DL-DEMO-2026'));
          if(context.mounted)toast(context,s.t('تم نسخ الرمز التجريبي','Demo code copied'));
        },icon:const Icon(Icons.copy),label:Text(s.t('نسخ الرمز','Copy code'))),
      ])),
      Note(s.t('لا يُرسل رابط دعوة ولا تُحتسب إحالات فعلية. إنشاء الروابط وQR والمكافآت بعد الربط.',
        'No invitations are sent or real referrals tracked. Links, QR codes and rewards follow during integration.')),
    ]);
  }
}
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override State<AssistantScreen> createState()=>_AssistantScreenState();
}
class _AssistantScreenState extends State<AssistantScreen> {
  final entries=<String>[];
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('مساعدك الصحي','Health assistant'),children:[
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Glyph(Icons.auto_awesome_outlined,size:65),
        const SizedBox(height:18),Heading(s.t('مساحة لأسئلتك','A space for your questions'),
          subtitle:s.t('واجهة عرض للمساعد، بدون نموذج ذكاء اصطناعي متصل.',
            'An assistant interface preview, without a connected AI model.')),
        Wrap(spacing:8,runSpacing:8,children:[
          for(final title in [s.t('كيف أقرأ التقرير؟','How do I read a report?'),
            s.t('كيف أشارك النتيجة؟','How do I share a result?')])
            ActionChip(label:Text(title),onPressed:()=>setState(()=>entries.add(title))),
        ]),
      ])),
      const SizedBox(height:18),
      ...entries.map((q)=>Padding(padding:const EdgeInsets.only(bottom:16),child:Column(
        crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Panel(child:Text(q)),
          const SizedBox(height:8),Panel(child:Text(s.t(
            'رد عرض ثابت: يمكنك فتح النتيجة للاطلاع على القيمة والوحدة والمدى المرجعي، ثم استخدام مشاركة النتائج للتحكم بالإذن. لا يتم تحليل بياناتك أو تقديم تشخيص في هذه النسخة.',
            'Fixed demo response: open a report to see values, units and reference ranges. Use Report sharing to manage permissions. This version does not analyze your data or provide a diagnosis.'),
            style:const TextStyle(height:1.8))),
        ]))),
      FilledButton.icon(onPressed:() async {
        final q=await prompt(context,s.t('سؤال تجريبي','Demo question'),lines:2);
        if(q!=null&&mounted)setState(()=>entries.add(q));
      },icon:const Icon(Icons.chat_bubble_outline),label:Text(s.t('جرّب كتابة سؤال','Try writing a question'))),
      ActionRow(Icons.lock_outline,s.t('إدارة موافقة التحليل','Manage analysis consent'),
        onTap:()=>go(context,const PrivacyScreen())),
    ]);
  }
}
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});
  @override State<ConsultationScreen> createState()=>_ConsultationScreenState();
}
class _ConsultationScreenState extends State<ConsultationScreen> {
  bool mutedMic=false,camera=false,session=false;
  final messages=<String>[];
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('غرفة الاستشارة','Consultation room'),children:[
      Panel(color:midnight,child:Column(children:[
        const SizedBox(height:18),const CircleAvatar(radius:40,backgroundColor:accent,
          child:Icon(Icons.person_outline,color:Colors.white,size:44)),
        const SizedBox(height:20),
        Text(s.t('غرفة معاينة فقط','Preview room only'),
          style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w800)),
        const SizedBox(height:10),
        Text(session?s.t('المحاكاة قيد العرض','Simulation running'):s.t('لا يوجد طبيب متصل','No doctor connected'),
          style:const TextStyle(color:Colors.white70)),
        const SizedBox(height:24),
        Wrap(spacing:12,runSpacing:12,alignment:WrapAlignment.center,children:[
          IconButton.filled(tooltip:s.t('تبديل الميكروفون التجريبي','Toggle demo microphone'),
            onPressed:()=>setState(()=>mutedMic=!mutedMic),icon:Icon(mutedMic?Icons.mic_off:Icons.mic)),
          IconButton.filled(tooltip:s.t('تبديل الكاميرا التجريبية','Toggle demo camera'),
            onPressed:()=>setState(()=>camera=!camera),icon:Icon(camera?Icons.videocam:Icons.videocam_off)),
          IconButton.filled(tooltip:s.t('بدء أو إنهاء المحاكاة','Start or stop simulation'),
            onPressed:()=>setState(()=>session=!session),
            style:IconButton.styleFrom(backgroundColor:session?const Color(0xFFB65059):accent),
            icon:Icon(session?Icons.call_end:Icons.call)),
        ]),
        const SizedBox(height:18),
      ])),
      Note(s.t('الأزرار تغيّر حالة العرض فقط؛ لا تُفتح الكاميرا أو الميكروفون ولا توجد مكالمة فعلية.',
        'Controls change the preview only; no camera or microphone is opened and no call takes place.')),
      Section(s.t('المحادثة التجريبية','Demo conversation')),
      ...messages.map((m)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Panel(child:Text(m)))),
      OutlinedButton.icon(onPressed:() async {
        final m=await prompt(context,s.t('اكتب رسالة للمعاينة','Write a preview message'),lines:2);
        if(m!=null&&mounted)setState(()=>messages.add(m));
      },icon:const Icon(Icons.send_outlined),label:Text(s.t('إضافة رسالة محلية','Add local message'))),
      ActionRow(Icons.attach_file,s.t('إذن مشاركة التقرير','Report sharing permission'),
        onTap:()=>go(context,const SharingScreen())),
    ]);
  }
}
class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});
  @override State<PharmacyScreen> createState()=>_PharmacyScreenState();
}
class _PharmacyScreenState extends State<PharmacyScreen> {
  String fulfillment='pickup';
  final requests=<String>[];
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('الصيدلية والوصفات','Pharmacy & prescriptions'),children:[
      Heading(s.t('رعايتك تكمل هنا','Your care continues here'),
        subtitle:s.t('معاينة طلب وصفة وطريقة الاستلام.','Preview prescription requests and fulfillment.')),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Glyph(Icons.medication_outlined,size:66),const SizedBox(height:20),
        Text(s.t('وصفاتك الطبية','Your prescriptions'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800)),
        const SizedBox(height:10),Text(s.t('لا توجد وصفة صادرة عن طبيب في هذا النموذج.',
          'No doctor-issued prescription exists in this prototype.')),
      ])),
      const SizedBox(height:20),
      DropdownButtonFormField<String>(value:fulfillment,
        decoration:InputDecoration(labelText:s.t('طريقة الاستلام','Fulfillment')),
        items:[DropdownMenuItem(value:'pickup',child:Text(s.t('استلام من الصيدلية','Pharmacy pickup'))),
          DropdownMenuItem(value:'delivery',child:Text(s.t('توصيل إلى المنزل','Home delivery')))],
        onChanged:(v)=>setState(()=>fulfillment=v!)),
      const SizedBox(height:20),
      FilledButton(onPressed:() async {
        final title=await prompt(context,s.t('عنوان طلب تجريبي — بدون بيانات طبية','Demo request title — no medical details'));
        if(title==null||!context.mounted)return;
        String? address;
        if(fulfillment=='delivery') address=await prompt(context,s.t('عنوان توصيل وهمي','Fictional delivery address'));
        if(!mounted||(fulfillment=='delivery'&&address==null))return;
        setState(()=>requests.add('$title • ${fulfillment=='delivery'?address:s.t('استلام','Pickup')}'));
      },child:Text(s.t('إنشاء طلب تجريبي','Create demo request'))),
      Section(s.t('طلباتي','My requests')),
      ...requests.map((r)=>ActionRow(Icons.receipt_long_outlined,r,
        subtitle:s.t('لم يُرسل للصيدلية','Not sent to a pharmacy'),trailing:Tag(s.t('مسودة','Draft')))),
      Note(s.t('لا توجد أدوية للبيع أو وصفات أو مخزون متصل. يلزم ربط الصيدليات والتحقق من الوصفات قبل التنفيذ.',
        'No medications, prescriptions or inventory are connected. Pharmacy integration and prescription verification are required.')),
    ]);
  }
}
class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('التأمين الصحي','Health insurance'),children:[
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Glyph(Icons.verified_user_outlined,size:64),
        const SizedBox(height:20),Heading(s.t('تغطية أوضح، راحة أكثر','Clarity for your coverage'),
          subtitle:s.t('معاينة إدارة الوثيقة والمطالبات.','Preview policy and claims management.')),
        Tag(s.t('لا توجد وثيقة مرتبطة','NO LINKED POLICY')),
      ])),
      const SizedBox(height:16),
      FilledButton(onPressed:() async {
        final name=await prompt(context,s.t('اسم شركة تأمين تجريبي','Demo insurance company name'));
        if(name!=null){s.claims.add(name);s.update();}
      },child:Text(s.t('إضافة طلب ربط تجريبي','Add demo linking request'))),
      Section(s.t('الطلبات','Requests')),
      ...s.claims.map((r)=>ActionRow(Icons.assignment_outlined,r,
        subtitle:s.t('لم يُرسل • بانتظار الربط','Not sent • Awaiting integration'),trailing:Tag(s.t('مسودة','Draft')))),
      Note(s.t('لا يتم تأكيد أهلية أو تغطية أو قبول مطالبات في النموذج. هذه القرارات تأتي من شركة التأمين بعد الربط.',
        'Eligibility, coverage and claim approval are not determined in this prototype. Those decisions come from the insurer after integration.')),
    ]);
  }
}
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('المساعدة والدعم','Help & support'),children:[
      Heading(s.t('نحن هنا لنسمعك','We are here to listen'),
        subtitle:s.t('إجابات واضحة ومساحة للملاحظات.','Clear answers and space for feedback.')),
      TileGrid(children:[
        FeatureTile(Icons.chat_outlined,s.t('تذكرة دعم','Support ticket'),s.t('سجّل ملاحظة تجريبية','Save a demo request'),
          onTap:() async {
            final message=await prompt(context,s.t('كيف نساعدك؟ — نموذج تجريبي','How can we help? — demo'),lines:3);
            if(message!=null){s.tickets.add(message);s.update();}
          }),
        FeatureTile(Icons.call_outlined,s.t('قنوات التواصل','Contact channels'),
          s.t('الهاتف وواتساب بعد الربط','Phone & WhatsApp after integration'),
          onTap:()=>previewNotice(context,s.t('قنوات الدعم','Support channels'),
            s.t('سيتم إعداد رقم الدعم وروابط واتساب المعتمدة في مرحلة الربط.',
              'Verified phone and WhatsApp support channels will be configured during integration.'))),
      ]),
      Section(s.t('الأسئلة المتكررة','Frequently asked questions')),
      for(final e in [
        (s.t('هل الحجز هنا حقيقي؟','Is this a real booking?'),
          s.t('كل الحجوزات تجريبية ولا تصل إلى مختبر أو طبيب.','All bookings are demos and do not reach a lab or doctor.')),
        (s.t('هل تُحفظ بياناتي؟','Is my data saved?'),
          s.t('تُحفظ في الذاكرة خلال الجلسة وتُصفّر عند إعادة التشغيل.','Data stays in memory during this session and resets on restart.')),
        (s.t('كيف أغيّر اللغة؟','How do I change the language?'),
          s.t('استخدم زر اللغة أعلى الرئيسية أو صفحة الإعدادات.','Use the language button in the header or the Settings page.')),
      ]) ExpansionTile(title:Text(e.$1),children:[Padding(padding:const EdgeInsets.all(18),child:Text(e.$2))]),
      Section(s.t('تذاكري التجريبية','My demo tickets')),
      ...s.tickets.asMap().entries.map((e)=>ActionRow(Icons.confirmation_number_outlined,
        'T-${100+e.key}',subtitle:e.value,trailing:Tag(s.t('محلي فقط','Local only')))),
      ActionRow(Icons.rate_review_outlined,s.t('شاركنا رأيك بالتصميم','Give design feedback'),
        onTap:()=>go(context,const FeedbackScreen())),
    ]);
  }
}
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key,this.bookingId});
  final String? bookingId;
  @override State<FeedbackScreen> createState()=>_FeedbackScreenState();
}
class _FeedbackScreenState extends State<FeedbackScreen> {
  double rating=4,nps=8;
  String message='';
  bool saved=false;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('رأيك يهمنا','Your feedback matters'),children:[
      Heading(s.t('كيف كانت تجربتك؟','How was your experience?'),subtitle:widget.bookingId),
      Panel(child:Column(children:[
        Wrap(alignment:WrapAlignment.center,children:List.generate(5,(i)=>IconButton(
          tooltip:'${i+1} / 5',onPressed:()=>setState(()=>rating=i+1.0),
          icon:Icon(i<rating?Icons.star:Icons.star_border,color:amber,size:30)))),
        const SizedBox(height:20),Text(s.t('هل تنصح بهذه التجربة؟','How likely are you to recommend this experience?')),
        Slider(value:nps,min:0,max:10,divisions:10,label:nps.round().toString(),onChanged:(v)=>setState(()=>nps=v)),
        TextFormField(maxLines:3,onChanged:(v)=>message=v,
          decoration:InputDecoration(labelText:s.t('ملاحظتك — اختياري','Your feedback — optional'))),
      ])),
      const SizedBox(height:20),FilledButton(onPressed:saved?null:(){
        s.reviews.add('${widget.bookingId??'design'}: $rating/5; NPS $nps; $message');s.update();
        setState(()=>saved=true);
      },child:Text(saved?s.t('حُفظت الملاحظة في الجلسة','Saved in this session'):s.t('حفظ الملاحظة التجريبية','Save demo feedback'))),
    ]);
  }
}
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});
  @override State<CheckinScreen> createState()=>_CheckinScreenState();
}
class _CheckinScreenState extends State<CheckinScreen> {
  bool checked=false;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('بطاقة المريض والدور','Patient card & queue'),children:[
      const PatientPicker(),const SizedBox(height:20),
      Panel(child:Column(children:[
        const BrandMark(size:65),const SizedBox(height:20),
        Text(s.patient.name,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:22)),
        const SizedBox(height:10),Text('DL • ${s.patientId.toUpperCase()}'),
        const SizedBox(height:22),
        const Icon(Icons.qr_code_2,size:100,color:accent),
        Text(s.t('مكان رمز QR — غير قابل للمسح','QR placeholder — not scannable'),style:TextStyle(color:muted(context),fontSize:12)),
      ])),
      const SizedBox(height:20),
      FilledButton(onPressed:()=>setState(()=>checked=!checked),
        child:Text(checked?s.t('إعادة تجربة الدخول','Reset check-in demo'):s.t('محاكاة تسجيل الوصول','Simulate check-in'))),
      if(checked) ...[
        Section(s.t('دورك التجريبي','Your demo queue ticket')),
        Panel(child:Column(children:[
          const Text('A-004',style:TextStyle(fontSize:42,fontWeight:FontWeight.w800)),
          Text(s.t('3 أشخاص أمامك • بيانات عرض ثابتة','3 people ahead • Static demo data')),
        ])),
      ],
      Note(s.t('تسجيل الوصول والطابور وQR تحتاج نظام الفرع للتحقق والتحديث.',
        'Check-in, queues and QR codes require the branch system for verification and live updates.')),
    ]);
  }
}
class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('الفروع والمواقع','Branches & locations'),children:[
      Heading(s.t('رعاية أقرب إليك','Care closer to you')),
      Panel(child:Column(children:[
        const Glyph(Icons.map_outlined,size:90),const SizedBox(height:20),
        Text(s.t('مساحة معاينة الخريطة','Map preview area'),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
        const SizedBox(height:8),Text(s.t('سيتم ربط المواقع والملاحة لاحقاً. لا توجد إحداثيات حقيقية.',
          'Locations and navigation will be connected later. No real coordinates are shown.'),textAlign:TextAlign.center),
      ])),
      Section(s.t('الفروع التجريبية','Demo branches')),
      ...services.where((v)=>v.kind=='labs').map(ServiceCard.new),
    ]);
  }
}
class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('دليل الزيارة','Visit guide'),children:[
      Heading(s.t('خطوات أوضح لزيارتك','A clearer path to your visit')),
      for(final e in [
        (s.t('قبل الحجز','Before booking'),s.t('اختر الباقة المناسبة لطلب طبيبك، وتحقق من تفاصيل الخدمة قبل تأكيد الموعد.',
          'Choose the panel requested by your clinician and review service details before confirming the appointment.')),
        (s.t('تعليمات التحضير','Preparation instructions'),s.t('تعليمات الصيام والتحضير تختلف باختلاف الفحص. تُعرض تعليمات المختبر المعتمدة عند ربط الخدمة.',
          'Fasting and preparation vary by test. The laboratory’s approved instructions will be displayed after integration.')),
        (s.t('بعد ظهور النتيجة','When your report is ready'),s.t('راجع التقرير الكامل، ويمكنك مشاركة النتيجة مع طبيبك بإذن محدد المدة.',
          'Review the full report and share it with your clinician using a time-limited permission.')),
      ]) Padding(padding:const EdgeInsets.only(bottom:16),child:Panel(child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Glyph(Icons.menu_book_outlined),const SizedBox(height:16),
          Text(e.$1,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
          const SizedBox(height:10),Text(e.$2,style:TextStyle(color:muted(context),height:1.9)),
        ]))),
    ]);
  }
}
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState()=>_LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final form=GlobalKey<FormState>();
  String phone='',code='';
  bool sent=false,complete=false;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('معاينة الدخول','Sign-in preview'),children:[
      const SizedBox(height:20),const Align(alignment:Alignment.center,child:BrandMark(size:76)),
      const SizedBox(height:25),
      Heading(s.t('أهلاً بك في مساحة العناية','Welcome to your care space'),
        subtitle:s.t('تجربة شاشة الهاتف ورمز التحقق فقط.','Preview the phone and verification code screens.')),
      Form(key:form,child:Column(children:[
        if(!sent) TextFormField(key:const ValueKey('login-phone'),keyboardType:TextInputType.phone,
          textDirection:TextDirection.ltr,decoration:InputDecoration(labelText:s.t('رقم الهاتف','Phone number')),
          onChanged:(v)=>phone=v,validator:(v)=>validIraqiPhone(v??'')?null:s.t('أدخل رقماً عراقياً صالحاً','Enter a valid Iraqi number')),
        if(sent) TextFormField(key:const ValueKey('login-otp'),keyboardType:TextInputType.number,
          maxLength:6,textDirection:TextDirection.ltr,
          decoration:InputDecoration(labelText:s.t('رمز تجريبي: 000000','Demo code: 000000')),
          onChanged:(v)=>code=v,validator:(v)=>v=='000000'?null:s.t('رمز العرض هو 000000','The demo code is 000000')),
        const SizedBox(height:20),SizedBox(width:double.infinity,child:FilledButton(onPressed:complete?null:(){
          if(!form.currentState!.validate())return;
          setState((){if(sent){complete=true;s.loggedInDemo=true;s.update();}else{sent=true;}});
        },child:Text(complete?s.t('اكتملت معاينة الدخول','Sign-in preview complete'):
          sent?s.t('تحقق تجريبي','Simulate verification'):s.t('متابعة التجربة','Continue preview')))),
      ])),
      Note(s.t('لا تُرسل رسالة SMS، ولا تُتحقق الهوية فعلياً، ولا يُربط ملف طبي برقم الهاتف.',
        'No SMS is sent, identity is not verified, and no medical record is linked by phone number.')),
    ]);
  }
}
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('استوديو الإدارة','Admin design studio'),children:[
      Heading(s.t('نظرة على تجربة الإدارة','A look at the admin experience'),
        subtitle:s.t('واجهة عرض بلا صلاحيات إدارية فعلية.','A preview with no real administrative permissions.')),
      TileGrid(children:[
        FeatureTile(Icons.calendar_month_outlined,'${s.bookings.length}',s.t('حجز في الجلسة','Session bookings'),
          onTap:()=>go(context,const AdminModuleScreen('orders'))),
        FeatureTile(Icons.people_outline,'${s.patients.length}',s.t('ملف تجريبي','Demo profiles'),
          onTap:()=>go(context,const FamilyScreen())),
        FeatureTile(Icons.support_agent,'${s.tickets.length}',s.t('تذكرة محلية','Local tickets'),
          onTap:()=>go(context,const SupportScreen())),
        FeatureTile(Icons.rate_review_outlined,'${s.reviews.length}',s.t('ملاحظة محفوظة','Saved feedback'),
          onTap:()=>go(context,const AdminModuleScreen('feedback'))),
      ]),
      Section(s.t('مساحات الإدارة','Administration areas')),
      ...[
        ('providers',Icons.verified_outlined,s.t('المختبرات والأطباء والفروع','Providers & branches')),
        ('orders',Icons.receipt_long_outlined,s.t('الحجوزات والفنيون والطلبات','Bookings, collectors & orders')),
        ('campaigns',Icons.campaign_outlined,s.t('البانرات والحملات والعروض','Banners, campaigns & offers')),
        ('notifications',Icons.notifications_outlined,s.t('محرر الإشعارات','Notification composer')),
        ('points',Icons.workspace_premium_outlined,s.t('النقاط والمكافآت','Points & rewards')),
        ('revenue',Icons.query_stats,s.t('الإيرادات والاشتراكات والرعاة','Revenue, subscriptions & sponsors')),
        ('flags',Icons.toggle_on_outlined,s.t('المميزات والصيانة والإصدارات','Features, maintenance & versions')),
        ('audit',Icons.manage_accounts_outlined,s.t('الأدوار وسجل الإجراءات','Roles & audit trail')),
      ].map((e)=>ActionRow(e.$2,e.$3,onTap:()=>go(context,AdminModuleScreen(e.$1)))),
    ]);
  }
}
class AdminModuleScreen extends StatefulWidget {
  const AdminModuleScreen(this.module,{super.key});
  final String module;
  @override State<AdminModuleScreen> createState()=>_AdminModuleScreenState();
}
class _AdminModuleScreenState extends State<AdminModuleScreen> {
  final drafts=<String>[];
  final flags=<String,bool>{'home':true,'consultations':true,'maintenance':false};
  final verified=<String>{};
  String audience='all';
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final m=widget.module;
    return DetailPage(title:s.t('معاينة الإدارة','Admin preview'),children:[
      Note(s.t('حالة محلية للعرض فقط. لا تغيّر بيانات التطبيق أو ترسل رسائل. بوابة الإدارة الآمنة والأدوار تُبنى مع الخدمات الخلفية.',
        'Local preview state only. No app data is changed and no messages are sent. Secure administration and roles require backend services.')),
      if(m=='providers') ...[
        Heading(s.t('التحقق من مقدم الخدمة','Provider verification')),
        ...services.where((v)=>v.kind!='packages').map((v)=>ActionRow(v.icon,v.title(s),
          subtitle:v.subtitle(s),trailing:Checkbox(value:verified.contains(v.id),
            onChanged:(value)=>setState((){value!?verified.add(v.id):verified.remove(v.id);}))))],
      if(m=='orders') ...[
        Heading(s.t('طلبات الجلسة','Session orders')),
        if(s.bookings.isEmpty) EmptyState(s.t('لا توجد طلبات','No orders'),s.t('أنشئ حجزاً من واجهة المريض.','Create a booking from the patient interface.')),
        ...s.bookings.map(BookingCard.new)],
      if(m=='feedback') ...[
        Heading(s.t('ملاحظات الجلسة','Session feedback')),...s.reviews.map((v)=>Panel(child:Text(v)))],
      if(m=='campaigns'||m=='notifications') ...[
        Heading(m=='campaigns'?s.t('مسودات الحملات','Campaign drafts'):s.t('معاينة الإشعار','Notification preview')),
        DropdownButtonFormField<String>(value:audience,decoration:InputDecoration(labelText:s.t('الجمهور','Audience')),
          items:[DropdownMenuItem(value:'all',child:Text(s.t('الكل — معاينة','Everyone — preview'))),
            DropdownMenuItem(value:'opted',child:Text(s.t('الموافقون على التسويق','Marketing opt-in')))],
          onChanged:(v)=>setState(()=>audience=v!)),
        const SizedBox(height:16),
        FilledButton(onPressed:() async {
          final text=await prompt(context,s.t('محتوى المسودة','Draft content'),lines:3);
          if(text!=null&&mounted)setState(()=>drafts.add(text));
        },child:Text(s.t('حفظ مسودة محلية','Save local draft'))),
        const SizedBox(height:16),...drafts.map((d)=>ActionRow(Icons.drafts_outlined,d,trailing:Tag(s.t('لم تُرسل','Not sent')))),
      ],
      if(m=='points') ...[
        Heading(s.t('معاينة برنامج الولاء','Loyalty preview')),
        ActionRow(Icons.workspace_premium_outlined,s.t('رصيد الجلسة','Session balance'),trailing:Text('${s.points}')),
        ActionRow(Icons.redeem,s.t('استبدالات تجريبية','Demo redemptions'),trailing:Text('${s.rewards.length}')),
        OutlinedButton(onPressed:()=>go(context,const RewardsScreen()),child:Text(s.t('عرض تجربة المريض','View patient experience'))),
      ],
      if(m=='revenue') ...[
        Heading(s.t('التقارير التجارية','Business reports')),
        TileGrid(children:[
          FeatureTile(Icons.payments_outlined,s.money(0),s.t('دفعات فعلية','Real payments'),onTap:()=>go(context,const WalletScreen())),
          FeatureTile(Icons.receipt_long_outlined,s.money(s.bookings.fold(0,(sum,b)=>sum+b.total)),
            s.t('قيمة طلبات تجريبية — ليست إيراداً','Demo order value — not revenue'),onTap:()=>go(context,const WalletScreen())),
        ]),
        Section(s.t('الاشتراكات والرعاة','Subscriptions & sponsors')),
        EmptyState(s.t('لا توجد عقود متصلة','No connected contracts'),
          s.t('إدارة الاشتراكات والرعايات تحتاج بيانات الخدمة الخلفية.','Subscriptions and sponsorships require backend contract data.')),
      ],
      if(m=='flags') ...[
        Heading(s.t('معاينة إعدادات النظام','System settings preview')),
        ...flags.keys.map((k)=>SwitchListTile(value:flags[k]!,title:Text(
          k=='home'?s.t('السحب المنزلي','Home collection'):k=='consultations'?s.t('الاستشارات','Consultations'):s.t('الصيانة','Maintenance')),
          onChanged:(v)=>setState(()=>flags[k]=v))),
        const Note('Design version: 0.3.0 • Minimum supported version: not configured'),
      ],
      if(m=='audit') ...[
        Heading(s.t('الأدوار وسجل الإجراءات','Roles & audit trail')),
        Wrap(spacing:8,runSpacing:8,children:[Tag(s.t('مدير','Administrator')),Tag(s.t('مشرف مختبر','Lab manager')),
          Tag(s.t('فني','Collector')),Tag(s.t('دعم','Support'))]),
        const SizedBox(height:20),
        EmptyState(s.t('لا يوجد سجل خادم','No server audit log'),
          s.t('المصادقة والأدوار والعزل وتسجيل العمليات تتبع في مرحلة الربط.',
            'Authentication, role permissions, isolation and event logging follow during integration.')),
      ],
    ]);
  }
}
