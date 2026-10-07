import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api.dart';
import 'store.dart';

const _teal = Color(0xFF087F69);
const _ink = Color(0xFF143C38);

class PatientMobileRoot extends StatefulWidget {
  const PatientMobileRoot({super.key, required this.baseUrl, this.store});
  final String baseUrl;
  final LinkedPatientStore? store;
  @override State<PatientMobileRoot> createState() => _PatientMobileRootState();
}
class _PatientMobileRootState extends State<PatientMobileRoot> {
  LinkedPatientStore? store;
  String? configurationError;
  int tab = 0;
  @override void initState() {
    super.initState();
    try {
      store = widget.store ?? LinkedPatientStore(PatientApi(widget.baseUrl), SecurePatientSessionVault(widget.baseUrl));
      store!.restore();
    } on PatientApiException catch (e) { configurationError = e.message; }
  }
  @override void dispose() { if (widget.store == null) store?.dispose(); super.dispose(); }
  Future<void> addProfile() => showDialog<void>(context:context,builder:(context)=>Dialog(
    insetPadding:const EdgeInsets.all(16),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:520),
      child:SingleChildScrollView(padding:const EdgeInsets.all(24),
        child:PatientLinkForm(store:store!,onLinked:()=>Navigator.pop(context))))));
  Future<void> logout() async {
    final yes = await showDialog<bool>(context:context,builder:(context)=>AlertDialog(
      title:const Text('تسجيل الخروج من هذا الملف؟'),
      content:const Text('للعودة إليه، خذ رمز ربط جديداً من بوابة المريض.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('تراجع')),
        FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('تسجيل الخروج'))]));
    if (yes == true) await store!.logout();
  }
  @override Widget build(BuildContext context) {
    if (configurationError != null) return Scaffold(body:Center(child:Padding(
      padding:const EdgeInsets.all(30),child:Text(configurationError!,textAlign:TextAlign.center))));
    final s = store!;
    return AnimatedBuilder(animation:s,builder:(context,_) {
      final linked = s.selected != null;
      return Scaffold(
        appBar:AppBar(title:const Text('Digital Lab',style:TextStyle(fontWeight:FontWeight.w800)),actions:[
          if (linked) IconButton(tooltip:'تحديث الملف',onPressed:s.loading?null:()=>s.select(s.selected!),icon:const Icon(Icons.refresh)),
          if (linked) IconButton(tooltip:'ربط ملف آخر',onPressed:s.loading?null:addProfile,icon:const Icon(Icons.add_link)),
          if (linked) IconButton(tooltip:'تسجيل الخروج',onPressed:s.loading?null:logout,icon:const Icon(Icons.logout)),
        ]),
        body:SafeArea(child:s.restoring ? const Center(child:CircularProgressIndicator())
          : Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:820),child:ListView(
            padding:const EdgeInsets.fromLTRB(20,12,20,30),children:[
              if (s.error != null) _Message(s.error!,error:true),
              if (s.profiles.length > 1 || (!linked && s.profiles.isNotEmpty)) ...[
                DropdownButtonFormField<String>(
                  initialValue:s.selected?.key,isExpanded:true,
                  decoration:const InputDecoration(labelText:'ملفاتك المرتبطة'),
                  items:s.profiles.map((p)=>DropdownMenuItem(value:p.key,
                    child:Text(p.name+' · '+p.labName,maxLines:1,overflow:TextOverflow.ellipsis))).toList(),
                  onChanged:s.loading?null:(key) { if(key!=null) s.select(s.profiles.firstWhere((p)=>p.key==key)); }),
                const SizedBox(height:18),
              ],
              if (!linked) PatientLinkForm(store:s)
              else if (s.loading) const Padding(padding:EdgeInsets.all(64),child:Center(child:CircularProgressIndicator()))
              else if (s.overview == null) _Empty(icon:Icons.cloud_off,title:'تعذر تحميل الملف',
                action:FilledButton(onPressed:()=>s.select(s.selected!),child:const Text('إعادة المحاولة')))
              else ...[
                if (tab == 0) ..._home(s),
                if (tab == 1) ..._reports(s),
                if (tab == 2) ..._points(s),
              ],
            ])))),
        bottomNavigationBar:linked ? NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),
          destinations:const [
            NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),label:'ملفي'),
            NavigationDestination(icon:Icon(Icons.description_outlined),label:'تقاريري'),
            NavigationDestination(icon:Icon(Icons.workspace_premium_outlined),label:'نقاطي'),
          ]) : null,
      );
    });
  }

  List<Widget> _home(LinkedPatientStore s) {
    final patient = s.overview!['patient'] as Map, lab = s.overview!['lab'] as Map;
    final loyalty = s.overview!['loyalty'] as Map;
    return [
      _Surface(color:_ink,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Icon(Icons.health_and_safety_outlined,color:Color(0xFF82EAC9),size:38),
        const SizedBox(height:18),
        const Text('أهلاً بك، هذا ملفك الصحي',style:TextStyle(color:Colors.white70)),
        const SizedBox(height:7),Text(_string(patient['name']),
          style:const TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.w800)),
        const SizedBox(height:12),Text('رقم الملف: '+_string(patient['code']),style:const TextStyle(color:Colors.white70)),
      ])),
      const SizedBox(height:18),
      _Surface(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('مختبرك',style:TextStyle(color:_teal,fontWeight:FontWeight.w700)),
        const SizedBox(height:8),Text(_string(lab['name']),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),
        if (_string(lab['address'])!='—') Padding(padding:const EdgeInsets.only(top:10),child:Text(_string(lab['address']))),
        if (_string(lab['phone'])!='—') Padding(padding:const EdgeInsets.only(top:8),child:Text(_string(lab['phone']),textDirection:TextDirection.ltr)),
      ])),
      const SizedBox(height:18),
      _Surface(color:const Color(0xFFE7F8F0),child:Row(children:[
        const Icon(Icons.stars_rounded,color:_teal,size:44),const SizedBox(width:16),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('رصيد نقاطك في هذا المختبر'),const SizedBox(height:5),
          Text(_string(loyalty['balance'])+' نقطة',style:const TextStyle(color:_ink,fontSize:27,fontWeight:FontWeight.w900)),
          Text(_string(loyalty['tier']?['label_ar']),style:const TextStyle(color:_teal)),
        ])),
      ])),
      const SizedBox(height:22),_Title('بيانات ملفك'),
      _Surface(child:Column(children:[
        _Field('رقم الهاتف',_string(patient['phone'])),
        if(patient['dob']!=null) _Field('تاريخ الميلاد',_string(patient['dob'])),
        if(patient['gender']!=null) _Field('الجنس',_string(patient['gender'])),
      ])),
      const SizedBox(height:22),_Title('أحدث التقارير'),
      if(s.reports.isEmpty) const _Empty(icon:Icons.folder_open,title:'لا توجد تقارير مسجلة لهذا الملف بعد.'),
      ...s.reports.take(3).map((r)=>_reportCard(s,r)),
      if(s.reports.length>3 || s.nextReports!=null) TextButton(
        onPressed:()=>setState(()=>tab=1),child:const Text('عرض جميع التقارير')),
    ];
  }
  List<Widget> _reports(LinkedPatientStore s) => [
    _Title('تقاريرك ونتائجك'),
    Text(s.selected!.labName,style:const TextStyle(color:_teal)),
    const SizedBox(height:16),
    if(s.reports.isEmpty) const _Empty(icon:Icons.description_outlined,title:'لا توجد تقارير لهذا الملف بعد.'),
    ...s.reports.map((r)=>_reportCard(s,r)),
    if(s.nextReports!=null) OutlinedButton(onPressed:s.paging?null:()=>s.more(),
      child:Text(s.paging?'جاري التحميل…':'تحميل تقارير أقدم')),
  ];
  Widget _reportCard(LinkedPatientStore s,Map<String,dynamic> report) {
    final ready = report['status']=='ready';
    final tests = (report['tests'] as List? ?? []).map((t)=>_string(t['name'])).join(' • ');
    return Padding(padding:const EdgeInsets.only(bottom:14),child:_Surface(child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.article_outlined,color:_teal),const SizedBox(width:10),
        Expanded(child:Text('تقرير #'+_string(report['id']),style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))),
        Chip(label:Text(ready?'جاهز':'قيد الإجراء',style:TextStyle(fontSize:11,color:ready?_teal:const Color(0xFF855C17))),
          backgroundColor:ready?const Color(0xFFE6F7EF):const Color(0xFFFFF2D7),side:BorderSide.none),
      ]),
      Text(_date(report['date']),style:const TextStyle(color:Colors.grey,fontSize:12)),
      const SizedBox(height:12),if(tests.isNotEmpty) Text(tests,style:const TextStyle(fontWeight:FontWeight.w600,height:1.7)),
      if(report['result_date']!=null) Padding(padding:const EdgeInsets.only(top:8),child:Text('موعد النتائج: '+_date(report['result_date']))),
      const Divider(height:28),
      Wrap(spacing:24,runSpacing:12,children:[
        _Amount('الإجمالي',report['total']),_Amount('المدفوع',report['paid']),_Amount('المتبقي',report['due']),
      ]),
      const SizedBox(height:16),
      SizedBox(width:double.infinity,child:FilledButton.icon(
        key:ValueKey('patient-report-open-'+report['id'].toString()),
        onPressed:ready?()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>LinkedReportScreen(
          api:s.api,profile:s.selected!,reportId:(report['id'] as num).toInt()))):null,
        icon:Icon(ready?Icons.description_outlined:Icons.hourglass_empty,size:19),
        label:Text(ready?'عرض النتائج':'بانتظار اعتماد التقرير'))),
    ])));
  }
  List<Widget> _points(LinkedPatientStore s) {
    final points=s.overview!['loyalty'] as Map;
    final next=points['next_tier'] as Map?;
    final current=(points['yearly_points'] as num?)?.toDouble()??0;
    final from=(points['tier']?['min_yearly_points'] as num?)?.toDouble()??0;
    final to=(next?['min_yearly_points'] as num?)?.toDouble()??current;
    final progress=next==null?1.0:((current-from)/(to-from==0?1:to-from)).clamp(0.0,1.0);
    return [
      _Title('ولاؤك له قيمة'),
      Text(s.selected!.labName,style:const TextStyle(color:_teal)),const SizedBox(height:18),
      _Surface(color:_ink,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Icon(Icons.workspace_premium,color:Color(0xFFEAC68C),size:40),
        const SizedBox(height:12),const Text('رصيد نقاطك',style:TextStyle(color:Colors.white70)),
        Text(_string(points['balance']),style:const TextStyle(color:Colors.white,fontSize:46,fontWeight:FontWeight.w900)),
        Text(_string(points['tier']?['label_ar']),style:const TextStyle(color:Color(0xFFEAC68C))),
        const SizedBox(height:20),LinearProgressIndicator(value:progress,color:const Color(0xFF82EAC9),backgroundColor:Colors.white12),
        const SizedBox(height:10),Text(next==null?'أعلى مستوى عضوية':'المستوى التالي: '+_string(next['label_ar']),
          style:const TextStyle(color:Colors.white70,fontSize:12)),
      ])),
      if(points['enabled']==false) const _Message('برنامج الولاء متوقف حالياً لدى المختبر؛ الرصيد المعروض هو المسجل في ملفك.'),
      const SizedBox(height:22),_Title('المكافآت لدى المختبر'),
      ...((points['catalog'] as List?)??[]).map((item)=>Padding(padding:const EdgeInsets.only(bottom:10),
        child:_Surface(child:Row(children:[const Icon(Icons.redeem,color:_teal),const SizedBox(width:12),
          Expanded(child:Text(_string(item['label_ar']))),Text(_string(item['points'])+' نقطة')])))),
      const _Message('يمكنك طلب استبدال المكافآت من المختبر.'),
      const SizedBox(height:20),_Title('حركة النقاط'),
      if(s.ledger.isEmpty) const _Empty(icon:Icons.history,title:'لا توجد حركات نقاط مسجلة بعد.'),
      ...s.ledger.map((item)=>Padding(padding:const EdgeInsets.only(bottom:10),child:_Surface(
        child:Row(children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(_string(item['description']),style:const TextStyle(fontWeight:FontWeight.w700)),
            const SizedBox(height:6),Text(_date(item['created_at']),style:const TextStyle(fontSize:12,color:Colors.grey)),
          ])),const SizedBox(width:12),Text(_string(item['points']),textDirection:TextDirection.ltr,
            style:TextStyle(fontWeight:FontWeight.w800,color:(item['points'] as num)<0?Colors.deepOrange:_teal)),
        ])))),
      if(s.nextPoints!=null) OutlinedButton(onPressed:s.paging?null:()=>s.more(points:true),
        child:Text(s.paging?'جاري التحميل…':'تحميل حركات أقدم')),
    ];
  }
}

