import 'package:flutter/material.dart';

void main() {
runApp(const KitaiMasterApp());
}

class KitaiMasterApp extends StatelessWidget {
const KitaiMasterApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: '期待値マスター',
theme: ThemeData(
colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
useMaterial3: true,
),
home: const HomePage(),
);
}
}

// ==============================
// 機種データ
// ==============================

class MachineData {
String name;
int ceiling;
int resetCeiling;
String type;

MachineData({
required this.name,
required this.ceiling,
required this.resetCeiling,
required this.type,
});
}

// ==============================
// 台データ
// ==============================

class Machine {
final MachineData data;
final int game;
final int investment;
final int expectedValue;

Machine({
required this.data,
required this.game,
required this.investment,
required this.expectedValue,
});
}

// ==============================
// メイン画面
// ==============================

class HomePage extends StatefulWidget {
const HomePage({super.key});

@override
State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
final List<Machine> machines = [];

final List<MachineData> machineDataList = [
MachineData(
name: 'スマスロ北斗の拳',
ceiling: 1268,
resetCeiling: 800,
type: 'スマスロ',
),
MachineData(
name: 'モンキーターンV',
ceiling: 795,
resetCeiling: 795,
type: 'スマスロ',
),
MachineData(
name: 'ゴッドイーター リザレクション',
ceiling: 1000,
resetCeiling: 1000,
type: 'スマスロ',
),
];

void addMachine(Machine machine) {
setState(() {
machines.add(machine);

machines.sort(
(a, b) => b.expectedValue.compareTo(a.expectedValue),
);
});
}

String getRank(int index) {
if (index == 0) return '🥇';
if (index == 1) return '🥈';
if (index == 2) return '🥉';
return '${index + 1}位';
}

String getJudgement(int expectedValue) {
if (expectedValue >= 5000) {
return '🟢 打つべき';
}

if (expectedValue >= 2000) {
return '🟡 微妙';
}

return '🔴 打たない';
}

@override
Widget build(BuildContext context) {
final recommendedMachine =
machines.isNotEmpty ? machines.first : null;

return Scaffold(
appBar: AppBar(
title: const Text('期待値マスター'),
actions: [
IconButton(
icon: const Icon(Icons.settings),
tooltip: '機種データ',
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => MachineDataPage(
machineDataList: machineDataList,
),
),
);
},
),
],
),

body: machines.isEmpty
? const Center(
child: Text(
'まだ台が登録されていません',
style: TextStyle(fontSize: 18),
),
)
: ListView(
padding: const EdgeInsets.all(16),
children: [
if (recommendedMachine != null)
Card(
elevation: 4,
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'🏆 おすすめ台',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 15),

Text(
recommendedMachine.data.name,
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Text(
'${recommendedMachine.game}G',
style:
const TextStyle(fontSize: 18),
),

const SizedBox(height: 4),

Text(
'投資 ${recommendedMachine.investment}円',
style:
const TextStyle(fontSize: 18),
),

const SizedBox(height: 12),

Text(
'期待値 +${recommendedMachine.expectedValue}円',
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Text(
getJudgement(
recommendedMachine.expectedValue,
),
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
],
),
),
),

const SizedBox(height: 25),

const Text(
'📊 期待値ランキング',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 10),

...machines.asMap().entries.map(
(entry) {
final index = entry.key;
final machine = entry.value;

return Card(
margin:
const EdgeInsets.only(bottom: 10),
child: ListTile(
leading: Text(
getRank(index),
style: const TextStyle(
fontSize: 24,
),
),

title: Text(
machine.data.name,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),

subtitle: Text(
'${machine.game}G / 投資 ${machine.investment}円',
),

trailing: SizedBox(
width: 110,
child: Column(
mainAxisSize: MainAxisSize.min,
mainAxisAlignment:
MainAxisAlignment.center,
crossAxisAlignment:
CrossAxisAlignment.end,
children: [
Text(
'+${machine.expectedValue}円',
style: const TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),

Text(
getJudgement(
machine.expectedValue,
),
style: const TextStyle(
fontSize: 10,
fontWeight:
FontWeight.bold,
),
),
],
),
),
),
);
},
),
],
),

