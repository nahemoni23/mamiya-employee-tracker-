import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb.instance.init();
  runApp(const MamiyaTrackerApp());
}

class MamiyaTrackerApp extends StatelessWidget {
  const MamiyaTrackerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Mamiya Employee Tracker',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF087F5B)),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab=0;
  void refresh()=>setState((){});
  @override
  Widget build(BuildContext context) {
    final pages=[
      DashboardPage(onChanged: refresh),
      RecordsPage(onChanged: refresh),
      ReportsPage(),
      SettingsPage(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Mamiya Employee Tracker',style: TextStyle(fontWeight: FontWeight.bold))),
      body: pages[tab],
      floatingActionButton: tab==1 ? FloatingActionButton.extended(
        onPressed: () async { await Navigator.push(context,MaterialPageRoute(builder:(_)=>const AddRecordPage())); refresh(); },
        icon: const Icon(Icons.add), label: const Text('নতুন রেকর্ড'),
      ):null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,onDestinationSelected:(i)=>setState(()=>tab=i),
        destinations: const [
          NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'Dashboard'),
          NavigationDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month),label:'রেকর্ড'),
          NavigationDestination(icon:Icon(Icons.bar_chart_outlined),selectedIcon:Icon(Icons.bar_chart),label:'রিপোর্ট'),
          NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:'সেটিংস'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final VoidCallback onChanged;
  const DashboardPage({super.key,required this.onChanged});
  @override Widget build(BuildContext context)=>FutureBuilder(
    future: AppDb.instance.monthStats(DateTime.now().year,DateTime.now().month),
    builder:(context,snap){
      if(!snap.hasData)return const Center(child:CircularProgressIndicator());
      final s=snap.data!;
      return RefreshIndicator(
        onRefresh:()async=>onChanged(),
        child:ListView(padding:const EdgeInsets.all(16),children:[
          Text(DateFormat('MMMM yyyy').format(DateTime.now()),style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          Card(child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[
            CircleAvatar(radius:28,child:Text('${s['present']}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))),
            const SizedBox(width:14),Expanded(child:Text('${s['present']} দিন উপস্থিত • ${s['absent']} দিন অনুপস্থিত • ${s['leave']} দিন ছুটি')),
          ]))),
          const SizedBox(height:12),
          GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
            mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.55,children:[
              StatCard('মোট রেকর্ড','${s['total']}',Icons.event_note),
              StatCard('উপস্থিত','${s['present']}',Icons.check_circle),
              StatCard('অনুপস্থিত','${s['absent']}',Icons.cancel_outlined),
              StatCard('ছুটি','${s['leave']}',Icons.beach_access),
              StatCard('মোট OT',fmt(s['otMinutes']),Icons.timer),
              StatCard('গাড়ি পেয়েছেন','${s['vehicleYes']}',Icons.directions_bus),
              StatCard('গাড়ি পাননি','${s['vehicleNo']}',Icons.no_transfer),
              StatCard('গাড়ি ভাড়া','৳${(s['fare'] as num).toStringAsFixed(0)}',Icons.payments),
            ]),
          const SizedBox(height:16),
          const Card(child:ListTile(leading:Icon(Icons.offline_bolt),title:Text('সম্পূর্ণ Offline'),subtitle:Text('সব তথ্য ফোনের স্থানীয় SQLite database-এ সংরক্ষিত হয়।'))),
        ]),
      );
    });
}
class StatCard extends StatelessWidget {
  final String title,value; final IconData icon;
  const StatCard(this.title,this.value,this.icon,{super.key});
  @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[
    Icon(icon,size:28),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
      Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(title,maxLines:1,overflow:TextOverflow.ellipsis)
    ]))
  ])));
}