class PatientLinkForm extends StatefulWidget {
  const PatientLinkForm({super.key,required this.store,this.onLinked});
  final LinkedPatientStore store;
  final VoidCallback? onLinked;
  @override State<PatientLinkForm> createState()=>_PatientLinkFormState();
}
class _PatientLinkFormState extends State<PatientLinkForm> {
  final phone=TextEditingController(),code=TextEditingController(),form=GlobalKey<FormState>();
  bool busy=false;
  String? error;
  @override void dispose(){phone.dispose();code.dispose();super.dispose();}
  Future<void> submit() async {
    if(busy || !form.currentState!.validate()) return;
    setState((){busy=true;error=null;});
    try {
      await widget.store.link(normalizePatientPhone(phone.text)!,normalizePairingCode(code.text));
      if(!mounted) return;
      code.clear(); widget.onLinked?.call();
    } on PatientApiException catch(e) { if(mounted) setState(()=>error=e.message); }
    finally { if(mounted) setState(()=>busy=false); }
  }
  @override Widget build(BuildContext context)=>AutofillGroup(child:Form(key:form,child:Column(
    crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const SizedBox(height:16),
      const Align(alignment:Alignment.centerRight,child:CircleAvatar(radius:34,backgroundColor:Color(0xFFE1F6EC),
        child:Icon(Icons.link_rounded,size:36,color:_teal))),
      const SizedBox(height:24),
      const Text('تقاريرك أقرب إليك',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:_ink)),
      const SizedBox(height:10),
      const Text('اربط ملفك من بوابة المريض، وتابع نتائجك ونقاطك في مكان واحد.',style:TextStyle(height:1.8,fontSize:15)),
      const SizedBox(height:22),
      const _Message('افتح بوابة المريض ← اضغط «إنشاء رمز ربط التطبيق» ← أدخل الرمز هنا.'),
      const SizedBox(height:18),
      TextFormField(key:const ValueKey('patient-phone'),controller:phone,enabled:!busy,
        keyboardType:TextInputType.phone,textDirection:TextDirection.ltr,autofillHints:const [AutofillHints.telephoneNumber],
        decoration:const InputDecoration(labelText:'رقم الهاتف المسجل لدى المختبر',hintText:'07xx xxx xxxx',prefixIcon:Icon(Icons.phone_outlined)),
        validator:(v)=>normalizePatientPhone(v??'')==null?'أدخل رقم هاتف عراقي صحيحاً.':null),
      const SizedBox(height:16),
      TextFormField(key:const ValueKey('patient-pairing-code'),controller:code,enabled:!busy,
        keyboardType:TextInputType.number,textDirection:TextDirection.ltr,enableSuggestions:false,autocorrect:false,
        decoration:const InputDecoration(labelText:'رمز الربط من بوابة المريض',hintText:'0000 0000 0000',prefixIcon:Icon(Icons.key_outlined)),
        validator:(v)=>RegExp(r'^\d{12}$').hasMatch(normalizePairingCode(v??''))?null:'أدخل رمز الربط المكوّن من 12 رقماً.',
        onFieldSubmitted:(_)=>submit()),
      if(error!=null) Padding(padding:const EdgeInsets.only(top:12),child:_Message(error!,error:true)),
      const SizedBox(height:22),
      FilledButton.icon(key:const ValueKey('patient-link-submit'),onPressed:busy?null:submit,
        icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.arrow_forward),
        label:Text(busy?'جاري ربط ملفك…':'ربط ملفي وعرض النتائج')),
      const SizedBox(height:16),
      const Text('الرمز صالح لمدة قصيرة ويُستخدم مرة واحدة. إذا انتهى، أنشئ رمزاً جديداً من بوابتك.',
        style:TextStyle(fontSize:12,height:1.8,color:Colors.grey)),
      if(kIsWeb) const Padding(padding:EdgeInsets.only(top:12),
        child:Text('في نسخة المتصفح، يستمر الربط أثناء فتح الصفحة فقط.',style:TextStyle(fontSize:12,color:Colors.grey))),
    ])));
}

