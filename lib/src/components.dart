part of '../main.dart';

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness);
  return ThemeData(
    useMaterial3: true, colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF101F26) : const Color(0xFFF5F7F8),
    appBarTheme: AppBarTheme(backgroundColor: dark ? const Color(0xFF101F26) : const Color(0xFFF5F7F8),
      surfaceTintColor: Colors.transparent,centerTitle:false,elevation:0),
    textTheme: Typography.material2021().black.apply(
      bodyColor: dark ? const Color(0xFFE4EFED) : midnight,
      displayColor: dark ? const Color(0xFFE4EFED) : midnight),
    inputDecorationTheme: InputDecorationTheme(
      filled:true,fillColor: dark ? const Color(0xFF1D3039) : Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(16),
        borderSide: BorderSide(color:dark ? Colors.white12 : const Color(0xFFE0E8E7))),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      minimumSize: const Size(48,50),backgroundColor: accent,foregroundColor:Colors.white,
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
      textStyle:const TextStyle(fontSize:14,fontWeight:FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      minimumSize:const Size(48,48),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)))),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:dark ? const Color(0xFF142730) : Colors.white,
      indicatorColor:dark ? const Color(0xFF23544F) : mint,
      labelTextStyle:const WidgetStatePropertyAll(TextStyle(fontSize:11,fontWeight:FontWeight.w600))),
    dividerTheme: DividerThemeData(color:dark ? Colors.white12 : const Color(0xFFE6ECEB),space:28),
  );
}
Color muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
Color surface(BuildContext context) => Theme.of(context).brightness == Brightness.dark
  ? const Color(0xFF192D36) : Colors.white;
