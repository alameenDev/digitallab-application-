part of '../main.dart';

class ExperienceHome extends StatelessWidget {
  const ExperienceHome({super.key,required this.onTab});
  final ValueChanged<int> onTab;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final visits=s.bookings.where((b)=>b.patientId==s.patientId&&b.status=='upcoming').toList()
      ..sort((a,b)=>a.date.compareTo(b.date));
    return ScreenBody(children:[
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s.t('أهلاً، ${s.patient.name.split(' ').first}','Hello, ${s.patient.name.split(' ').first}'),
            style:const TextStyle(fontWeight:FontWeight.w800,fontSize:25)),
          const SizedBox(height:5),Text(s.t('رعايتك تبدأ من هنا.','Your care starts here.'),
            style:TextStyle(fontSize:13,color:muted(context))),
        ])),
        ActionChip(avatar:const Icon(Icons.people_outline,size:17),
          label:Text(s.t('عائلتي','My family')),onPressed:()=>go(context,const FamilyHub())),
      ]),
      const SizedBox(height:20),
      const CampaignCarousel(),
      const SizedBox(height:8),
      const StoryStrip(),
      const SectionGap(),
      CareSummary(onResults:()=>onTab(1),onBookings:()=>onTab(3)),
      Section(s.t('كل خدماتك، أقرب','Your everyday care'),action:s.t('اكتشف الكل','Explore all'),onTap:()=>onTab(2)),
      TileGrid(children:[
        FeatureTile(Icons.biotech,s.t('باقات الفحوصات','Test packages'),
          s.t('تصفّح وقارن قبل الحجز','Browse, compare, then book'),
          onTap:()=>go(context,const ExploreScreen(standalone:true))),
        FeatureTile(Icons.medical_services_outlined,s.t('الأطباء','Doctors'),
          s.t('حضوري أو عن بُعد','In person or online'),
          onTap:()=>go(context,const ExploreScreen(initialKind:'doctors',standalone:true))),
        FeatureTile(Icons.home_outlined,s.t('فحوصات بالبيت','Care at home'),
          s.t('اختر الموعد، وتابع العينة','Choose a time, track the sample'),
          onTap:()=>go(context,const HomeCollectionHub())),
        FeatureTile(Icons.medication_outlined,s.t('الصيدلية','Pharmacy'),
          s.t('الوصفات والطلبات','Prescriptions and requests'),color:amber,
          onTap:()=>go(context,const PharmacyScreen())),
      ]),
      Section(s.t('تجربة تختلف، لأنك تستحق','A little more personal')),
      Panel(onTap:()=>go(context,const PackageComparisonScreen()),
        child:Row(children:[
          const Glyph(Icons.compare_arrows,size:58,color:Color(0xFF7862A4)),
          const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(s.t('قارن. اختَر. اطمئن.','Compare. Choose. Feel clear.'),
              style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
            const SizedBox(height:6),Text(s.t('السعر، عدد الفحوصات والمختبر بجدول واحد.',
              'Price, test count and laboratory, side by side.'),
              style:TextStyle(color:muted(context),fontSize:12,height:1.7)),
          ])),const SizedBox(width:8),const Icon(Icons.arrow_outward,color:accent,size:18),
        ])),
      const SizedBox(height:12),
      TileGrid(minWidth:240,children:[
        FeatureTile(Icons.checklist_rtl,s.t('خطة العناية','Care planner'),
          s.t('نتائج، أسئلة، وخطوات قبل الزيارة','Reports, questions and visit preparation'),
          onTap:()=>go(context,const CarePlanScreen())),
        FeatureTile(Icons.people_alt_outlined,s.t('عائلتك بنظرة واحدة','Your family at a glance'),
          s.t('ملف ونتائج ومواعيد لكل فرد','Profiles, reports and visits for each person'),
          onTap:()=>go(context,const FamilyHub()),color:Color(0xFF7862A4)),
      ]),
      if(visits.isNotEmpty) ...[
        Section(s.t('موعدك القادم','Your next visit')),
        BookingCard(visits.first),
      ],
      Section(s.t('اهتمامك يرجع لك','Your care comes full circle')),
      const LoyaltyTeaser(),
      Section(s.t('باقات تستحق المقارنة','Worth a closer look'),
        action:s.t('قارن الباقات','Compare packages'),onTap:()=>go(context,const PackageComparisonScreen())),
      TileGrid(minWidth:260,children:services.where((e)=>e.kind=='packages').take(2).map(ServiceCard.new).toList()),
      Panel(onTap:()=>go(context,const AssistantScreen()),child:Row(children:[
        const Glyph(Icons.auto_awesome_outlined,color:Color(0xFF7862A4),size:56),
        const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s.t('اسأل عن تجربتك','Ask about your experience'),
            style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
          const SizedBox(height:5),Text(s.t('معاينة المساعد الصحي • بدون تحليل طبي متصل',
            'Assistant preview • No connected medical analysis'),
            style:TextStyle(color:muted(context),fontSize:12)),
        ])),
      ])),
    ]);
  }
}
class SectionGap extends StatelessWidget {
  const SectionGap({super.key});
  @override Widget build(BuildContext context)=>const SizedBox(height:20);
}