class RecordsPage extends StatefulWidget {
  final VoidCallback onChanged; const RecordsPage({super.key,required this.onChanged});
  @override State<RecordsPage> createState()=>_RecordsPageState();
}
class _RecordsPageState extends State<RecordsPage>{
  DateTime month=DateTime(DateTime.now().year,DateTime.now().month);
  @override Widget build(BuildContext context)=>FutureBuilder(
    future:AppDb.instance.recordsForMonth(month.year,month.month),
    builder:(context,snap){
      if(!snap.hasData)return const Center(child:CircularProgressIndicator());
      final rows=snap.data!;
      return ListView(padding:const EdgeInsets.all(12),children:[
        MonthSelector(month:month,onChanged:(m)=>setState(()=>month=m)),
        const SizedBox(height:8),
        if(rows.isEmpty)const Padding(padding:EdgeInsets.all(40),child:Center(child:Text('এই মাসে কোনো রেকর্ড নেই। + চাপ দিয়ে যোগ করুন।'))),
        ...rows.map((r)=>RecordTile(record:r,onEdit:()async{
          await Navigator.push(context,MaterialPageRoute(builder:(_)=>AddRecordPage(existing:r)));setState((){});widget.onChanged();
        },onDelete:()async{
          await AppDb.instance.deleteRecord(r['id']);setState((){});widget.onChanged();
        }))
      ]);
    });
}
class RecordTile extends StatelessWidget{
  final Map<String,dynamic> record; final VoidCallback onEdit,onDelete;
  const RecordTile({super.key,required this.record,required this.onEdit,required this.onDelete});
  @override Widget build(BuildContext context){
    final d=DateTime.parse(record['date']); final v=record['vehicle']; final fare=(record['fare'] as num).toDouble();
    return Card(child:ListTile(
      leading:CircleAvatar(child:Text(DateFormat('dd').format(d))),
      title:Text(DateFormat('EEE, dd MMM yyyy').format(d),style:const TextStyle(fontWeight:FontWeight.bold)),
      subtitle:Wrap(spacing:6,children:[
        Chip(label:Text(statusLabel(record['status']))),Chip(label:Text('OT ${fmt(record['ot_minutes'])}')),
        if(v==1)const Chip(label:Text('🚐 গাড়ি পেয়েছেন')),
        if(v==0)const Chip(label:Text('🚫 গাড়ি পাননি')),
        if(fare>0)Chip(label:Text('ভাড়া ৳${fare.toStringAsFixed(0)}')),
      ]),
      trailing:PopupMenuButton<String>(onSelected:(x){if(x=='edit')onEdit();else onDelete();},itemBuilder:(_)=>const[
        PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))
      ]),
    ));
  }
}

