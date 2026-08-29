import 'package:flutter/material.dart';

void main() {
runApp(const ExpectedValueMasterApp());
}

class ExpectedValueMasterApp extends StatelessWidget {
const ExpectedValueMasterApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: '期待値マスター',
theme: ThemeData(
colorScheme: ColorScheme.fromSeed(
seedColor: Colors.blue,
),
useMaterial3: true,
),
home: const HomePage(),
);
}
}

// ============================================================
// 機種データ
// ============================================================

class MachineData {
final String name;
final String type;
final int ceiling;
final int resetCeiling;

const MachineData({
required this.name,
required this.type,
required this.ceiling,
required this.resetCeiling,
});
}

// ============================================================
// 登録している機種
// ※あとから実際の機種に変更できる
// ============================================================

const List<MachineData> machineDataList = [
MachineData(
name: 'サンプル機種A',
type: 'AT',
ceiling: 1000,
resetCeiling: 500,
),
MachineData(
name: 'サンプル機種B',
type: 'AT',
ceiling: 1200,
resetCeiling: 600,
),
MachineData(
name: 'サンプル機種C',
type: 'AT',
ceiling: 1500,
resetCeiling: 750,
),
MachineData(
name: 'サンプル機種D',
type: 'ART',
ceiling: 999,
resetCeiling: 400,
),
];

// ============================================================
// 計算結果
// ============================================================

class MachineResult {
final MachineData machine;
final int game;
final int investment;
final int expectedValue;

const MachineResult({
required this.machine,
required this.game,
required this.investment,
required this.expectedValue,
});
}

// ============================================================
// ホーム画面
// ============================================================

class HomePage extends StatefulWidget {
const HomePage({super.key});

@override
State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
final List<MachineResult> machines = [];

Future<void> addMachine() async {
final MachineResult? result =
await Navigator.push<MachineResult>(
context,
MaterialPageRoute(
builder: (context) => const AddMachinePage(),
),
);

if (result != null) {
setState(() {
machines.add(result);
});
}
}

void deleteMachine(int index) {
setState(() {
machines.removeAt(index);
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'期待値マスター',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
centerTitle: true,
),
body: machines.isEmpty
? const Center(
child: Text(
'まだ台がありません\n'
'右下の「台を追加する」から追加してください',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 17,
),
),
)
: ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: machines.length,
itemBuilder: (context, index) {
final MachineResult result =
machines[index];

final bool positive =
result.expectedValue >= 0;

return Card(
margin: const EdgeInsets.only(
bottom: 12,
),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(
child: Text(
result.machine.name,
style: const TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),
),
IconButton(
onPressed: () {
deleteMachine(index);
},
icon: const Icon(
Icons.delete_outline,
),
),
],
),

Text(
'タイプ：${result.machine.type}',
),

const Divider(),

Text(
'現在ゲーム数：${result.game}G',
),

Text(
'通常天井：${result.machine.ceiling}G',
),

Text(
'リセット天井：'
'${result.machine.resetCeiling}G',
),

Text(
'投資額：${result.investment}円',
),

const SizedBox(height: 12),

Container(
width: double.infinity,
padding:
const EdgeInsets.all(14),
decoration: BoxDecoration(
borderRadius:
BorderRadius.circular(12),
color: positive
? Colors.green
.withOpacity(0.12)
: Colors.red
.withOpacity(0.12),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'期待値',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
'${result.expectedValue}円',
style: TextStyle(
fontSize: 28,
fontWeight:
FontWeight.bold,
color: positive
? Colors.green
: Colors.red,
),
),
],
),
),
],
),
),
);
},
),
floatingActionButton:
FloatingActionButton.extended(
onPressed: addMachine,
icon: const Icon(Icons.add),
label: const Text('台を追加する'),
),
);
}
}

// ============================================================
// 台追加画面
// ============================================================

class AddMachinePage extends StatefulWidget {
const AddMachinePage({super.key});

@override
State<AddMachinePage> createState() =>
_AddMachinePageState();
}

class _AddMachinePageState
extends State<AddMachinePage> {
late MachineData selectedMachine;

final TextEditingController gameController =
TextEditingController();

final TextEditingController investmentController =
TextEditingController();

@override
void initState() {
super.initState();

selectedMachine =
machineDataList.first;
}

@override
void dispose() {
gameController.dispose();
investmentController.dispose();

super.dispose();
}

// ==========================================================
// 期待値計算
// ==========================================================

int calculateExpectedValue({
required int game,
required int investment,
required int ceiling,
}) {
int remaining = ceiling - game;

if (remaining < 0) {
remaining = 0;
}

// 現段階ではテスト用の簡易計算
final int value =
5000 - (remaining * 5) - investment;

return value;
}

// ==========================================================
// 台を追加
// ==========================================================

void addMachine() {
final int? game = int.tryParse(
gameController.text.trim(),
);

final int? investment = int.tryParse(
investmentController.text.trim(),
);

if (game == null) {
showMessage(
'現在ゲーム数を入力してください',
);
return;
}

if (investment == null) {
showMessage(
'投資額を入力してください',
);
return;
}

final int expectedValue =
calculateExpectedValue(
game: game,
investment: investment,
ceiling: selectedMachine.ceiling,
);

final MachineResult result =
MachineResult(
machine: selectedMachine,
game: game,
investment: investment,
expectedValue: expectedValue,
);

Navigator.pop(
context,
result,
);
}

void showMessage(String message) {
ScaffoldMessenger.of(context)
.showSnackBar(
SnackBar(
content: Text(message),
),
);
}

// ==========================================================
// 画面
// ==========================================================

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('台を追加'),
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'機種を選択',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

DropdownButtonFormField<MachineData>(
value: selectedMachine,
decoration:
const InputDecoration(
border: OutlineInputBorder(),
hintText: '機種を選択',
),
items: machineDataList
.map(
(MachineData machine) {
return DropdownMenuItem<
MachineData>(
value: machine,
child: Text(
machine.name,
),
);
},
).toList(),
onChanged: (
MachineData? value,
) {
if (value == null) {
return;
}

setState(() {
selectedMachine = value;
});
},
),

const SizedBox(height: 16),

// --------------------------------------------------
// 選択した機種の情報
// --------------------------------------------------

Card(
child: Padding(
padding:
const EdgeInsets.all(16),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
selectedMachine.name,
style: const TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 8),

Text(
'タイプ：'
'${selectedMachine.type}',
),

Text(
'通常天井：'
'${selectedMachine.ceiling}G',
),

Text(
'リセット天井：'
'${selectedMachine.resetCeiling}G',
),
],
),
),
),

const SizedBox(height: 24),

// --------------------------------------------------
// 現在ゲーム数
// --------------------------------------------------

const Text(
'現在ゲーム数',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

TextField(
controller: gameController,
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
border: OutlineInputBorder(),
hintText: '例：500',
suffixText: 'G',
),
),

const SizedBox(height: 24),

// --------------------------------------------------
// 投資額
// --------------------------------------------------

const Text(
'投資額',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

TextField(
controller: investmentController,
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
border: OutlineInputBorder(),
hintText: '例：10000',
suffixText: '円',
),
),

const SizedBox(height: 32),

// --------------------------------------------------
// 追加ボタン
// --------------------------------------------------

SizedBox(
width: double.infinity,
height: 55,
child: ElevatedButton.icon(
onPressed: addMachine,
icon: const Icon(
Icons.calculate,
),
label: const Text(
'期待値を計算して追加',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
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
