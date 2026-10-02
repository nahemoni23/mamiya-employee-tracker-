import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb{
  AppDb._();static final instance=AppDb._();late Database db;
  Future<void> init()async{
    final p=join(await getDatabasesPath(),'mamiya_employee_tracker.db');
    db=await openDatabase(p,version:1,onCreate:(d,v)async{
      await d.execute("CREATE TABLE records(id INTEGER PRIMARY KEY AUTOINCREMENT,date TEXT NOT NULL UNIQUE,status TEXT NOT NULL,ot_minutes INTEGER NOT NULL DEFAULT 0,vehicle INTEGER NOT NULL DEFAULT 1,fare REAL NOT NULL DEFAULT 0,note TEXT)");
      await d.execute("CREATE TABLE profile(id INTEGER PRIMARY KEY CHECK(id=1),name TEXT,company TEXT)");
      await d.insert('profile',{'id':1,'name':'','company':'Mamiya-OP (Bangladesh) Ltd.'});
    });
  }
  Future<int> insertRecord(Map<String,dynamic> x)async=>db.insert('records',x,conflictAlgorithm:ConflictAlgorithm.replace);
  Future<int> updateRecord(int id,Map<String,dynamic>x)=>db.update('records',x,where:'id=?',whereArgs:[id]);
  Future<int> deleteRecord(int id)=>db.delete('records',where:'id=?',whereArgs:[id]);
  Future<List<Map<String,dynamic>>> recordsForMonth(int y,int m){
    final start='$y-${m.toString().padLeft(2,'0')}-01';final last=DateTime(y,m+1,0);
    final end='$y-${m.toString().padLeft(2,'0')}-${last.day.toString().padLeft(2,'0')}';
    return db.query('records',where:'date BETWEEN ? AND ?',whereArgs:[start,end],orderBy:'date DESC');
  }
  Future<Map<String,dynamic>> monthStats(int y,int m)async{
    final rows=await recordsForMonth(y,m);int present=0,absent=0,leave=0,yes=0,no=0,ot=0;double fare=0;
    for(final r in rows){if(r['status']=='present')present++;if(r['status']=='absent')absent++;if(r['status']=='leave')leave++;ot+=r['ot_minutes'] as int;final v=r['vehicle'] as int;if(v==1)yes++;if(v==0)no++;fare+=(r['fare'] as num).toDouble();}
    return {'total':rows.length,'present':present,'absent':absent,'leave':leave,'vehicleYes':yes,'vehicleNo':no,'otMinutes':ot,'fare':fare};
  }
  Future<List<Map<String,dynamic>>> weeklyFare(int y,int m)async{
    final rows=await recordsForMonth(y,m);final Map<int,Map<String,dynamic>> w={};
    for(final r in rows){final d=DateTime.parse(r['date']);final n=((d.day-1)~/7)+1;w.putIfAbsent(n,()=>{'days':0,'fare':0.0});if((r['fare'] as num)>0)w[n]!['days']++;w[n]!['fare']=(w[n]!['fare'] as double)+(r['fare'] as num).toDouble();}
    return w.entries.map((e)=>{'label':'সপ্তাহ ${e.key}','days':e.value['days'],'fare':e.value['fare']}).toList();
  }
  Future<Map<String,dynamic>> profile()async{final r=await db.query('profile',where:'id=1',limit:1);return r.isEmpty?{}:r.first;}
  Future<void> saveProfile(String n,String c)async=>db.update('profile',{'name':n,'company':c},where:'id=1');
}