void go(BuildContext context,Widget page) => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => page));
void toast(BuildContext context,String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message),behavior:SnackBarBehavior.floating));
}
Future<bool> confirm(BuildContext context,String title,String body) async {
  final s=AppScope.of(context);
  return await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
    title:Text(title),content:Text(body),actions:[
      TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(s.t('رجوع','Back'))),
      FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(s.t('تأكيد','Confirm'))),
    ])) ?? false;
}
Future<String?> prompt(BuildContext context,String title,{String? hint,int lines=1}) async {
  final s=AppScope.of(context);
  String input='';
  final key=GlobalKey<FormState>();
  final result=await showDialog<String>(context:context,builder:(c)=>AlertDialog(
    title:Text(title),
    content:Form(key:key,child:TextFormField(onChanged:(v)=>input=v,autofocus:true,
      minLines:lines,maxLines:lines,decoration:InputDecoration(hintText:hint),
      validator:(v)=>(v??'').trim().isEmpty ? s.t('أدخل قيمة','Enter a value') : null)),
    actions:[TextButton(onPressed:()=>Navigator.pop(c),child:Text(s.t('إلغاء','Cancel'))),
      FilledButton(onPressed:(){if(key.currentState!.validate()) Navigator.pop(c,input.trim());},
        child:Text(s.t('حفظ','Save')))]));
  return result;
}
void previewNotice(BuildContext context,String title,String body) {
  final s=AppScope.of(context);
  showDialog<void>(context:context,builder:(c)=>AlertDialog(title:Text(title),
    content:Text(body),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:Text(s.t('حسناً','OK')))]));
}
class BrandMark extends StatelessWidget {
  const BrandMark({super.key,this.size=44});
  final double size;
  @override
  Widget build(BuildContext context) => Container(width:size,height:size,
    decoration:BoxDecoration(color:accent,borderRadius:BorderRadius.circular(size*.3)),
    child:Icon(Icons.biotech,color:Colors.white,size:size*.68));
}
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key,required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(alignment:Alignment.topCenter,
    child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1100),
      child:ListView(padding:EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 400 ? 16 : 24,20,
        MediaQuery.sizeOf(context).width < 400 ? 16 : 24,32),
        children:children)));
}
class DetailPage extends StatelessWidget {
  const DetailPage({super.key,required this.title,required this.children,this.actions});
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700)),actions:actions),
    body:ScreenBody(children:children));
}
class Heading extends StatelessWidget {
  const Heading(this.title,{super.key,this.subtitle,this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(padding:const EdgeInsets.only(bottom:20),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(fontSize:26,fontWeight:FontWeight.w800,height:1.4)),
        if(subtitle!=null) Padding(padding:const EdgeInsets.only(top:5),
          child:Text(subtitle!,style:TextStyle(color:muted(context),fontSize:13,height:1.6))),
      ])),if(trailing!=null) trailing!,
    ]));
}
class Section extends StatelessWidget {
  const Section(this.title,{super.key,this.action,this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(padding:const EdgeInsets.only(top:22,bottom:12),
    child:Row(children:[
      Expanded(child:Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800))),
      if(action!=null) TextButton(onPressed:onTap,child:Text(action!)),
    ]));
}
class Panel extends StatelessWidget {
  const Panel({super.key,required this.child,this.color,this.padding=20,this.onTap});
  final Widget child;
  final Color? color;
  final double padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color:color??surface(context),borderRadius:BorderRadius.circular(22),
    child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(22),
      child:Container(padding:EdgeInsets.all(padding),
        decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),
          border:Border.all(color:Theme.of(context).brightness==Brightness.dark
            ? Colors.white.withAlpha(10) : const Color(0xFFE8EEEC))),
        child:child)));
}
class Tag extends StatelessWidget {
  const Tag(this.text,{super.key,this.color=accent});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
    decoration:BoxDecoration(color:color.withAlpha(22),borderRadius:BorderRadius.circular(8)),
    child:Text(text,style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,
      color:Theme.of(context).brightness==Brightness.dark ? Theme.of(context).colorScheme.onSurface : color)));
}
class Glyph extends StatelessWidget {
  const Glyph(this.icon,{super.key,this.color=accent,this.size=48});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context)=>Container(width:size,height:size,
    decoration:BoxDecoration(color:color.withAlpha(18),borderRadius:BorderRadius.circular(15)),
    child:Icon(icon,color:Theme.of(context).brightness==Brightness.dark
      ? Theme.of(context).colorScheme.primary : color,size:size*.5));
}
class ActionRow extends StatelessWidget {
  const ActionRow(this.icon,this.title,{super.key,this.subtitle,this.onTap,this.trailing});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:10),
    child:Panel(padding:15,onTap:onTap,child:Row(children:[
      Glyph(icon),const SizedBox(width:13),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),
        if(subtitle!=null) Padding(padding:const EdgeInsets.only(top:4),
          child:Text(subtitle!,style:TextStyle(fontSize:12,color:muted(context),height:1.5))),
      ])),const SizedBox(width:8),
      trailing??Icon(Directionality.of(context)==TextDirection.rtl
        ? Icons.chevron_left : Icons.chevron_right,color:muted(context),size:20),
    ])));
}
class TileGrid extends StatelessWidget {
  const TileGrid({super.key,required this.children,this.minWidth=155});
  final List<Widget> children;
  final double minWidth;
  @override
  Widget build(BuildContext context)=>LayoutBuilder(builder:(context,c){
    final columns=((c.maxWidth+12)/(minWidth+12)).floor().clamp(1,4);
    final width=(c.maxWidth-(columns-1)*12)/columns;
    return Wrap(spacing:12,runSpacing:12,children:children.map((w)=>SizedBox(width:width,child:w)).toList());
  });
}
class FeatureTile extends StatelessWidget {
  const FeatureTile(this.icon,this.title,this.subtitle,{super.key,required this.onTap,this.color=accent});
  final IconData icon;
  final String title,subtitle;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context)=>Panel(onTap:onTap,padding:17,
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Glyph(icon,color:color),const SizedBox(height:15),
      Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:15)),
      const SizedBox(height:5),Text(subtitle,style:TextStyle(color:muted(context),fontSize:11,height:1.5)),
    ]));
}
class Note extends StatelessWidget {
  const Note(this.text,{super.key,this.icon=Icons.info_outline});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:12),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Icon(icon,size:17,color:muted(context)),const SizedBox(width:8),
      Expanded(child:Text(text,style:TextStyle(color:muted(context),fontSize:12,height:1.6))),
    ]));
}
class EmptyState extends StatelessWidget {
  const EmptyState(this.title,this.body,{super.key,this.icon=Icons.inbox_outlined,this.action});
  final String title,body;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context)=>Panel(child:Column(children:[
    const SizedBox(height:16),Glyph(icon,size:68),const SizedBox(height:18),
    Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
    const SizedBox(height:8),Text(body,textAlign:TextAlign.center,style:TextStyle(color:muted(context),height:1.6)),
    if(action!=null) Padding(padding:const EdgeInsets.only(top:18),child:action!),
    const SizedBox(height:16),
  ]));
}
class PatientPicker extends StatelessWidget {
  const PatientPicker({super.key});
  @override
  Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return DropdownButtonFormField<String>(
      value:s.patientId,decoration:InputDecoration(labelText:s.t('الملف الصحي','Health profile'),
        prefixIcon:const Icon(Icons.account_circle_outlined)),
      items:s.patients.map((p)=>DropdownMenuItem(value:p.id,child:Text(p.name))).toList(),
      onChanged:(v){if(v!=null) s.selectPatient(v);});
  }
}
class ServiceCard extends StatelessWidget {
  const ServiceCard(this.service,{super.key});
  final Service service;
  @override
  Widget build(BuildContext context) {
    final s=AppScope.of(context);
    return Padding(padding:const EdgeInsets.only(bottom:12),child:Panel(
      onTap:(){s.recent.add(service.id);s.update();go(context,ServiceScreen(service));},
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Glyph(service.icon,size:54),const Spacer(),
          if(service.kind=='packages') Tag(s.t('باقة فحوصات','TEST PACKAGE')),
          IconButton(tooltip:s.t('المفضلة','Favorite'),
            onPressed:()=>s.favorite(service.id),
            icon:Icon(s.favorites.contains(service.id)?Icons.favorite:Icons.favorite_border,
              color:s.favorites.contains(service.id)?const Color(0xFFBF5865):muted(context)))]),
        const SizedBox(height:15),
        Text(service.title(s),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17)),
        const SizedBox(height:6),
        Text(service.subtitle(s),style:TextStyle(fontSize:12,color:muted(context))),
        const SizedBox(height:18),
        Row(children:[
          Expanded(child:Text(service.price>0?s.money(service.price):s.t('عرض الفروع','View branches'),
            style:const TextStyle(fontWeight:FontWeight.w800,fontSize:15))),
          Icon(Directionality.of(context)==TextDirection.rtl?Icons.arrow_back:Icons.arrow_forward,
            size:19,color:accent),
        ]),
      ])));
  }
}
class MoleculePainter extends CustomPainter {
  @override
  void paint(Canvas canvas,Size size) {
    final line=Paint()..color=Colors.white.withAlpha(30)..strokeWidth=1.5..style=PaintingStyle.stroke;
    final center=Offset(size.width*.5,size.height*.5);
    canvas.drawCircle(center,size.width*.28,line);
    canvas.drawCircle(center,size.width*.44,line);
    final points=[Offset(size.width*.3,size.height*.27),Offset(size.width*.73,size.height*.34),
      Offset(size.width*.65,size.height*.78),Offset(size.width*.2,size.height*.67)];
    for(final p in points) {
      canvas.drawLine(center,p,line);
      canvas.drawCircle(p,9,Paint()..color=const Color(0xFF75D8B6).withAlpha(150));
    }
    canvas.drawCircle(center,24,Paint()..color=const Color(0xFF75D8B6).withAlpha(55));
    canvas.drawLine(center-const Offset(10,0),center+const Offset(10,0),
      Paint()..color=Colors.white70..strokeWidth=3);
    canvas.drawLine(center-const Offset(0,10),center+const Offset(0,10),
      Paint()..color=Colors.white70..strokeWidth=3);
  }
  @override bool shouldRepaint(covariant MoleculePainter oldDelegate)=>false;
}
