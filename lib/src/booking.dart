part of '../main.dart';

String modeLabel(AppStore s,String mode) {
  switch(mode) {
    case 'home':return s.t('سحب منزلي','Home collection');
    case 'chat':return s.t('محادثة','Chat');
    case 'voice':return s.t('صوت','Voice');
    case 'video':return s.t('فيديو','Video');
    default:return s.t('حضوري','In person');
  }
}
class BookingScreen extends StatefulWidget {
  const BookingScreen(this.service,{super.key,this.home=false,this.couponCode=''});
  final Service service;
  final bool home;
  final String couponCode;
  @override State<BookingScreen> createState()=>_BookingScreenState();
}
class _BookingScreenState extends State<BookingScreen> {
  int step=0;
  final form=GlobalKey<FormState>();
  late String mode=widget.home?'home':'clinic';
  String? patientId;
  String phone='',address='',notes='',payment='provider';
  late String coupon=widget.couponCode;
  String appliedCode='';
  bool couponInitialized=false;
  DateTime date=DateTime.now().add(const Duration(days:1));
  int hour=9;
  bool consent=false;
  bool submitted=false;
  int discount=0;
  @override Widget build(BuildContext context) {
    final s=AppScope.of(context);
    final service=widget.service;
    if(!couponInitialized){
      couponInitialized=true;
      appliedCode=coupon.trim().toUpperCase();
      discount=s.discountFor(service,appliedCode);
    }
    final total=service.price+(mode=='home'?10000:0)-discount;
    final steps=[s.t('المعلومات','Details'),s.t('الموعد','Appointment'),s.t('المراجعة','Review')];
    patientId??=s.patientId;
    return DetailPage(title:s.t('حجز جديد','New appointment'),children:[
      Row(children:List.generate(3,(i)=>Expanded(child:Padding(
        padding:const EdgeInsets.symmetric(horizontal:3),child:Column(children:[
          Container(height:5,decoration:BoxDecoration(color:i<=step?accent:accent.withAlpha(24),
            borderRadius:BorderRadius.circular(8))),
          const SizedBox(height:9),Text('${i+1}. ${steps[i]}',style:TextStyle(
            fontSize:12,fontWeight:i==step?FontWeight.w800:FontWeight.w400)),
        ]))))),
      const SizedBox(height:24),
      Heading(steps[step],subtitle:service.title(s)),
      Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        if(step==0) ...[
          DropdownButtonFormField<String>(value:patientId,
            decoration:InputDecoration(labelText:s.t('الحجز لمن؟','Who is this for?')),
            items:s.patients.map((p)=>DropdownMenuItem(value:p.id,child:Text(p.name))).toList(),
            onChanged:(v)=>setState(()=>patientId=v)),
          const SizedBox(height:16),
          TextFormField(key:const ValueKey('booking-phone'),initialValue:phone,
            keyboardType:TextInputType.phone,textDirection:TextDirection.ltr,
            decoration:InputDecoration(labelText:s.t('رقم الهاتف العراقي','Iraqi phone number'),hintText:'07xxxxxxxxx'),
            onChanged:(v)=>phone=v,validator:(v)=>validIraqiPhone(v??'')?null:
              s.t('أدخل رقماً عراقياً صالحاً مثل 07701234567','Enter a valid Iraqi number, e.g. 07701234567')),
          const SizedBox(height:16),
          DropdownButtonFormField<String>(value:mode,
            decoration:InputDecoration(labelText:s.t('نوع الموعد','Visit type')),
            items:(service.kind=='doctors'?['clinic','chat','voice','video']:
              service.kind=='packages'?['clinic','home']:['clinic']).map((v)=>DropdownMenuItem(
                value:v,child:Text(modeLabel(s,v)))).toList(),
            onChanged:(v)=>setState(()=>mode=v!)),
          Note(s.t('استخدم معلومات وهمية عند تجربة التصميم. لن تُرسل بياناتك إلى مقدم خدمة.',
            'Use fictional details while reviewing the design. Nothing is sent to a provider.')),
        ],
        if(step==1) ...[
          ActionRow(Icons.calendar_today_outlined,s.t('يوم الموعد','Appointment day'),
            subtitle:'${date.day}/${date.month}/${date.year}',onTap:() async {
              final chosen=await showDatePicker(context:context,initialDate:date,
                firstDate:DateTime.now().add(const Duration(days:1)),
                lastDate:DateTime.now().add(const Duration(days:90)));
              if(chosen!=null&&mounted)setState(()=>date=chosen);
            }),
          Text(s.t('الوقت المتاح — تجريبي','Available time — demo'),
            style:const TextStyle(fontWeight:FontWeight.w700)),
          const SizedBox(height:12),
          Wrap(spacing:8,runSpacing:8,children:[9,10,11,13,15,17].map((h)=>ChoiceChip(
            label:Text('${h.toString().padLeft(2,'0')}:00'),selected:h==hour,
            onSelected:(_)=>setState(()=>hour=h))).toList()),
          const SizedBox(height:20),
          if(mode=='home') TextFormField(key:const ValueKey('booking-address'),initialValue:address,
            maxLines:3,decoration:InputDecoration(labelText:s.t('العنوان الكامل','Full address'),
              hintText:s.t('المنطقة، الشارع، أقرب نقطة دالة','Area, street, nearest landmark')),
            onChanged:(v)=>address=v,
            validator:(v)=>(v??'').trim().length<8?s.t('أدخل عنواناً واضحاً','Enter a complete address'):null),
          const SizedBox(height:16),
          TextFormField(key:const ValueKey('booking-notes'),initialValue:notes,maxLines:3,
            decoration:InputDecoration(labelText:s.t('ملاحظات إضافية — اختياري','Additional notes — optional')),
            onChanged:(v)=>notes=v),
          Note(s.t('تأكيد التوفر وتعليمات التحضير ستكون من مقدم الخدمة بعد الربط.',
            'The provider will confirm availability and preparation instructions after integration.')),
        ],
        if(step==2) ...[
          Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(s.patients.firstWhere((p)=>p.id==patientId).name,
              style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),
            const SizedBox(height:10),Text(modeLabel(s,mode)),
            const SizedBox(height:10),Text(dateLabel(DateTime(date.year,date.month,date.day,hour))),
            if(mode=='home') Padding(padding:const EdgeInsets.only(top:10),child:Text(address)),
            const Divider(),
            priceRow(s.t('الخدمة','Service'),s.money(service.price)),
            if(mode=='home') priceRow(s.t('السحب المنزلي','Home collection'),s.money(10000)),
            if(discount>0) priceRow(s.t('الخصم','Discount'),'-${s.money(discount)}'),
            const Divider(),priceRow(s.t('الإجمالي التجريبي','Demo total'),s.money(total)),
          ])),
          const SizedBox(height:18),
          TextFormField(key:const ValueKey('booking-coupon'),initialValue:coupon,
            textCapitalization:TextCapitalization.characters,
            decoration:InputDecoration(labelText:s.t('كود الخصم','Promo code'),hintText:'DIGITAL10',
              suffixIcon:TextButton(onPressed:(){
                setState((){
                  appliedCode=coupon.trim().toUpperCase();
                  discount=s.discountFor(service,appliedCode);
                });
                toast(context,discount>0?s.t('تم تطبيق خصم الباقة','Package discount applied'):
                  s.t('تحقق من الكود. القسيمة يجب أن تكون متاحة وعلى باقة.','Check the code. Vouchers must be available and apply to a package.'));
              },child:Text(s.t('تطبيق','Apply')))),onChanged:(v)=>setState((){
              coupon=v;discount=0;appliedCode='';
            })),
          const SizedBox(height:16),
          DropdownButtonFormField<String>(value:payment,
            decoration:InputDecoration(labelText:s.t('طريقة الدفع','Payment method')),
            items:[DropdownMenuItem(value:'provider',child:Text(s.t('عند مقدم الخدمة','At the provider'))),
              DropdownMenuItem(value:'online',child:Text(s.t('إلكتروني — محاكاة','Online — simulation')))],
            onChanged:(v)=>setState(()=>payment=v!)),
          CheckboxListTile(contentPadding:EdgeInsets.zero,value:consent,
            onChanged:(v)=>setState(()=>consent=v??false),
            title:Text(s.t('أفهم أن هذا حجز تجريبي دون دفع أو إرسال فعلي.',
              'I understand this is a demo booking with no payment or real submission.'),
              style:const TextStyle(fontSize:13))),
        ],
        const SizedBox(height:24),
        FilledButton(
          key:const ValueKey('booking-next'),
          onPressed:submitted?null:(){
            if(!form.currentState!.validate())return;
            if(step<2){setState(()=>step++);return;}
            if(!consent){toast(context,s.t('يرجى تأكيد الموافقة على النسخة التجريبية','Please acknowledge the demo'));return;}
            if(discount!=s.discountFor(service,appliedCode)){
              setState(()=>discount=s.discountFor(service,appliedCode));
              toast(context,s.t('تغيّر توفر القسيمة. راجع الإجمالي وأكّد مرة أخرى.',
                'Voucher availability changed. Review the total and confirm again.'));return;
            }
            submitted=true;
            final booking=Booking(id:'DL-${1001+s.bookings.length}',serviceId:service.id,patientId:patientId!,
              date:DateTime(date.year,date.month,date.day,hour),phone:phone.trim(),
              address:mode=='home'?address.trim():'',notes:notes.trim(),mode:mode,payment:payment,
              total:total,discount:discount,voucherCode:discount>0?appliedCode:'');
            s.addBooking(booking);
            if(discount>0)s.useVoucher(appliedCode);
            Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder:(_)=>BookingDetailScreen(booking)));
          },
          child:Text(step==2?s.t('تأكيد الحجز التجريبي','Confirm demo booking'):s.t('متابعة','Continue'))),
        if(step>0) TextButton(onPressed:()=>setState(()=>step--),child:Text(s.t('الخطوة السابقة','Previous step'))),
      ])),
    ]);
  }
  Widget priceRow(String label,String value)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),
    child:Row(children:[Expanded(child:Text(label)),Text(value,style:const TextStyle(fontWeight:FontWeight.w800))]));
}