class CampaignCarousel extends StatefulWidget {
  const CampaignCarousel({super.key,this.autoplay=true});
  final bool autoplay;
  @override State<CampaignCarousel> createState()=>_CampaignCarouselState();
}
class _CampaignCarouselState extends State<CampaignCarousel> {
  final controller=PageController();
  Timer? timer;
  int current=0;
  bool paused=false;
  @override void initState() {
    super.initState();
    if(widget.autoplay)timer=Timer.periodic(const Duration(seconds:7),(_){
      if(!mounted||paused||!controller.hasClients)return;
      final media=MediaQuery.of(context);
      if(media.disableAnimations||media.accessibleNavigation||ModalRoute.of(context)?.isCurrent!=true)return;
      controller.animateToPage((current+1)%3,duration:const Duration(milliseconds:450),curve:Curves.easeInOutCubic);
    });
  }
  @override void dispose(){timer?.cancel();controller.dispose();super.dispose();}
  void select(int i) {
    setState(()=>paused=true);
    if(MediaQuery.of(context).disableAnimations){controller.jumpToPage(i);}
    else{controller.animateToPage(i,duration:const Duration(milliseconds:280),curve:Curves.easeOut);}
  }
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return Column(children:[
      LayoutBuilder(builder:(context,c)=>SizedBox(height:campaignHeight(context,c.maxWidth),child:Listener(
        onPointerDown:(_){if(!paused)setState(()=>paused=true);},
        child:PageView.builder(key:const ValueKey('campaign-carousel'),controller:controller,itemCount:3,
          onPageChanged:(i)=>setState(()=>current=i),itemBuilder:(context,i)=>CampaignCard(index:i))))),
      Row(children:[
        Expanded(child:Text(s.t('مختارات Digital Lab','DIGITAL LAB EDIT'),maxLines:1,overflow:TextOverflow.ellipsis,
          style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,letterSpacing:s.arabic?0:1.2,color:muted(context)))),
        for(var i=0;i<3;i++) Semantics(selected:i==current,child:IconButton(
          key:ValueKey('campaign-dot-$i'),tooltip:s.t('عرض البانر ${i+1}','Show banner ${i+1}'),
          constraints:const BoxConstraints(minWidth:40,minHeight:44),
          onPressed:()=>select(i),icon:AnimatedContainer(duration:const Duration(milliseconds:180),
            width:i==current?21:6,height:6,
            decoration:BoxDecoration(color:i==current?accent:accent.withAlpha(45),
              borderRadius:BorderRadius.circular(8))))),
        IconButton(tooltip:paused?s.t('تشغيل البانرات تلقائياً','Play banners'):s.t('إيقاف حركة البانرات','Pause banners'),
          onPressed:()=>setState(()=>paused=!paused),icon:Icon(paused?Icons.play_arrow_rounded:Icons.pause_rounded,size:17)),
      ]),
    ]);
  }
}
List<String> campaignCopy(AppStore s,int index) {
    final labels=[s.t('رعاية توصل لبابك','CARE AT YOUR DOOR'),s.t('لأن العائلة أولاً','FAMILY COMES FIRST'),s.t('مكافآت تستاهلها','A LITTLE THANK YOU')];
    final titles=[s.t('مختبرك،\nلحد باب بيتك.','Your lab.\nAt your doorstep.'),
      s.t('صحتهم تهمك.\nخلّها قريبة.','Their health.\nCloser to you.'),
      s.t('اهتمامك إلك،\nومكافأته هم إلك.','Care for you.\nRewards for you.')];
    final desc=[s.t('موعد على راحتك، ومتابعة بكل خطوة.','Your time. Your place. Every step in view.'),
      s.t('نتائج ومواعيد عائلتك، بملفات مستقلة.','Your family’s reports and visits, organized.'),
      s.t('${s.points} نقطة تنتظر اختيارك.','${s.points} points. Choose a little extra.')];
    final ctas=[s.t('اكتشف السحب المنزلي','Explore home collection'),
      s.t('افتح مساحة العائلة','Open family space'),s.t('اكتشف مكافآتك','Explore your rewards')];

  return [labels[index],titles[index],desc[index],ctas[index]];
}
double campaignHeight(BuildContext context,double width) {
  final s=AppScope.of(context);
  final available=width-40-math.min(width*.34,210.0);
  final scaler=MediaQuery.textScalerOf(context);
  double measure(String value,TextStyle style,double maxWidth) {
    final painter=TextPainter(text:TextSpan(text:value,
      style:DefaultTextStyle.of(context).style.merge(style)),
      textDirection:Directionality.of(context),textScaler:scaler)..layout(maxWidth:maxWidth);
    final height=painter.height;painter.dispose();return height;
  }
  double height=260;
  for(var i=0;i<3;i++){
    final copy=campaignCopy(s,i);
    final textHeight=measure(copy[0],const TextStyle(fontSize:10,fontWeight:FontWeight.w800),available)
      +measure(copy[1],const TextStyle(fontSize:25,fontWeight:FontWeight.w900,height:1.3),available)
      +measure(copy[2],const TextStyle(fontSize:12,height:1.6),available)
      +math.max(42,measure(copy[3],const TextStyle(fontSize:11,fontWeight:FontWeight.w800),available-24)+20);
    height=math.max(height,textHeight+90);
  }
  return height;
}
class CampaignCard extends StatelessWidget {
  const CampaignCard({super.key,required this.index});
  final int index;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final colors=[const Color(0xFFDEF2E9),const Color(0xFFEEE8F7),const Color(0xFFFFEDCF)];
    final copy=campaignCopy(s,index);
    void open(){
      go(context,index==0?const HomeCollectionHub():index==1?const FamilyHub():const RewardsScreen());
    }
    return Container(key:ValueKey('campaign-card-$index'),clipBehavior:Clip.antiAlias,
      decoration:BoxDecoration(color:colors[index],borderRadius:BorderRadius.circular(25)),
      child:Stack(children:[
        PositionedDirectional(end:-40,bottom:-45,child:Container(width:220,height:220,
          decoration:BoxDecoration(shape:BoxShape.circle,color:Colors.white.withAlpha(100)))),
        LayoutBuilder(builder:(context,c){
          final artWidth=math.min(c.maxWidth*.34,210.0);
          return Padding(padding:const EdgeInsets.all(20),child:Row(children:[
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
              Text(copy[0],style:const TextStyle(color:accent,fontSize:10,fontWeight:FontWeight.w800)),
              const SizedBox(height:10),
              Text(copy[1],style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900,height:1.3,color:midnight)),
              const SizedBox(height:10),
              Text(copy[2],style:const TextStyle(fontSize:12,color:Color(0xFF3E5D66),height:1.6)),
              const SizedBox(height:16),
              FilledButton(key:ValueKey('campaign-open-$index'),onPressed:open,
                style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:12),
                  minimumSize:const Size(40,42),textStyle:const TextStyle(fontSize:11,fontWeight:FontWeight.w800)),
                child:Text(copy[3],textAlign:TextAlign.center)),
            ])),
            SizedBox(width:artWidth,child:ExcludeSemantics(child:AspectRatio(aspectRatio:.8,
              child:CustomPaint(painter:CareArtwork(index))))),
          ]));
        }),
      ]));
  }
}
class CareArtwork extends CustomPainter {
  CareArtwork(this.scene);
  final int scene;
  @override void paint(Canvas canvas,Size size) {
    canvas.save();canvas.scale(size.width/200,size.height/250);
    void rounded(double x,double y,double w,double h,double r,Color color){
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h),Radius.circular(r)),Paint()..color=color);
    }
    final shadow=Paint()..color=midnight.withAlpha(22)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8);
    canvas.drawOval(const Rect.fromLTWH(22,215,160,17),shadow);
    canvas.drawCircle(const Offset(108,120),82,Paint()..color=Colors.white.withAlpha(75));
    if(scene==0) {
      rounded(57,90,70,38,14,const Color(0xFF3B8C81));
      rounded(65,98,54,23,9,const Color(0xFFDEF2E9));
      final rect=RRect.fromRectAndRadius(const Rect.fromLTWH(30,112,145,99),const Radius.circular(22));
      canvas.drawRRect(rect,Paint()..shader=const LinearGradient(
        colors:[Colors.white,Color(0xFFD1E6DF)],begin:Alignment.topLeft,end:Alignment.bottomRight).createShader(rect.outerRect));
      rounded(90,136,23,52,5,accent);rounded(75,151,53,22,5,accent);
      canvas.save();canvas.translate(45,70);canvas.rotate(-.23);
      rounded(-11,0,24,77,10,Colors.white);
      rounded(-8,36,18,38,7,const Color(0xFFB1D4D5));
      rounded(-15,-5,32,19,5,const Color(0xFFF1BDA3));canvas.restore();
      canvas.save();canvas.translate(145,63);canvas.rotate(.2);
      rounded(-11,0,24,87,10,Colors.white);
      rounded(-8,48,18,35,7,const Color(0xFF7CBDB0));
      rounded(-15,-5,32,19,5,accent);canvas.restore();
      rounded(139,169,50,45,13,midnight);
      final p=Paint()..color=const Color(0xFFBDECD6)..strokeWidth=3..strokeCap=StrokeCap.round;
      canvas.drawLine(const Offset(152,190),const Offset(160,197),p);
      canvas.drawLine(const Offset(160,197),const Offset(178,180),p);
    } else if(scene==1) {
      void person(double x,double y,double r,Color shirt,Color skin){
        rounded(x-r*1.35,y+r*.5,r*2.7,r*2.6,r*.9,shirt);
        canvas.drawCircle(Offset(x,y),r,Paint()..color=skin);
        canvas.drawArc(Rect.fromCircle(center:Offset(x,y-2),radius:r+1),math.pi,math.pi,false,
          Paint()..color=midnight..style=PaintingStyle.stroke..strokeWidth=7);
      }
      person(63,92,25,const Color(0xFF9685B8),const Color(0xFFE8BFA0));
      person(136,83,26,accent,const Color(0xFFDCA680));
      person(105,154,21,const Color(0xFFF1CA86),const Color(0xFFE8BFA0));
      rounded(10,170,47,37,12,Colors.white);
      final heart=Path()..moveTo(33,197)..cubicTo(8,182,23,171,33,181)
        ..cubicTo(45,168,58,186,33,197);
      canvas.drawPath(heart,Paint()..color=const Color(0xFFC0747B));
      rounded(154,132,36,36,11,Colors.white);
      rounded(170,140,5,20,2,accent);rounded(163,147,19,5,2,accent);
    } else {
      rounded(39,121,122,86,13,const Color(0xFFDFA753));
      rounded(31,111,138,26,7,const Color(0xFFF3CC83));
      rounded(93,111,19,96,3,const Color(0xFF79669C));
      final ribbon=Paint()..color=const Color(0xFF79669C)..strokeWidth=10..style=PaintingStyle.stroke;
      canvas.drawOval(const Rect.fromLTWH(58,78,44,31),ribbon);
      canvas.drawOval(const Rect.fromLTWH(101,78,43,31),ribbon);
      for(var i=0;i<3;i++){
        rounded(129,201-i*10.0,53,12,6,const Color(0xFFAD752C));
        canvas.drawOval(Rect.fromLTWH(129,195-i*10.0,53,14),Paint()..color=const Color(0xFFF2D28F));
      }
      canvas.drawCircle(const Offset(33,68),17,Paint()..color=const Color(0xFFF2D28F));
      canvas.drawCircle(const Offset(33,68),11,Paint()..color=const Color(0xFFE7B968));
    }
    final sparkle=Paint()..color=accent.withAlpha(140)..strokeWidth=2..strokeCap=StrokeCap.round;
    for(final p in [const Offset(165,46),const Offset(25,128)]){
      canvas.drawLine(p-const Offset(0,6),p+const Offset(0,6),sparkle);
      canvas.drawLine(p-const Offset(6,0),p+const Offset(6,0),sparkle);
    }
    canvas.restore();
  }
  @override bool shouldRepaint(covariant CareArtwork old)=>old.scene!=scene;
}