floatingActionButton:
FloatingActionButton.extended(
onPressed: () async {
final machine =
await Navigator.push<Machine>(
context,
MaterialPageRoute(
builder: (context) => AddMachinePage(
machineDataList: machineDataList,
),
),
);

if (machine != null) {
addMachine(machine);
}
},
icon: const Icon(Icons.add),
label: const Text('台を追加'),
),
);
}
}

// ==============================
// 台追加画面
// ==============================

class AddMachinePage extends StatefulWidget {
final List<MachineData> machineDataList;

const AddMachinePage({
super.key,
required this.machineDataList,
});

@override
State<AddMachinePage> createState() =>
_AddMachinePageState();
}

class _AddMachinePageState
extends State<AddMachinePage> {
final gameController = TextEditingController();
final investmentController = TextEditingController();

late MachineData selectedMachine;

@override
void initState() {
super.initState();

selectedMachine =
widget.machineDataList.first;
}

int calculateExpectedValue(int game) {
return game * 10;
}

@override
void dispose() {
gameController.dispose();
investmentController.dispose();
super.dispose();
}

void addMachine() {
final game =
int.tryParse(gameController.text.trim());

final investment =
int.tryParse(
investmentController.text.trim(),
);

if (game == null || investment == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content:
Text('ゲーム数と投資金額を入力してください'),
),
);

return;
}

final machine = Machine(
data: selectedMachine,
game: game,
investment: investment,
expectedValue:
calculateExpectedValue(game),
);

Navigator.pop(context, machine);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('台を追加'),
),

body: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
children: [
const Text(
'台の情報を入力',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 30),

DropdownButtonFormField<MachineData>(
value: selectedMachine,

decoration:
const InputDecoration(
labelText: '機種',
border: OutlineInputBorder(),
),

items: widget.machineDataList
.map(
(machine) {
return DropdownMenuItem(
value: machine,
child: Text(machine.name),
);
},
)
.toList(),

onChanged: (value) {
if (value != null) {
setState(() {
selectedMachine = value;
});
}
},
),

const SizedBox(height: 15),

Card(
child: ListTile(
title:
Text(selectedMachine.name),
subtitle: Text(
'タイプ：${selectedMachine.type}\n'
'通常天井：${selectedMachine.ceiling}G\n'
'リセット天井：${selectedMachine.resetCeiling}G',
),
),
),

const SizedBox(height: 20),

TextField(
controller: gameController,
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
labelText: '現在のゲーム数',
hintText: '例：500',
suffixText: 'G',
border: OutlineInputBorder(),
),
),

const SizedBox(height: 20),

TextField(
controller: investmentController,
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
labelText: '投資金額',
hintText: '例：10000',
suffixText: '円',
border: OutlineInputBorder(),
),
),

const SizedBox(height: 30),

SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: addMachine,
child: const Padding(
padding: EdgeInsets.all(14),
child: Text(
'追加する',
style:
TextStyle(fontSize: 18),
),
),
),
),
],
),
),
);
}
}

// ==============================
// 機種データ一覧
// ==============================

class MachineDataPage extends StatelessWidget {
final List<MachineData> machineDataList;

const MachineDataPage({
super.key,
required this.machineDataList,
});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('機種データ'),
),

body: ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: machineDataList.length,

itemBuilder:
(context, index) {
final machine =
machineDataList[index];

return Card(
margin:
const EdgeInsets.only(bottom: 12),

child: ListTile(
leading:
const Icon(Icons.casino),

title: Text(
machine.name,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 18,
),
),

subtitle: Text(
'タイプ：${machine.type}\n'
'通常天井：${machine.ceiling}G\n'
'リセット天井：${machine.resetCeiling}G',
),

trailing: const Icon(
Icons.arrow_forward_ios,
),

onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
MachineDetailPage(
machine: machine,
),
),
);
},
),
);
},
),
);
}
}