class AddRecordPage extends StatefulWidget{
  final Map<String,dynamic>? existing; const AddRecordPage({super.key,this.existing});
  @override State<AddRecordPage> createState()=>_AddRecordPageState();
}
class _AddRecordPageState extends State<AddRecordPage>{
  late DateTime date;String status='present';int ot=0;int vehicle=1;
  final fare=TextEditingController(),note=TextEditingController();
  @override void initState(){super.initState();final r=widget.existing;date=r==null?DateTime.now():DateTime.parse(r['date']);status=r?['status']??'present';ot=r?['ot_minutes']??0;vehicle=(r?['vehicle']==0)?0:1;fare.text=(r?['fare']??0)==0?'':'${r?['fare']}';note.text=r?['note']??'';}
  @override void dispose(){fare.dispose();note.dispose();super.dispose();}
  Future<void> save()async{
    final data={'date':DateFormat('yyyy-MM-dd').format(date),'status':status,'ot_minutes':status=='present'?ot:0,'vehicle':status=='absent'?-1:vehicle,'fare':status=='absent'?0:double.tryParse(fare.text)??0,'note':note.text.trim()};
    if(widget.existing==null)await AppDb.instance.insertRecord(data);else await AppDb.instance.updateRecord(widget.existing!['id'],data);
    if(mounted)Navigator.pop(context);
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:Text(widget.existing==null?'নতুন দৈনিক রেকর্ড':'রেকর্ড Edit')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      ListTile(contentPadding:EdgeInsets.zero,title:const Text('তারিখ'),subtitle:Text(DateFormat('dd MMMM yyyy').format(date)),trailing:FilledButton.tonal(onPressed:()async{
        final d=await showDatePicker(context:c,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)setState(()=>date=d);
      },child:const Text('তারিখ'))),
      const SizedBox(height:10),const Text('উপস্থিতির অবস্থা',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:6),
      SegmentedButton<String>(segments:const[
        ButtonSegment(value:'present',label:Text('উপস্থিত'),icon:Icon(Icons.check)),
        ButtonSegment(value:'absent',label:Text('অনুপস্থিত'),icon:Icon(Icons.close)),
        ButtonSegment(value:'leave',label:Text('ছুটি'),icon:Icon(Icons.beach_access)),
      ],selected:{status},onSelectionChanged:(v)=>setState(()=>status=v.first)),
      if(status=='present')...[
        const SizedBox(height:18),Text('OT: ${fmt(ot)}',style:const TextStyle(fontWeight:FontWeight.bold)),
        Slider(value:ot.toDouble(),min:0,max:180,divisions:36,label:'${ot~/60}h ${ot%60}m',onChanged:(v)=>setState(()=>ot=v.round())),
        Center(child:Text('সর্বোচ্চ ৩ ঘণ্টা • $ot মিনিট')),
        const SizedBox(height:10),const Text('অফিসের গাড়ি',style:TextStyle(fontWeight:FontWeight.bold)),
        const SizedBox(height:6),
        SegmentedButton<int>(segments:const[
          ButtonSegment(value:1,label:Text('পেয়েছি'),icon:Icon(Icons.directions_bus)),
          ButtonSegment(value:0,label:Text('পাইনি'),icon:Icon(Icons.no_transfer)),
        ],selected:{vehicle},onSelectionChanged:(v)=>setState(()=>vehicle=v.first)),
        const SizedBox(height:12),
        TextField(controller:fare,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'গাড়ি ভাড়া',prefixText:'৳ ',hintText:'নিজে ভাড়া দিলে')),
      ],
      const SizedBox(height:12),TextField(controller:note,maxLines:2,decoration:const InputDecoration(labelText:'নোট (ঐচ্ছিক)')),
      const SizedBox(height:24),FilledButton.icon(onPressed:save,icon:const Icon(Icons.save),label:Text(widget.existing==null?'রেকর্ড সংরক্ষণ':'পরিবর্তন সংরক্ষণ'))
    ])
  );
}

class ReportsPage extends StatefulWidget{const ReportsPage({super.key});@override State<ReportsPage> createState()=>_ReportsPageState();}
class _ReportsPageState extends State<ReportsPage>{
  DateTime month=DateTime(DateTime.now().year,DateTime.now().month);
  @override Widget build(BuildContext c)=>FutureBuilder(
    future:AppDb.instance.monthStats(month.year,month.month),builder:(c,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());final x=s.data!;
      return ListView(padding:const EdgeInsets.all(16),children:[
        MonthSelector(month:month,onChanged:(m)=>setState(()=>month=m)),const SizedBox(height:12),
        const Text('মাসিক রিপোর্ট',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        ReportRow('মোট রেকর্ড','${x['total']} দিন'),ReportRow('উপস্থিত','${x['present']} দিন'),ReportRow('অনুপস্থিত','${x['absent']} দিন'),ReportRow('ছুটি','${x['leave']} দিন'),
        ReportRow('মোট OT',fmt(x['otMinutes'])),ReportRow('গাড়ি পেয়েছেন','${x['vehicleYes']} দিন'),ReportRow('গাড়ি পাননি','${x['vehicleNo']} দিন'),ReportRow('মোট গাড়ি ভাড়া','৳${(x['fare'] as num).toStringAsFixed(2)}'),
        const SizedBox(height:14),Card(child:ListTile(title:const Text('সাপ্তাহিক গাড়ি ভাড়া'),subtitle:const Text('সপ্তাহভিত্তিক খরচ দেখুন'),trailing:FilledButton(onPressed:()=>showWeekly(c),child:const Text('দেখুন'))))
      ]);
    });
  void showWeekly(BuildContext c)async{final rows=await AppDb.instance.weeklyFare(month.year,month.month);if(!c.mounted)return;showModalBottomSheet(context:c,showDragHandle:true,builder:(_)=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('সাপ্তাহিক গাড়ি ভাড়া',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),...rows.map((r)=>Card(child:ListTile(title:Text(r['label']),subtitle:Text('${r['days']} দিন'),trailing:Text('৳${(r['fare'] as num).toStringAsFixed(0)}',style:const TextStyle(fontWeight:FontWeight.bold)))))
  ]));}
}
class ReportRow extends StatelessWidget{final String a,b;const ReportRow(this.a,this.b,{super.key});@override Widget build(BuildContext c)=>Card(child:ListTile(title:Text(a),trailing:Text(b,style:const TextStyle(fontWeight:FontWeight.bold))));}