class StoryStrip extends StatelessWidget {
  const StoryStrip({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final labels=[s.t('من البيت','At home'),s.t('افهم تقريرك','Your report'),s.t('مساحة العائلة','Family space'),s.t('مكافآتك','Rewards')];
    final icons=[Icons.home_outlined,Icons.analytics_outlined,Icons.people_outline,Icons.redeem_outlined];
    return SizedBox(height:82+36*MediaQuery.textScalerOf(context).scale(1),child:ListView.separated(
      scrollDirection:Axis.horizontal,itemCount:4,separatorBuilder:(_,i)=>const SizedBox(width:14),
      itemBuilder:(context,i)=>SizedBox(width:86,child:InkWell(
        key:ValueKey('story-$i'),borderRadius:BorderRadius.circular(18),
        onTap:(){s.viewedStories.add(i);s.update();go(context,StoryViewer(initial:i));},
        child:Column(children:[
          Container(padding:const EdgeInsets.all(3),decoration:BoxDecoration(shape:BoxShape.circle,
            border:Border.all(width:2,color:s.viewedStories.contains(i)?accent.withAlpha(40):accent)),
            child:Container(width:56,height:56,decoration:BoxDecoration(shape:BoxShape.circle,
              color:surface(context)),child:Icon(icons[i],size:26,color:Theme.of(context).colorScheme.primary))),
          const SizedBox(height:8),Text(labels[i],textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,height:1.4)),
        ])))));
  }
}
class StoryViewer extends StatefulWidget {
  const StoryViewer({super.key,required this.initial});
  final int initial;
  @override State<StoryViewer> createState()=>_StoryViewerState();
}
class _StoryViewerState extends State<StoryViewer> {
  late int index=widget.initial;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final titles=[s.t('من باب بيتك، للمختبر','From your doorstep to the lab'),
      s.t('أرقام أوضح، أسئلة أفضل','Clearer numbers. Better questions.'),
      s.t('ملف مستقل لكل فرد','A profile for each person'),
      s.t('نقاط تتحول لاختيارك','Points become your choice')];
    final bodies=[s.t('اختَر باقتك وموعدك، وأضف عنوانك. تابع تسع مراحل لطلب السحب المنزلي داخل النموذج.',
        'Choose your package and time, add an address, and follow nine demo collection stages.'),
      s.t('شوف القيمة والوحدة والمدى التوضيحي، وقارن القراءة بالسابق. تفسيرها طبياً يحتاج طبيبك.',
        'See values, units and illustrative ranges, then compare previous readings. Clinical interpretation belongs with your clinician.'),
      s.t('بدّل بين ملفات العائلة. تظهر نتائج ومواعيد الفرد المحدد فقط في ملفه.',
        'Switch family profiles. Each person’s reports and appointments appear in their own profile.'),
      s.t('استبدل النقاط بقسيمة تجريبية، ثم جرّب تطبيقها على باقة في الحجز.',
        'Redeem points for a demo voucher, then try it on a package during checkout.')];
    return DetailPage(title:s.t('اكتشف التجربة','Explore the experience'),children:[
      Row(children:List.generate(4,(i)=>Expanded(child:Container(height:4,margin:const EdgeInsets.all(3),
        decoration:BoxDecoration(color:i<=index?accent:accent.withAlpha(30),borderRadius:BorderRadius.circular(5)))))),
      const SizedBox(height:20),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Center(child:SizedBox(width:190,height:210,child:CustomPaint(painter:CareArtwork(index==0?0:index==3?2:1)))),
        const SizedBox(height:20),Heading(titles[index]),
        Text(bodies[index],style:TextStyle(color:muted(context),height:1.9,fontSize:15)),
        const SizedBox(height:22),
        FilledButton(key:const ValueKey('story-cta'),onPressed:()=>go(context,
          index==0?const HomeCollectionHub():index==1?const ReportExplorer():index==2?const FamilyHub():const RewardsScreen()),
          child:Text(s.t('جرّب الميزة','Try this feature'))),
      ])),
      const SizedBox(height:20),
      Row(children:[
        OutlinedButton(onPressed:index>0?()=>setState((){index--;s.viewedStories.add(index);s.update();}):null,
          child:Text(s.t('السابق','Previous'))),
        const Spacer(),
        FilledButton(onPressed:index<3?()=>setState((){index++;s.viewedStories.add(index);s.update();}):()=>Navigator.pop(context),
          child:Text(index<3?s.t('التالي','Next'):s.t('تم','Done'))),
      ]),
    ]);
  }
}