class LinkedReportScreen extends StatefulWidget {
  const LinkedReportScreen({super.key,required this.api,required this.profile,required this.reportId});
  final PatientApi api;
  final LinkedPatient profile;
  final int reportId;
  @override State<LinkedReportScreen> createState()=>_LinkedReportScreenState();
}
class _LinkedReportScreenState extends State<LinkedReportScreen> {
  late Future<Map<String,dynamic>> future;
  @override void initState(){super.initState();future=load();}
  Future<Map<String,dynamic>> load()=>widget.api.call('GET','reports/'+widget.reportId.toString(),token:widget.profile.token);
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('تفاصيل النتائج')),
    body:FutureBuilder<Map<String,dynamic>>(future:future,builder:(context,snapshot){
      if(snapshot.connectionState!=ConnectionState.done) return const Center(child:CircularProgressIndicator());
      if(snapshot.hasError) return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
        _Message(snapshot.error is PatientApiException?(snapshot.error as PatientApiException).message:'تعذر تحميل التقرير.',error:true),
        const SizedBox(height:16),OutlinedButton(onPressed:()=>setState(()=>future=load()),child:const Text('إعادة المحاولة')),
      ])));
      final data=snapshot.data!,report=data['report'] as Map;
      return Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:820),child:ListView(
        padding:const EdgeInsets.all(20),children:[
          _Title(widget.profile.name),Text(widget.profile.labName,style:const TextStyle(color:_teal,fontSize:17)),
          const SizedBox(height:8),Text('تقرير #'+widget.reportId.toString()+' · '+_date(report['date'])),
          const SizedBox(height:22),
          ...(data['sections'] as List).map((section)=>Padding(padding:const EdgeInsets.only(bottom:18),
            child:_Surface(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
              Text(_string(section['name']),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:20)),
              ...((section['items'] as List?)??[]).map((item)=>_Measurement(item:Map<String,dynamic>.from(item))),
            ])))),
        ])));
    }));
}
class _Measurement extends StatelessWidget {
  const _Measurement({required this.item});
  final Map<String,dynamic> item;
  @override Widget build(BuildContext context) {
    final ranges=(item['ranges'] as List?)??[],parts=(item['parts'] as List?)??[];
    return Padding(padding:const EdgeInsets.only(top:16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Divider(),Text(_string(item['name']),style:const TextStyle(fontWeight:FontWeight.w700)),
      const SizedBox(height:8),
      if(_string(item['value'])!='—') SelectableText(_string(item['value'])+' '+(_string(item['unit'])=='—'?'':_string(item['unit'])),
        textDirection:TextDirection.ltr,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:_ink)),
      if(ranges.isNotEmpty) Padding(padding:const EdgeInsets.only(top:8),
        child:Text('Reference range: '+ranges.map(_range).where((v)=>v.isNotEmpty).join(' | '),textDirection:TextDirection.ltr,
          style:const TextStyle(fontSize:12,color:Colors.grey,height:1.7))),
      if(_string(item['comment'])!='—') Padding(padding:const EdgeInsets.only(top:10),child:Text(_string(item['comment']))),
      ...parts.map((part)=>_Measurement(item:Map<String,dynamic>.from(part))),
    ]));
  }
}
String _range(dynamic value) {
  if(value is! Map) return _string(value);
  const labels={'from':'From','to':'To','notes':'Note','gender':'Gender','age_from':'Age from',
    'age_to':'Age to','age_unit':'Age unit','test_reference_options':'Options','selection_type_options':'Options'};
  return value.entries.where((e)=>e.value!=null && e.value.toString().isNotEmpty)
    .map((e)=>(labels[e.key]??e.key.toString())+': '+e.value.toString()).join(' · ');
}
String _string(dynamic value)=>value==null||value.toString().trim().isEmpty?'—':value.toString();
String _date(dynamic value) {
  final date=DateTime.tryParse(value?.toString()??'');
  return date==null?'—':date.toLocal().toIso8601String().substring(0,10);
}
class _Surface extends StatelessWidget {
  const _Surface({required this.child,this.color=Colors.white});
  final Widget child;final Color color;
  @override Widget build(BuildContext context)=>Container(width:double.infinity,padding:const EdgeInsets.all(20),
    decoration:BoxDecoration(color:color,borderRadius:BorderRadius.circular(22),
      border:Border.all(color:const Color(0xFFE0ECE7))),child:child);
}
class _Title extends StatelessWidget {
  const _Title(this.value);final String value;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:12),
    child:Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)));
}
class _Message extends StatelessWidget {
  const _Message(this.value,{this.error=false});final String value;final bool error;
  @override Widget build(BuildContext context)=>Container(width:double.infinity,padding:const EdgeInsets.all(14),
    margin:const EdgeInsets.symmetric(vertical:6),decoration:BoxDecoration(
      color:error?const Color(0xFFFFEFF0):const Color(0xFFEAF5F1),borderRadius:BorderRadius.circular(12)),
    child:Text(value,style:TextStyle(color:error?const Color(0xFF9B2440):_ink,fontSize:13,height:1.8)));
}
class _Field extends StatelessWidget {
  const _Field(this.label,this.value);final String label,value;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:8),
    child:Wrap(spacing:20,runSpacing:6,children:[Text(label,style:const TextStyle(color:Colors.grey)),Text(value)]));
}
class _Amount extends StatelessWidget {
  const _Amount(this.label,this.value);final String label;final dynamic value;
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(label,style:const TextStyle(fontSize:11,color:Colors.grey)),const SizedBox(height:4),
    Text(_string(value)+' د.ع',style:const TextStyle(fontWeight:FontWeight.w700,fontSize:13)),
  ]);
}
class _Empty extends StatelessWidget {
  const _Empty({required this.icon,required this.title,this.action});final IconData icon;final String title;final Widget? action;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:28),
    child:Column(children:[Icon(icon,size:45,color:_teal),const SizedBox(height:16),Text(title,textAlign:TextAlign.center),
      if(action!=null) Padding(padding:const EdgeInsets.only(top:16),child:action)]));
}
