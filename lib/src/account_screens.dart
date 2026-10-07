part of '../main.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return ScreenBody(children:[
      Heading(s.t('مساحتك الشخصية','Your personal space'),
        subtitle:s.t('رعايتك، أفراد عائلتك، وتفضيلاتك.','Your care, your family, your preferences.')),
      Panel(child:Row(children:[
        CircleAvatar(radius:30,backgroundColor:accent,child:Text(s.patient.name.characters.first,
          style:const TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.w800))),
        const SizedBox(width:15),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s.patient.name,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
          const SizedBox(height:5),Text('DL • ${s.patientId.toUpperCase()}',style:TextStyle(color:muted(context),fontSize:12)),
        ])),IconButton(tooltip:s.t('تعديل الاسم','Edit name'),onPressed:() async {
          final name=await prompt(context,s.t('الاسم في النموذج','Demo display name'));
          if(name!=null){s.patient.name=name;s.update();}
        },icon:const Icon(Icons.edit_outlined)),
      ])),
      const SizedBox(height:14),
      Panel(color:midnight,onTap:()=>go(context,const RewardsScreen()),child:Row(children:[
        const Icon(Icons.workspace_premium_outlined,color:Color(0xFFEAC68C),size:38),
        const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s.t('عضويتك الذهبية','Your Gold membership'),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),
          const SizedBox(height:5),Text(s.t('${s.points} نقطة • رصيد تجريبي','${s.points} points • Demo balance'),
            style:const TextStyle(color:Color(0xFFEAC68C),fontSize:12)),
        ])),const Icon(Icons.arrow_outward,color:Colors.white,size:20),
      ])),
      Section(s.t('صحتي وعائلتي','My health & family')),
      ActionRow(Icons.people_outline,s.t('أفراد العائلة','Family profiles'),
        subtitle:s.t('ملف مستقل لكل شخص','A separate profile for every person'),onTap:()=>go(context,const FamilyScreen())),
      ActionRow(Icons.medical_information_outlined,s.t('معلوماتي الصحية','Medical information'),
        onTap:()=>go(context,const MedicalScreen())),
      ActionRow(Icons.folder_open_outlined,s.t('مستنداتي ووصفاتي','Documents & prescriptions'),
        onTap:()=>go(context,const DocumentsScreen())),
      ActionRow(Icons.alarm_outlined,s.t('التذكيرات','Reminders'),onTap:()=>go(context,const RemindersScreen())),
      ActionRow(Icons.shield_outlined,s.t('بطاقة الطوارئ','Emergency card'),onTap:()=>go(context,const EmergencyScreen())),
      ActionRow(Icons.qr_code_2,s.t('بطاقة المريض والدور','Patient card & check-in'),onTap:()=>go(context,const CheckinScreen())),
      Section(s.t('مزاياك وخدماتك','Benefits & services')),
      ActionRow(Icons.account_balance_wallet_outlined,s.t('المحفظة والمدفوعات','Wallet & payments'),
        onTap:()=>go(context,const WalletScreen())),
      ActionRow(Icons.local_offer_outlined,s.t('العروض والإحالات','Offers & referrals'),onTap:()=>go(context,const OffersScreen())),
      ActionRow(Icons.verified_user_outlined,s.t('التأمين الصحي','Health insurance'),onTap:()=>go(context,const InsuranceScreen())),
      ActionRow(Icons.favorite_border,s.t('المفضلة','Favorites'),
        onTap:()=>go(context,const ExploreScreen(standalone:true,collection:'favorites'))),
      ActionRow(Icons.history,s.t('شاهدتها مؤخراً','Recently viewed'),
        onTap:()=>go(context,const ExploreScreen(standalone:true,collection:'recent'))),
      Section(s.t('التحكم والمساعدة','Control & support')),
      ActionRow(Icons.tune,s.t('الإعدادات','Settings'),onTap:()=>go(context,const SettingsScreen())),
      ActionRow(Icons.lock_outline,s.t('الخصوصية والمشاركة','Privacy & sharing'),onTap:()=>go(context,const PrivacyScreen())),
      ActionRow(Icons.support_agent,s.t('المساعدة والدعم','Help & support'),onTap:()=>go(context,const SupportScreen())),
      ActionRow(Icons.login,s.t('معاينة تسجيل الدخول','Preview sign in'),onTap:()=>go(context,const LoginScreen())),
      ActionRow(Icons.dashboard_customize_outlined,s.t('استوديو الإدارة التجريبي','Admin design studio'),
        subtitle:s.t('معاينة منفصلة لوظائف الإدارة','Separate preview of administration features'),
        onTap:()=>go(context,const AdminScreen())),
      const Note('Digital Lab • Design edition 0.2'),
    ]);
  }
}
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('العائلة','Family profiles'),children:[
      Heading(s.t('العناية تجمعنا','Care brings us together'),
        subtitle:s.t('بدّل بين الملفات لعرض نتائج وحجوزات كل فرد.','Switch profiles to see each person’s reports and bookings.')),
      ...s.patients.map((p)=>ActionRow(Icons.person_outline,p.name,
        subtitle:p.relation=='self'?s.t('الملف الأساسي','Primary profile'):p.relation,
        onTap:()=>s.selectPatient(p.id),trailing:p.id==s.patientId?
          const Icon(Icons.check_circle,color:accent):const Icon(Icons.radio_button_unchecked))),
      const SizedBox(height:15),
      FilledButton.icon(onPressed:() async {
        final name=await prompt(context,s.t('اسم فرد العائلة التجريبي','Demo family member name'));
        if(name==null||!context.mounted)return;
        final relation=await prompt(context,s.t('صلة القرابة','Relationship'));
        if(relation!=null)s.addPatient(name,relation);
      },icon:const Icon(Icons.person_add_alt),label:Text(s.t('إضافة فرد للعائلة','Add family member'))),
      Note(s.t('الملفات هنا تجريبية. ربط ملفات البالغين يحتاج موافقتهم والتحقق من الهوية في النسخة الفعلية.',
        'These are demo profiles. Linking adult records requires consent and identity verification in the connected app.')),
    ]);
  }
}
class MedicalScreen extends StatelessWidget {
  const MedicalScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final fields=[('blood',s.t('فصيلة الدم','Blood group')),('allergies',s.t('الحساسيات','Allergies')),
      ('conditions',s.t('حالات مزمنة','Chronic conditions')),('medications',s.t('الأدوية الحالية','Current medications')),
      ('contact',s.t('جهة اتصال للطوارئ','Emergency contact'))];
    return DetailPage(title:s.t('المعلومات الصحية','Medical information'),children:[
      const PatientPicker(),const SizedBox(height:20),
      ...fields.map((e)=>ActionRow(Icons.edit_note,e.$2,
        subtitle:s.patient.medical[e.$1]??s.t('غير مضاف','Not entered'),onTap:() async {
          final patient=s.patient;
          final value=await prompt(context,e.$2,lines:2);
          if(value!=null){patient.medical[e.$1]=value;s.update();}
        })),
      Note(s.t('أدخل أمثلة وهمية فقط. هذه المعلومات غير محفوظة في ملف طبي فعلي.',
        'Enter fictional examples only. These details are not saved to a real medical record.')),
    ]);
  }
}
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('بطاقة الطوارئ','Emergency card'),children:[
      const PatientPicker(),const SizedBox(height:20),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Glyph(Icons.emergency_outlined,color:Color(0xFFB35E5D),size:65),
        const SizedBox(height:18),Heading(s.patient.name,subtitle:s.t('بطاقة تصميم تجريبية','Demo design card')),
        for(final e in [('blood',s.t('فصيلة الدم','Blood group')),('allergies',s.t('الحساسيات','Allergies')),
          ('conditions',s.t('الحالات','Conditions')),('contact',s.t('جهة الطوارئ','Emergency contact'))])
          Padding(padding:const EdgeInsets.only(bottom:15),child:Text(
            '${e.$2}: ${s.patient.medical[e.$1]??s.t('غير مضاف','Not entered')}')),
      ])),
      Note(s.t('لا تعتمد على بطاقة العرض في حالة طوارئ فعلية. لا توجد مكالمات طوارئ متصلة.',
        'Do not rely on this demo card in a real emergency. Emergency calling is not connected.')),
      OutlinedButton(onPressed:()=>go(context,const MedicalScreen()),child:Text(s.t('تعديل المعلومات','Edit information'))),
    ]);
  }
}
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('الإعدادات','Settings'),children:[
      Heading(s.t('على طريقتك','Make it yours'),subtitle:s.t('لغة العرض، المظهر، والتنبيهات.','Language, appearance and notifications.')),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        DropdownButtonFormField<bool>(value:s.arabic,decoration:InputDecoration(labelText:s.t('اللغة','Language')),
          items:const [DropdownMenuItem(value:true,child:Text('العربية')),DropdownMenuItem(value:false,child:Text('English'))],
          onChanged:(v){s.arabic=v!;s.update();}),
        const SizedBox(height:18),
        DropdownButtonFormField<ThemeMode>(value:s.themeMode,
          decoration:InputDecoration(labelText:s.t('المظهر','Appearance')),
          items:[DropdownMenuItem(value:ThemeMode.light,child:Text(s.t('فاتح','Light'))),
            DropdownMenuItem(value:ThemeMode.dark,child:Text(s.t('داكن','Dark'))),
            DropdownMenuItem(value:ThemeMode.system,child:Text(s.t('حسب الجهاز','System')))],
          onChanged:(v){s.themeMode=v!;s.update();}),
        const SizedBox(height:22),Text(s.t('حجم الخط','Text size')),
        Slider(value:s.textScale,min:1,max:1.4,divisions:4,label:'${(s.textScale*100).round()}%',
          onChanged:(v){s.textScale=v;s.update();}),
      ])),
      Section(s.t('تفضيلات الإشعارات','Notification preferences')),
      ...[('results',s.t('نتائج الفحوصات','Test results')),('bookings',s.t('الحجوزات','Appointments')),
        ('offers',s.t('العروض','Offers')),('biometric',s.t('بصمة الدخول — معاينة فقط','Biometric sign in — preview only'))]
        .map((e)=>SwitchListTile(value:s.preferences[e.$1]!,title:Text(e.$2),
          onChanged:(v){s.preferences[e.$1]=v;s.update();})),
      Note(s.t('تفضيلات الإشعارات والبصمة محاكاة؛ تحتاج ربط خدمات الجهاز. المظهر واللغة وحجم الخط تعمل في الواجهة.',
        'Notification and biometric preferences are simulated until device integration. Appearance, language and text size work in the UI.')),
      ActionRow(Icons.devices,s.t('الأجهزة والجلسات','Devices & sessions'),onTap:()=>go(context,const DevicesScreen())),
    ]);
  }
}
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('الخصوصية','Privacy'),children:[
      Heading(s.t('بياناتك، وقرارك','Your data. Your choice.'),
        subtitle:s.t('اختر ما تشاركه ومع من.','Choose what to share, and with whom.')),
      ...[('marketing',s.t('الموافقة على التسويق المخصص','Personalized marketing consent')),
        ('ai',s.t('الموافقة على تحليل التقارير بالمساعد','Assistant report analysis consent'))].map((e)=>
          SwitchListTile(value:s.preferences[e.$1]!,title:Text(e.$2),
            onChanged:(v){s.preferences[e.$1]=v;s.update();})),
      const Note('Demo: these choices do not send any data to third parties.'),
      ActionRow(Icons.share_outlined,s.t('صلاحيات مشاركة التقارير','Report sharing permissions'),
        onTap:()=>go(context,const SharingScreen())),
      ActionRow(Icons.policy_outlined,s.t('سياسة الخصوصية','Privacy policy'),onTap:()=>previewNotice(context,
        s.t('مسودة سياسة العرض','Demo policy draft'),
        s.t('النسخة الحالية تحفظ بيانات وهمية في ذاكرة الجلسة فقط. يلزم اعتماد سياسة الخصوصية والموافقات قبل الربط والإطلاق.',
          'This version holds fictional data in session memory only. Privacy terms and consent flows require approval before integration and launch.'))),
      ActionRow(Icons.download_outlined,s.t('طلب نسخة من البيانات','Request data export'),onTap:()=>previewNotice(context,
        s.t('طلب تصدير — معاينة','Export request — preview'),
        s.t('لا توجد بيانات على خادم لتصديرها حالياً. واجهة الطلب مخصصة لمرحلة الربط.',
          'There is no server data to export yet. This request interface is reserved for integration.'))),
      const SizedBox(height:14),
      OutlinedButton(onPressed:() async {
        if(await confirm(context,s.t('معاينة طلب حذف الحساب','Preview account deletion'),
          s.t('هذه معاينة لطلب الحذف فقط؛ لا يوجد حساب فعلي في النظام.',
            'This previews a deletion request only; there is no real account in the system.'))&&context.mounted) {
          toast(context,s.t('تمت معاينة الطلب. لم تُحذف أي بيانات فعلية.','Request previewed. No real data was deleted.'));
        }
      },child:Text(s.t('طلب حذف الحساب','Request account deletion'))),
    ]);
  }
}
class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key});
  @override State<SharingScreen> createState()=>_SharingScreenState();
}
class _SharingScreenState extends State<SharingScreen> {
  String scope='latest';
  int hours=24;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final grants=s.shares.where((g)=>g.patientId==s.patientId).toList();
    return DetailPage(title:s.t('مشاركة النتائج','Report sharing'),children:[
      Heading(s.t('موافقة واضحة، وقت محدد','Clear permission. Limited time.'),
        subtitle:s.t('معاينة صلاحيات المشاركة وإلغائها.','Preview sharing permissions and revocation.')),
      const PatientPicker(),const SizedBox(height:20),
      DropdownButtonFormField<String>(value:scope,decoration:InputDecoration(labelText:s.t('النتائج المسموح بها','Allowed reports')),
        items:[DropdownMenuItem(value:'latest',child:Text(s.t('آخر نتيجة جاهزة','Latest ready report'))),
          DropdownMenuItem(value:'cbc',child:Text(s.t('صورة الدم الكاملة','Blood count report'))),
          DropdownMenuItem(value:'all',child:Text(s.t('كل النتائج الجاهزة','All ready reports')))],
        onChanged:(v)=>setState(()=>scope=v!)),
      const SizedBox(height:16),
      DropdownButtonFormField<int>(value:hours,decoration:InputDecoration(labelText:s.t('مدة الإذن','Permission duration')),
        items:[1,24,168].map((v)=>DropdownMenuItem(value:v,child:Text(s.t('$v ساعة','$v hours')))).toList(),
        onChanged:(v)=>setState(()=>hours=v!)),
      const SizedBox(height:20),
      FilledButton.icon(onPressed:s.patientReports.where((r)=>r.ready).isEmpty?null:() async {
        final person=await prompt(context,s.t('اسم المستلم التجريبي','Demo recipient name'));
        if(person!=null){s.shares.add(ShareGrant(s.patientId,person,scope,DateTime.now().add(Duration(hours:hours))));s.update();}
      },icon:const Icon(Icons.add_link),label:Text(s.t('إنشاء إذن تجريبي','Create demo permission'))),
      Note(s.t('لا يُنشأ رابط عام ولا تُرسل تقارير. التحقق من هوية المستلم والتوكن الآمن يتبعان في مرحلة الربط.',
        'No public link is created and no reports are sent. Recipient verification and secure tokens belong to integration.')),
      Section(s.t('الأذونات','Permissions')),
      if(grants.isEmpty) EmptyState(s.t('لا توجد مشاركات','No sharing permissions'),
        s.t('تبقى النتائج ضمن ملفك في النموذج.','Reports stay within your demo profile.'),icon:Icons.lock_outline),
      ...grants.map((g)=>ActionRow(g.active?Icons.link:Icons.link_off,g.recipient,
        subtitle:'${g.scope} • ${dateLabel(g.expires)}',
        trailing:g.active?TextButton(onPressed:(){g.revoked=true;s.update();},child:Text(s.t('إلغاء','Revoke'))):
          Tag(s.t('غير فعال','Inactive'),color:amber))),
    ]);
  }
}
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('نقاط ومكافآت','Points & rewards'),children:[
      Panel(color:midnight,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Icon(Icons.workspace_premium_outlined,color:Color(0xFFEAC68C),size:45),
        const SizedBox(height:18),Text(s.t('ذهبي • حساب تجريبي','GOLD • DEMO ACCOUNT'),style:const TextStyle(color:Color(0xFFEAC68C))),
        const SizedBox(height:10),Text('${s.points}',style:const TextStyle(color:Colors.white,fontSize:48,fontWeight:FontWeight.w800)),
        Text(s.t('نقطة متاحة للاستبدال التجريبي','points available for demo redemption'),style:const TextStyle(color:Colors.white70)),
        const SizedBox(height:20),
        const LinearProgressIndicator(value:.7,backgroundColor:Colors.white12,color:Color(0xFFEAC68C),minHeight:6),
        const SizedBox(height:10),Text(s.t('مستوى العضوية للعرض؛ يُحدد نظام الترقية لاحقاً.','Illustrative tier; upgrade rules will be configured later.'),
          style:const TextStyle(color:Colors.white70,fontSize:11)),
      ])),
      Section(s.t('مستويات العضوية','Membership tiers')),
      Wrap(spacing:8,runSpacing:8,children:[
        Tag(s.t('برونزي','Bronze'),color:amber),Tag(s.t('فضي','Silver')),
        Tag(s.t('ذهبي','Gold'),color:amber),Tag(s.t('بلاتيني','Platinum')),
      ]),
      Section(s.t('مكافأة لك','A little thank you')),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(s.t('قسيمة تجريبية • 500 نقطة','Demo voucher • 500 points'),
          style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800)),
        const SizedBox(height:10),Text(s.t('تجربة استبدال النقاط، بدون قيمة مالية فعلية.',
          'Try the redemption flow. This has no real monetary value.')),
        const SizedBox(height:18),FilledButton(onPressed:s.points>=500?s.redeem:null,
          child:Text(s.t('استبدال 500 نقطة','Redeem 500 points'))),
      ])),
      Section(s.t('حركة النقاط','Points activity')),
      ActionRow(Icons.add_circle_outline,s.t('رصيد افتتاحي تجريبي','Demo opening balance'),trailing:const Text('+2,450')),
      ...s.rewards.map((code)=>ActionRow(Icons.redeem,code,subtitle:s.t('قسيمة تجريبية مستبدلة','Demo voucher redeemed'),trailing:const Text('−500'))),
      Note(s.t('النقاط المعلقة والانتهاء وقواعد الكسب تُدار في الخدمة الخلفية لاحقاً.',
        'Pending points, expiry and earning rules will be managed by the backend.')),
    ]);
  }
}
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('المحفظة والمدفوعات','Wallet & payments'),children:[
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Glyph(Icons.account_balance_wallet_outlined,size:60),
        const SizedBox(height:20),Text(s.t('رصيد توضيحي','Illustrative balance')),
        const SizedBox(height:8),Text(s.money(25000),style:const TextStyle(fontSize:36,fontWeight:FontWeight.w800)),
        const SizedBox(height:12),Tag(s.t('ليس رصيداً مالياً حقيقياً','NOT A REAL BALANCE')),
      ])),
      Section(s.t('ملخص الطلبات التجريبية','Demo order summaries')),
      if(s.bookings.isEmpty) EmptyState(s.t('لا توجد طلبات','No orders'),
        s.t('تظهر ملخصات الحجوزات هنا بعد إنشائها.','Booking summaries appear here after creation.')),
      ...s.bookings.map((b)=>ActionRow(Icons.receipt_long_outlined,b.id,
        subtitle:s.money(b.total),onTap:()=>go(context,BookingDetailScreen(b)),
        trailing:Tag(s.t('غير مدفوع','Unpaid'),color:amber))),
      Note(s.t('لم تُحفظ بطاقة دفع ولم يُخصم مبلغ. الإيصالات والمدفوعات والاسترداد المالي تحتاج مزود دفع فعلي.',
        'No card is stored or charged. Receipts, payments and refunds require a real payment provider.')),
    ]);
  }
}
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('المستندات والوصفات','Documents & prescriptions'),children:[
      Heading(s.t('أوراقك، بمكان واحد','Your documents, together')),
      FilledButton.icon(onPressed:() async {
        final title=await prompt(context,s.t('عنوان مستند تجريبي','Demo document title'));
        if(title!=null){s.documents.add(title);s.update();}
      },icon:const Icon(Icons.note_add_outlined),label:Text(s.t('إضافة عنوان مستند','Add a document title'))),
      Note(s.t('إضافة العنوان تعمل فقط؛ اختيار الملفات ورفعها وتخزينها غير متصل بعد.',
        'Only title entry is available; file picking, upload and storage are not connected yet.')),
      if(s.documents.isEmpty) EmptyState(s.t('لا توجد مستندات مضافة','No documents added'),
        s.t('ابدأ بعنوان مستند لعرض طريقة التنظيم.','Add a title to preview document organization.')),
      ...s.documents.asMap().entries.map((e)=>ActionRow(Icons.description_outlined,e.value,
        subtitle:s.t('عنوان تجريبي، بدون ملف مرفق','Demo title, no file attached'),
        trailing:IconButton(tooltip:s.t('حذف العنوان','Remove title'),onPressed:(){s.documents.removeAt(e.key);s.update();},
          icon:const Icon(Icons.delete_outline)))),
      Section(s.t('الوصفات الطبية','Prescriptions')),
      ActionRow(Icons.medication_outlined,s.t('معاينة الوصفة','Prescription preview'),
        subtitle:s.t('لا توجد أدوية أو جرعات موصوفة','No medications or doses prescribed'),
        onTap:()=>go(context,const PharmacyScreen())),
    ]);
  }
}
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('التذكيرات','Reminders'),children:[
      Heading(s.t('مساحة لما يهمك','Keep the important things close')),
      FilledButton.icon(onPressed:() async {
        final title=await prompt(context,s.t('عنوان التذكير','Reminder title'));
        if(title==null||!context.mounted)return;
        final date=await showDatePicker(context:context,initialDate:DateTime.now(),
          firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:365)));
        if(date==null||!context.mounted)return;
        final time=await showTimePicker(context:context,initialTime:const TimeOfDay(hour:9,minute:0));
        if(time==null)return;
        s.reminders.add(ReminderItem(title,DateTime(date.year,date.month,date.day,time.hour,time.minute)));s.update();
      },icon:const Icon(Icons.add_alarm),label:Text(s.t('تذكير جديد','New reminder'))),
      Note(s.t('القائمة تجريبية؛ لا تُرسل إشعارات مجدولة حالياً.','This list is a demo; scheduled notifications are not sent.')),
      ...s.reminders.map((r)=>CheckboxListTile(value:r.done,onChanged:(v){r.done=v!;s.update();},
        title:Text(r.title),subtitle:Text(dateLabel(r.date)))),
      if(s.reminders.isEmpty) EmptyState(s.t('لا توجد تذكيرات','No reminders'),
        s.t('أضف عنواناً وموعداً للتجربة.','Add a title and time to try the flow.'),icon:Icons.alarm_outlined),
    ]);
  }
}
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('الخط الزمني الصحي','Health timeline'),children:[
      const PatientPicker(),const SizedBox(height:20),
      ...s.patientReports.map((r)=>ActionRow(Icons.description_outlined,s.t(r.ar,r.en),
        subtitle:r.date,onTap:()=>go(context,ReportScreen(r)))),
      ...s.bookings.where((b)=>b.patientId==s.patientId).map(BookingCard.new),
      if(s.patientReports.isEmpty && !s.bookings.any((b)=>b.patientId==s.patientId))
        EmptyState(s.t('لا توجد أحداث بعد','No events yet'),s.t('ستظهر الزيارات والنتائج هنا.','Visits and reports will appear here.')),
    ]);
  }
}
class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('الأجهزة والجلسات','Devices & sessions'),children:[
      ActionRow(Icons.devices,s.t('جلسة العرض الحالية','Current demo session'),
        subtitle:s.t('لا يوجد تسجيل دخول فعلي','No real authentication'),trailing:Tag(s.t('حالي','Current'))),
      Note(s.t('قائمة الأجهزة وتسجيل الخروج عن بُعد تظهر بعد ربط المصادقة.',
        'Device lists and remote session revocation will be available after authentication integration.')),
    ]);
  }
}