class CareSummary extends StatelessWidget {
  const CareSummary({super.key,required this.onResults,required this.onBookings});
  final VoidCallback onResults,onBookings;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final ready=s.patientReports.where((r)=>r.ready).length;
    final pending=s.patientReports.where((r)=>!r.ready).length;
    final upcoming=s.bookings.where((b)=>b.patientId==s.patientId&&b.status=='upcoming').length;
    return Panel(padding:17,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        const Icon(Icons.favorite_border,color:accent,size:19),const SizedBox(width:8),
        Expanded(child:Text(s.t('مركز العناية • ${s.patient.name.split(' ').first}',
          'Care center • ${s.patient.name.split(' ').first}'),
          style:const TextStyle(fontWeight:FontWeight.w800,fontSize:15))),
        IconButton(tooltip:s.t('خطة العناية','Care planner'),onPressed:()=>go(context,const CarePlanScreen()),
          icon:const Icon(Icons.arrow_outward,size:18)),
      ]),
      const SizedBox(height:8),
      Row(children:[
        for(final item in [('$ready',s.t('نتائج جاهزة','Ready reports'),onResults),
          ('$pending',s.t('قيد الإجراء','Processing'),onResults),
          ('$upcoming',s.t('مواعيد قادمة','Upcoming'),onBookings)])
          Expanded(child:InkWell(onTap:item.$3,borderRadius:BorderRadius.circular(12),
            child:Padding(padding:const EdgeInsets.symmetric(vertical:8,horizontal:3),
              child:Column(children:[
                Text(item.$1,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:26)),
                const SizedBox(height:4),Text(item.$2,textAlign:TextAlign.center,
                  style:TextStyle(color:muted(context),fontSize:10)),
              ])))),
      ]),
    ]));
  }
}
class ReportExplorer extends StatelessWidget {
  const ReportExplorer({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return Scaffold(appBar:AppBar(title:Text(s.t('نتائج الملف','Profile reports'))),body:const ResultsScreen());
  }
}

class CarePlanScreen extends StatelessWidget {
  const CarePlanScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final id=s.patientId;
    final checked=s.careChecks[id]??<int>{};
    final tasks=[
      (s.t('راجع تقاريرك المتاحة','Review your available reports'),
        s.t('احتفظ بأسئلتك لمناقشتها مع الطبيب.','Keep questions to discuss with your clinician.'),Icons.description_outlined),
      (s.t('دوّن أسئلة الزيارة','Write your visit questions'),
        s.t('ما الذي تريد توضيحه خلال الموعد؟','What would you like to clarify at your visit?'),Icons.edit_note),
      (s.t('جهّز معلومات الزيارة','Prepare your visit information'),
        s.t('راجع بيانات الاتصال والمعلومات التي أضفتها.','Review your contact details and the information you added.'),Icons.fact_check_outlined),
    ];
    return DetailPage(title:s.t('خطة العناية','Care planner'),children:[
      const PatientPicker(),const SizedBox(height:20),
      Panel(child:Row(children:[
        ProgressRing(value:checked.length/3,label:'${checked.length}/3',size:84),
        const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s.t('جاهز لزيارة أوضح؟','Ready for a clearer visit?'),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:20)),
          const SizedBox(height:8),Text(s.t('قائمة لتنظيم الزيارة، وليست تقييماً لحالتك الصحية.',
            'A checklist for organizing your visit, not a health score.'),
            style:TextStyle(color:muted(context),fontSize:12,height:1.7)),
        ])),
      ])),
      Section(s.t('خطواتك الشخصية','Your personal steps')),
      ...tasks.asMap().entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Panel(
        padding:12,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          CheckboxListTile(key:ValueKey('care-task-${e.key}'),contentPadding:EdgeInsets.zero,
            value:checked.contains(e.key),onChanged:(v)=>s.checkCare(id,e.key,v!),
            title:Text(e.value.$1,style:const TextStyle(fontWeight:FontWeight.w700)),
            subtitle:Text(e.value.$2,style:TextStyle(fontSize:12,color:muted(context),height:1.6))),
          TextButton.icon(onPressed:() async {
            if(e.key==0){go(context,const ReportExplorer());return;}
            if(e.key==2){go(context,const MedicalScreen());return;}
            final text=await prompt(context,s.t('أسئلتي للزيارة','My visit questions'),lines:4);
            if(text!=null){s.visitQuestions[id]=text;s.update();}
          },icon:Icon(e.value.$3,size:18),label:Text(
            e.key==0?s.t('افتح النتائج','Open reports'):e.key==1?s.t('اكتب أسئلتك','Write questions'):s.t('راجع المعلومات','Review information'))),
        ])))),
      if(s.visitQuestions[id]!=null) ...[
        Section(s.t('مذكرة الزيارة','Visit note')),
        Panel(child:SelectableText(s.visitQuestions[id]!,style:const TextStyle(height:1.8))),
      ],
      const SizedBox(height:12),
      OutlinedButton.icon(onPressed:()=>go(context,const RemindersScreen()),icon:const Icon(Icons.alarm_add),
        label:Text(s.t('أضف تذكيراً للقائمة','Add a checklist reminder'))),
      Note(s.t('التقدّم والملاحظات مستقلان لكل فرد ويُحفظان خلال جلسة العرض فقط.',
        'Progress and notes are separate for each person and saved only during this demo session.')),
    ]);
  }
}
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key,required this.value,required this.label,this.size=78,this.gold=false});
  final double value,size;
  final String label;
  final bool gold;
  @override Widget build(BuildContext context)=>Semantics(label:label,value:'${(value*100).round()}%',
    child:SizedBox(width:size,height:size,child:Stack(alignment:Alignment.center,children:[
      SizedBox.expand(child:CircularProgressIndicator(value:value,strokeWidth:6,
        color:gold?const Color(0xFFE8C589):accent,
        backgroundColor:gold?Colors.white12:accent.withAlpha(20))),
      Padding(padding:const EdgeInsets.all(12),child:Text(label,textAlign:TextAlign.center,
        style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:gold?Colors.white:null))),
    ])));
}
class FamilyHub extends StatelessWidget {
  const FamilyHub({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DetailPage(title:s.t('مساحة العائلة','Family space'),children:[
      Heading(s.t('كل العائلة،\nبمكان قريب لقلبك.','The whole family.\nClose to your heart.'),
        subtitle:s.t('ملف مستقل لكل شخص، وخطوات عناية تخصّه.','A separate profile and care checklist for each person.')),
      ...s.patients.map((p){
        final ready=reports.where((r)=>r.patientId==p.id&&r.ready).length;
        final visits=s.bookings.where((b)=>b.patientId==p.id&&b.status=='upcoming').length;
        final done=(s.careChecks[p.id]??{}).length;
        return Padding(padding:const EdgeInsets.only(bottom:14),child:Panel(child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              CircleAvatar(radius:25,backgroundColor:mint,child:Text(p.name.characters.first,
                style:const TextStyle(color:accent,fontWeight:FontWeight.w800,fontSize:22))),
              const SizedBox(width:13),Expanded(child:Text(p.name,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18))),
              if(p.id==s.patientId) Tag(s.t('الملف الحالي','Active')),
            ]),
            const SizedBox(height:20),
            Wrap(spacing:8,runSpacing:8,children:[
              Tag(s.t('$ready نتيجة جاهزة','$ready ready reports')),
              Tag(s.t('$visits موعد قادم','$visits upcoming visits')),
              Tag(s.t('$done/3 خطوات التحضير','$done/3 preparation steps'),color:const Color(0xFF7862A4)),
            ]),
            const SizedBox(height:18),
            Row(children:[
              Expanded(child:FilledButton(key:ValueKey('family-open-${p.id}'),onPressed:(){
                s.selectPatient(p.id);go(context,const CarePlanScreen());
              },child:Text(s.t('خطة العناية','Care planner')))),
              const SizedBox(width:10),
              Expanded(child:OutlinedButton(onPressed:(){
                s.selectPatient(p.id);go(context,const ReportExplorer());
              },child:Text(s.t('النتائج','Reports')))),
            ]),
          ])));
      }),
      OutlinedButton.icon(onPressed:()=>go(context,const FamilyScreen()),
        icon:const Icon(Icons.person_add_alt),label:Text(s.t('إضافة فرد وإدارة الملفات','Add & manage family profiles'))),
      Note(s.t('تظهر هنا بيانات عائلة تجريبية؛ ربط ملفات البالغين فعلياً يحتاج موافقتهم والتحقق من الهوية.',
        'Demo family data is shown here. Linking adult records requires consent and identity verification.')),
    ]);
  }
}
class HomeCollectionHub extends StatefulWidget {
  const HomeCollectionHub({super.key});
  @override State<HomeCollectionHub> createState()=>_HomeCollectionHubState();
}
class _HomeCollectionHubState extends State<HomeCollectionHub> {
  String selected='wellness';
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final item=services.firstWhere((v)=>v.id==selected);
    final ongoing=s.bookings.where((b)=>b.home&&b.patientId==s.patientId&&b.status=='upcoming').toList();
    return DetailPage(title:s.t('فحوصات من البيت','Care at home'),children:[
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Expanded(child:Heading(s.t('راحتك جزء\nمن العناية.','Your comfort.\nPart of your care.'),
            subtitle:s.t('معاينة السحب المنزلي','Home collection preview'))),
          SizedBox(width:105,height:140,child:CustomPaint(painter:CareArtwork(0))),
        ]),
        Text(s.t('اختَر الباقة وشوف التكلفة قبل ما تكمل الحجز.',
          'Choose a package and see the price before booking.'),style:TextStyle(color:muted(context),height:1.7)),
      ])),
      const SizedBox(height:20),
      DropdownButtonFormField<String>(value:selected,isExpanded:true,
        decoration:InputDecoration(labelText:s.t('الباقة','Package')),
        items:services.where((v)=>v.kind=='packages').map((v)=>DropdownMenuItem(
          value:v.id,child:Text(v.title(s),overflow:TextOverflow.ellipsis))).toList(),
        onChanged:(v)=>setState(()=>selected=v!)),
      const SizedBox(height:16),
      Panel(child:Column(children:[
        quoteLine(s.t('سعر الباقة','Package price'),s.money(item.price)),
        const SizedBox(height:12),quoteLine(s.t('السحب المنزلي','Home collection'),s.money(10000)),
        const Divider(),quoteLine(s.t('الإجمالي التجريبي','Demo total'),s.money(item.price+10000)),
      ])),
      const SizedBox(height:18),
      FilledButton.icon(key:const ValueKey('home-collection-book'),onPressed:()=>go(context,BookingScreen(item,home:true)),
        icon:const Icon(Icons.calendar_month_outlined),label:Text(s.t('اختَر الموعد والعنوان','Choose time & address'))),
      Section(s.t('رحلة واضحة من البداية','Know the journey')),
      ...[(Icons.edit_calendar,s.t('1 • اختَر وقتك','1 • Choose a time')),
        (Icons.home_outlined,s.t('2 • استقبل الفني','2 • Meet your collector')),
        (Icons.science_outlined,s.t('3 • تابع العينة','3 • Follow the sample')),
        (Icons.description_outlined,s.t('4 • افتح النتيجة','4 • View the report'))]
        .map((v)=>ActionRow(v.$1,v.$2,trailing:const SizedBox.shrink())),
      if(ongoing.isNotEmpty) ...[
        Section(s.t('طلباتي الحالية','My active requests')),
        ...ongoing.map((b)=>ActionRow(Icons.route_outlined,b.id,subtitle:b.service.title(s),
          onTap:()=>go(context,TrackingScreen(b)))),
      ],
      Note(s.t('الأسعار والتغطية والتتبع تجريبية. لا يتم إرسال فني فعلي في هذه النسخة.',
        'Prices, coverage and tracking are simulated. No real collector is dispatched in this version.')),
    ]);
  }
  Widget quoteLine(String title,String value)=>Row(children:[
    Expanded(child:Text(title)),const SizedBox(width:10),Text(value,style:const TextStyle(fontWeight:FontWeight.w800)),
  ]);
}