// ==============================
// 機種詳細
// ==============================

class MachineDetailPage
extends StatefulWidget {
final MachineData machine;

const MachineDetailPage({
super.key,
required this.machine,
});

@override
State<MachineDetailPage> createState() =>
_MachineDetailPageState();
}

class _MachineDetailPageState
extends State<MachineDetailPage> {
void editMachine() async {
final result =
await Navigator.push<MachineData>(
context,
MaterialPageRoute(
builder: (context) =>
EditMachinePage(
machine: widget.machine,
),
),
);

if (result != null) {
setState(() {});
}
}

@override
Widget build(BuildContext context) {
final machine = widget.machine;

return Scaffold(
appBar: AppBar(
title: Text(machine.name),
actions: [
IconButton(
icon:
const Icon(Icons.edit),
tooltip: '編集',
onPressed: editMachine,
),
],
),

body: ListView(
padding: const EdgeInsets.all(20),
children: [
Card(
child: Padding(
padding:
const EdgeInsets.all(20),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
machine.name,
style: const TextStyle(
fontSize: 25,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 20),

Text(
'タイプ：${machine.type}',
style: const TextStyle(
fontSize: 18,
),
),

const SizedBox(height: 10),

Text(
'通常天井：${machine.ceiling}G',
style: const TextStyle(
fontSize: 18,
),
),

const SizedBox(height: 10),

Text(
'リセット天井：${machine.resetCeiling}G',
style: const TextStyle(
fontSize: 18,
),
),
],
),
),
),

const SizedBox(height: 20),

const Card(
child: Padding(
padding:
EdgeInsets.all(20),
child: Text(
'📊 期待値計算データ\n\n'
'今後ここに実際の機種データを追加して、'
'期待値計算に使用します。',
style:
TextStyle(fontSize: 16),
),
),
),
],
),
);
}
}

// ==============================
// 機種データ編集
// ==============================

class EditMachinePage
extends StatefulWidget {
final MachineData machine;

const EditMachinePage({
super.key,
required this.machine,
});

@override
State<EditMachinePage> createState() =>
_EditMachinePageState();
}

class _EditMachinePageState
extends State<EditMachinePage> {
late TextEditingController
ceilingController;

late TextEditingController
resetCeilingController;

@override
void initState() {
super.initState();

ceilingController =
TextEditingController(
text: widget.machine.ceiling
.toString(),
);

resetCeilingController =
TextEditingController(
text: widget.machine
.resetCeiling
.toString(),
);
}

@override
void dispose() {
ceilingController.dispose();
resetCeilingController.dispose();
super.dispose();
}

void saveData() {
final ceiling =
int.tryParse(
ceilingController.text.trim(),
);

final resetCeiling =
int.tryParse(
resetCeilingController.text.trim(),
);

if (ceiling == null ||
resetCeiling == null) {
ScaffoldMessenger.of(context)
.showSnackBar(
const SnackBar(
content:
Text('数字を正しく入力してください'),
),
);

return;
}

widget.machine.ceiling = ceiling;
widget.machine.resetCeiling =
resetCeiling;

Navigator.pop(
context,
widget.machine,
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title:
const Text('機種データ編集'),
),

body: Padding(
padding:
const EdgeInsets.all(20),
child: Column(
children: [
Text(
widget.machine.name,
style: const TextStyle(
fontSize: 24,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 30),

TextField(
controller:
ceilingController,
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
labelText: '通常天井',
suffixText: 'G',
border:
OutlineInputBorder(),
),
),

const SizedBox(height: 20),

TextField(
controller:
resetCeilingController,
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
labelText: 'リセット天井',
suffixText: 'G',
border:
OutlineInputBorder(),
),
),

const SizedBox(height: 30),

SizedBox(
width: double.infinity,
child:
ElevatedButton.icon(
onPressed: saveData,
icon:
const Icon(Icons.save),
label: const Padding(
padding:
EdgeInsets.all(14),
child: Text(
'保存する',
style: TextStyle(
fontSize: 18,
),
),
),
),
),
],
),
),
);
}
}