class MonthSelector extends StatelessWidget{
  final DateTime month;final ValueChanged<DateTime> onChanged;const MonthSelector({super.key,required this.month,required this.onChanged});
  @override Widget build(BuildContext c)=>Card(child:Row(children:[
    IconButton(onPressed:()=>onChanged(DateTime(month.year,month.month-1)),icon:const Icon(Icons.chevron_left)),
    Expanded(child:Center(child:Text(DateFormat('MMMM yyyy').format(month),style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)))),
    IconButton(onPressed:()=>onChanged(DateTime(month.year,month.month+1)),icon:const Icon(Icons.chevron_right))
  ]));
}

class SettingsPage extends StatefulWidget{const SettingsPage({super.key});@override State<SettingsPage> createState()=>_SettingsPageState();}
class _SettingsPageState extends State<SettingsPage>{
  final name=TextEditingController(),company=TextEditingController(text:'Mamiya-OP (Bangladesh) Ltd.');
  bool loaded=false;
  @override void dispose(){name.dispose();company.dispose();super.dispose();}
  @override Widget build(BuildContext c)=>FutureBuilder(future:loaded?null:AppDb.instance.profile(),builder:(c,s){
    if(s.hasData&&!loaded){name.text=s.data!['name']??'';company.text=s.data!['company']??company.text;loaded=true;}
    return ListView(padding:const EdgeInsets.all(16),children:[
      const Text('প্রোফাইল ও সেটিংস',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const SizedBox(height:16),
      TextField(controller:name,decoration:const InputDecoration(labelText:'কর্মীর নাম')),const SizedBox(height:12),
      TextField(controller:company,decoration:const InputDecoration(labelText:'কোম্পানির নাম')),const SizedBox(height:16),
      FilledButton.icon(onPressed:()async{await AppDb.instance.saveProfile(name.text.trim(),company.text.trim());if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('প্রোফাইল সংরক্ষণ হয়েছে।')));},icon:const Icon(Icons.save),label:const Text('সংরক্ষণ')),
      const SizedBox(height:18),const Card(child:ListTile(leading:Icon(Icons.offline_bolt),title:Text('Offline database'),subtitle:Text('ইন্টারনেট ছাড়াই Attendance, OT ও Transport হিসাব রাখা যাবে।')))
    ]);
  });
}

String statusLabel(String s)=>{'present':'উপস্থিত','absent':'অনুপস্থিত','leave':'ছুটি'}[s]??s;
String fmt(int m){final h=m~/60,r=m%60;if(h==0)return '$r মিনিট';if(r==0)return '$h ঘণ্টা';return '$h ঘণ্টা $r মিনিট';}