class PackageComparisonScreen extends StatelessWidget {
  const PackageComparisonScreen({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final packages=services.where((v)=>v.kind=='packages').toList();
    final chosen=packages.where((v)=>s.compareIds.contains(v.id)).toList();
    String tests(Service v)=>v.id=='wellness'?'12':v.id=='vitamins'?'4':'6';
    String lab(Service v)=>v.id=='liver'?s.t('مختبر النور التجريبي','Demo Noor Lab'):s.t('مختبر الحياة التجريبي','Demo Life Lab');
    return DetailPage(title:s.t('قارن الباقات','Compare packages'),children:[
      Heading(s.t('الاختيار يصير أوضح.','A clearer choice.'),
        subtitle:s.t('اختَر باقتين أو ثلاث. قارن التفاصيل حسب طلب طبيبك.',
          'Choose two or three packages. Compare details against your clinician’s request.')),
      Wrap(spacing:8,runSpacing:8,children:packages.map((v)=>FilterChip(
        key:ValueKey('compare-${v.id}'),label:Text(v.title(s)),selected:s.compareIds.contains(v.id),
        onSelected:(_)=>s.toggleComparison(v.id))).toList()),
      const SizedBox(height:20),
      if(chosen.length<2) EmptyState(s.t('اختَر باقتين للمقارنة','Choose two packages'),
        s.t('تظهر التفاصيل جنباً إلى جنب بعد تحديد باقتين.','Select two packages to see their details side by side.'),
        icon:Icons.compare_arrows)
      else ...[
        Note(s.t('اسحب الجدول أفقياً للاطلاع على كل الخيارات.','Swipe the table horizontally to see every option.')),
        Panel(padding:0,child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
          headingRowHeight:76,dataRowMinHeight:58,dataRowMaxHeight:90,
          headingRowColor:WidgetStatePropertyAll(accent.withAlpha(12)),
          columns:[
            DataColumn(label:Text(s.t('وجه المقارنة','Compare'),style:const TextStyle(fontWeight:FontWeight.w800))),
            ...chosen.map((v)=>DataColumn(label:SizedBox(width:140,child:Text(v.title(s),
              style:const TextStyle(fontWeight:FontWeight.w800))))),
          ],
          rows:[
            DataRow(cells:[DataCell(Text(s.t('سعر الباقة','Package price'))),
              ...chosen.map((v)=>DataCell(Text(s.money(v.price),style:const TextStyle(fontWeight:FontWeight.w800))))]),
            DataRow(cells:[DataCell(Text(s.t('عدد الفحوصات','Number of tests'))),...chosen.map((v)=>DataCell(Text(tests(v))))]),
            DataRow(cells:[DataCell(Text(s.t('المختبر','Laboratory'))),
              ...chosen.map((v)=>DataCell(SizedBox(width:140,child:Text(lab(v)))))]),
            DataRow(cells:[DataCell(Text(s.t('سحب منزلي','Home collection'))),
              ...chosen.map((v)=>DataCell(Text(s.t('متاح تجريبياً','Demo available'))))]),
            DataRow(cells:[DataCell(Text(s.t('مع السحب المنزلي','With collection'))),
              ...chosen.map((v)=>DataCell(Text(s.money(v.price+10000))))]),
            DataRow(cells:[DataCell(Text(s.t('بعد DIGITAL10','After DIGITAL10'))),
              ...chosen.map((v)=>DataCell(Text(s.money(v.price-promoDiscount(v,'DIGITAL10')))))]),
          ],
        ))),
        Section(s.t('اختَر الباقة لإكمال الحجز','Choose a package to continue')),
        ...chosen.map((v)=>ActionRow(v.icon,v.title(s),subtitle:s.money(v.price),
          onTap:()=>go(context,BookingScreen(v)))),
      ],
      Note(s.t('المقارنة لا تقترح فحوصات طبية. المحتوى والأسعار بيانات عرض فقط.',
        'This comparison does not recommend medical tests. Contents and prices are illustrative.')),
    ]);
  }
}

class LoyaltyTeaser extends StatelessWidget {
  const LoyaltyTeaser({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return Panel(color:midnight,onTap:()=>go(context,const RewardsScreen()),
      child:Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s.t('نادي Digital Lab','THE DIGITAL LAB CLUB'),
            style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:Color(0xFFE8C589),letterSpacing:1)),
          const SizedBox(height:8),Text(s.t('${s.points} نقطة','${s.points} points'),
            style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800,color:Colors.white)),
          const SizedBox(height:7),Text(s.t('اختَر مكافأتك، وجرّبها بالحجز.','Pick a reward. Try it at checkout.'),
            style:const TextStyle(color:Colors.white70,fontSize:12,height:1.6)),
        ])),const SizedBox(width:18),
        ProgressRing(value:s.tierProgress,label:s.t('ذهبي','GOLD'),gold:true),
      ]));
  }
}
class LoyaltyExperience extends StatelessWidget {
  const LoyaltyExperience({super.key});
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final tierNames=[s.t('برونزي','Bronze'),s.t('فضي','Silver'),s.t('ذهبي','Gold'),s.t('بلاتيني','Platinum')];
    const thresholds=[0,1000,2000,5000];
    return DetailPage(title:s.t('نادي Digital Lab','Digital Lab Club'),children:[
      Panel(color:midnight,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(s.t('اهتمام يستحق المكافأة','CARE WORTH REWARDING'),
              style:const TextStyle(color:Color(0xFFE8C589),fontSize:11,fontWeight:FontWeight.w800)),
            const SizedBox(height:14),Text('${s.points}',
              style:const TextStyle(color:Colors.white,fontSize:43,fontWeight:FontWeight.w800)),
            Text(s.t('نقطة متاحة • رصيد تجريبي','Available points • Demo balance'),
              style:const TextStyle(color:Colors.white70,fontSize:11)),
          ])),const SizedBox(width:12),
          ProgressRing(value:s.tierProgress,label:tierNames[s.tierIndex],gold:true,size:88),
        ]),
        const SizedBox(height:24),
        ClipRRect(borderRadius:BorderRadius.circular(5),child:LinearProgressIndicator(
          value:s.tierProgress,color:const Color(0xFFE8C589),backgroundColor:Colors.white12,minHeight:6)),
        const SizedBox(height:12),
        Text(s.t('${s.lifetimePoints} نقطة مؤهلة • ${s.tierIndex==3?0:thresholds[s.tierIndex+1]-s.lifetimePoints} للمستوى القادم',
          '${s.lifetimePoints} qualifying points • ${s.tierIndex==3?0:thresholds[s.tierIndex+1]-s.lifetimePoints} to the next tier'),
          style:const TextStyle(color:Colors.white70,fontSize:11)),
      ])),
      Section(s.t('رحلة عضويتك','Your membership journey')),
      Wrap(spacing:8,runSpacing:8,children:List.generate(4,(i)=>Tag(
        '${tierNames[i]} • ${thresholds[i]}',color:i==s.tierIndex?amber:accent))),
      Note(s.t('المستوى مبني على النقاط المؤهلة، واستبدال الرصيد لا يخفض مستواك. كل الأرصدة والمزايا تجريبية.',
        'Your tier uses qualifying points; spending your balance does not lower it. All balances and benefits are simulated.')),
      Section(s.t('اختَر مكافأتك','Choose your reward')),
      TileGrid(minWidth:245,children:[500,1000,1500].map((cost)=>Panel(child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[const Glyph(Icons.redeem_outlined,color:amber),const Spacer(),
            Tag(s.t('$cost نقطة','$cost points'),color:amber)]),
          const SizedBox(height:18),
          Text(s.money(cost*10),style:const TextStyle(fontSize:27,fontWeight:FontWeight.w800)),
          const SizedBox(height:7),
          Text(s.t('خصم تجريبي على باقة فحوصات','Demo discount on a test package'),
            style:TextStyle(color:muted(context),fontSize:12,height:1.6)),
          const SizedBox(height:18),
          SizedBox(width:double.infinity,child:FilledButton(key:ValueKey('redeem-$cost'),
            onPressed:s.points<cost?null:() async {
              if(!await confirm(context,s.t('استبدال النقاط؟','Redeem points?'),
                s.t('سيُخصم $cost نقطة من الرصيد التجريبي وتُضاف قسيمة بقيمة ${s.money(cost*10)}.',
                  '$cost demo points will be exchanged for a ${s.money(cost*10)} demo voucher.')))return;
              final voucher=s.claimReward(cost);
              if(voucher!=null&&context.mounted)go(context,VoucherScreen(voucher));
            },child:Text(s.t('استبدال المكافأة','Redeem reward')))),
        ]))).toList()),
      Section(s.t('قسائمي','My vouchers')),
      if(s.vouchers.isEmpty) EmptyState(s.t('مكافأتك الأولى بانتظارك','Your first reward is waiting'),
        s.t('استبدل النقاط وتظهر قسيمتك هنا.','Redeem points to see your voucher here.'),icon:Icons.redeem_outlined),
      ...s.vouchers.map((v)=>ActionRow(v.used?Icons.check_circle_outline:Icons.local_offer_outlined,v.code,
        subtitle:s.money(v.amount),trailing:Tag(v.used?s.t('مستخدمة','Used'):s.t('متاحة','Available')),
        onTap:()=>go(context,VoucherScreen(v)))),
      Section(s.t('حركة النقاط','Points activity')),
      ActionRow(Icons.add_circle_outline,s.t('رصيد افتتاحي تجريبي','Demo opening balance'),trailing:const Text('+2,450')),
      ...s.vouchers.map((v)=>ActionRow(Icons.redeem,v.code,trailing:Text('−${v.cost}'))),
    ]);
  }
}
class VoucherScreen extends StatelessWidget {
  const VoucherScreen(this.voucher,{super.key});
  final RewardVoucher voucher;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final v=voucher;
    return DetailPage(title:s.t('مكافأتك','Your reward'),children:[
      Panel(child:Column(children:[
        SizedBox(width:140,height:170,child:CustomPaint(painter:CareArtwork(2))),
        Text(s.t('مكافأة على اختيارك.','A little extra, just for you.'),
          style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800),textAlign:TextAlign.center),
        const SizedBox(height:14),Text(s.money(v.amount),style:const TextStyle(fontSize:34,fontWeight:FontWeight.w800)),
        const SizedBox(height:12),SelectableText(v.code,style:const TextStyle(fontSize:23,letterSpacing:2,fontWeight:FontWeight.w800)),
        const SizedBox(height:12),Tag(v.used?s.t('مستخدمة','Used'):s.t('متاحة للاستخدام التجريبي','Available for demo checkout')),
        const SizedBox(height:18),
        OutlinedButton.icon(onPressed:() async {
          await Clipboard.setData(ClipboardData(text:v.code));
          if(context.mounted)toast(context,s.t('تم نسخ الكود','Code copied'));
        },icon:const Icon(Icons.copy,size:18),label:Text(s.t('نسخ الكود','Copy code'))),
      ])),
      Note(s.t('تُطبق مرة واحدة على سعر الباقة فقط، ولا تُجمع مع DIGITAL10. تُعاد إتاحتها عند إلغاء الحجز التجريبي. لا قيمة مالية فعلية.',
        'Applies once to a package price, without DIGITAL10. Cancelling the demo booking makes it available again. No real monetary value.')),
      if(!v.used) ...[
        Section(s.t('اختَر باقة لاستخدام القسيمة','Choose a package to use your voucher')),
        ...services.where((p)=>p.kind=='packages').map((p)=>ActionRow(p.icon,p.title(s),
          subtitle:s.t('بعد القسيمة: ${s.money(p.price-s.discountFor(p,v.code))}',
            'After voucher: ${s.money(p.price-s.discountFor(p,v.code))}'),
          onTap:()=>go(context,BookingScreen(p,couponCode:v.code)))),
      ],
    ]);
  }
}
