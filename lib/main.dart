import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
runApp(const ExpectedValueMasterApp());
}

class ExpectedValueMasterApp extends StatelessWidget {
const ExpectedValueMasterApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: '期待値マスター',
debugShowCheckedModeBanner: false,
theme: ThemeData(
useMaterial3: true,
colorSchemeSeed: Colors.blue,
scaffoldBackgroundColor: const Color(0xFFF5F7FA),
inputDecorationTheme: const InputDecorationTheme(
border: OutlineInputBorder(),
),
),
home: const HomePage(),
);
}
}

enum MachineCategory {
slot,
pachinko,
}

extension MachineCategoryExtension on MachineCategory {
String get label {
switch (this) {
case MachineCategory.slot:
return 'パチスロ';
case MachineCategory.pachinko:
return 'パチンコ';
}
}

IconData get icon {
switch (this) {
case MachineCategory.slot:
return Icons.casino;
case MachineCategory.pachinko:
return Icons.sports_esports;
}
}

String get value {
switch (this) {
case MachineCategory.slot:
return 'slot';
case MachineCategory.pachinko:
return 'pachinko';
}
}

static MachineCategory fromValue(String value) {
return value == 'pachinko'
? MachineCategory.pachinko
: MachineCategory.slot;
}
}

class MachineData {
final String name;
final String type;
final MachineCategory category;

final int ceiling;
final int resetCeiling;
final double payoutRate;
final int gamesPerHour;
final int initialProbability;
final int averagePayout;
final int investmentPerGame;
final double gamesPer50Coins;

final int startGame;
final double probability;
final int averageBall;
final double ballPrice;
final double startPer250;

const MachineData.slot({
required this.name,
required this.type,
required this.ceiling,
required this.resetCeiling,
required this.payoutRate,
required this.gamesPerHour,
required this.initialProbability,
required this.averagePayout,
required this.investmentPerGame,
required this.gamesPer50Coins,
}) : category = MachineCategory.slot,
startGame = 0,
probability = 0,
averageBall = 0,
ballPrice = 0,
startPer250 = 0;

const MachineData.pachinko({
required this.name,
required this.type,
required this.startGame,
required this.probability,
required this.averageBall,
required this.ballPrice,
required this.startPer250,
}) : category = MachineCategory.pachinko,
ceiling = 0,
resetCeiling = 0,
payoutRate = 0,
gamesPerHour = 0,
initialProbability = 0,
averagePayout = 0,
investmentPerGame = 0,
gamesPer50Coins = 0;

Map<String, dynamic> toJson() {
return {
'name': name,
'type': type,
'category': category.value,
'ceiling': ceiling,
'resetCeiling': resetCeiling,
'payoutRate': payoutRate,
'gamesPerHour': gamesPerHour,
'initialProbability': initialProbability,
'averagePayout': averagePayout,
'investmentPerGame': investmentPerGame,
'gamesPer50Coins': gamesPer50Coins,
'startGame': startGame,
'probability': probability,
'averageBall': averageBall,
'ballPrice': ballPrice,
'startPer250': startPer250,
};
}

factory MachineData.fromJson(Map<String, dynamic> json) {
final category = MachineCategoryExtension.fromValue(
json['category']?.toString() ?? 'slot',
);

if (category == MachineCategory.pachinko) {
return MachineData.pachinko(
name: json['name']?.toString() ?? '',
type: json['type']?.toString() ?? '',
startGame: _toInt(json['startGame']),
probability: _toDouble(json['probability']),
averageBall: _toInt(json['averageBall']),
ballPrice: _toDouble(json['ballPrice']),
startPer250: _toDouble(json['startPer250']),
);
}

return MachineData.slot(
name: json['name']?.toString() ?? '',
type: json['type']?.toString() ?? '',
ceiling: _toInt(json['ceiling']),
resetCeiling: _toInt(json['resetCeiling']),
payoutRate: _toDouble(json['payoutRate']),
gamesPerHour: _toInt(json['gamesPerHour']),
initialProbability: _toInt(json['initialProbability']),
averagePayout: _toInt(json['averagePayout']),
investmentPerGame: _toInt(json['investmentPerGame']),
gamesPer50Coins: _toDouble(json['gamesPer50Coins']),
);
}

static int _toInt(dynamic value) {
if (value is int) return value;
if (value is double) return value.round();
return int.tryParse(value?.toString() ?? '') ?? 0;
}

static double _toDouble(dynamic value) {
if (value is double) return value;
if (value is int) return value.toDouble();
return double.tryParse(value?.toString() ?? '') ?? 0;
}
}

const String machineDataKey = 'machine_data_list';

List<MachineData> machineDataList = [];

Future<void> saveMachineData() async {
final prefs = await SharedPreferences.getInstance();

await prefs.setString(
machineDataKey,
jsonEncode(
machineDataList.map((machine) => machine.toJson()).toList(),
),
);
}

Future<void> loadMachineData() async {
final prefs = await SharedPreferences.getInstance();
final saved = prefs.getString(machineDataKey);

if (saved == null || saved.isEmpty) {
machineDataList = _defaultMachines();
await saveMachineData();
return;
}

try {
final decoded = jsonDecode(saved);

if (decoded is List) {
machineDataList = decoded
.map(
(item) => MachineData.fromJson(
Map<String, dynamic>.from(item),
),
)
.toList();
}
} catch (_) {
machineDataList = _defaultMachines();
}

if (machineDataList.isEmpty) {
machineDataList = _defaultMachines();
await saveMachineData();
}
}

List<MachineData> _defaultMachines() {
return [
const MachineData.slot(
name: 'サンプルスロット',
type: 'AT',
ceiling: 1000,
resetCeiling: 500,
payoutRate: 110,
gamesPerHour: 800,
initialProbability: 200,
averagePayout: 500,
investmentPerGame: 20,
gamesPer50Coins: 50,
),
const MachineData.pachinko(
name: 'サンプルパチンコ',
type: 'LT',
startGame: 1000,
probability: 0.00313,
averageBall: 1500,
ballPrice: 4,
startPer250: 19,
),
];
}

double calculateSlotExpectedValue({
required int currentGame,
required int ceiling,
required double payoutRate,
required int initialProbability,
required int averagePayout,
required int investmentPerGame,
}) {
if (ceiling <= 0 || initialProbability <= 0) {
return 0;
}

final remaining = ceiling - currentGame;

if (remaining <= 0) {
return 0;
}

final expectedHits =
remaining / initialProbability;

final expectedCoins =
expectedHits * averagePayout;

final correctedCoins =
expectedCoins * payoutRate / 100;

final expectedReturn =
correctedCoins * 20;

final investment =
remaining * investmentPerGame;

return expectedReturn - investment;
}

double calculatePachinkoExpectedValue({
required double currentRate,
required double border,
required double exchangeRate,
required double investment,
required int games,
}) {
if (currentRate <= 0 || border <= 0) {
return 0;
}

final rateDifference =
currentRate - border;

final base =
rateDifference / border;

return investment +
(base * games * exchangeRate * 10);
}

double calculatePachinkoHourlyValue({
required double expectedValue,
required double currentRate,
}) {
if (currentRate <= 0) {
return expectedValue;
}

final gamesPerHour =
currentRate * 4;

if (gamesPerHour <= 0) {
return expectedValue;
}

return expectedValue * gamesPerHour / 100;
}

class MachineResult {
final MachineData machine;
final int game;
final int investment;
final bool isReset;
final double expectedValue;

const MachineResult({
required this.machine,
required this.game,
required this.investment,
required this.isReset,
required this.expectedValue,
});

int get targetGame {
if (machine.category == MachineCategory.slot) {
return isReset
? machine.resetCeiling
: machine.ceiling;
}

return machine.startGame;
}

int get remainingGame {
final value = targetGame - game;
return value < 0 ? 0 : value;
}

double get hourlyValue {
if (remainingGame <= 0) {
return expectedValue;
}

final gamesPerHour =
machine.category == MachineCategory.slot
? machine.gamesPerHour
: 600;

if (gamesPerHour <= 0) {
return expectedValue;
}

final hours =
remainingGame / gamesPerHour;

if (hours <= 0) {
return expectedValue;
}

return expectedValue / hours;
}
}

MachineResult calculateMachineResult({
required MachineData machine,
required int currentGame,
required bool isReset,
}) {
if (machine.category == MachineCategory.slot) {
final ceiling =
isReset
? machine.resetCeiling
: machine.ceiling;

final remaining =
(ceiling - currentGame)
.clamp(0, 999999);

if (remaining <= 0) {
return MachineResult(
machine: machine,
game: currentGame,
investment: 0,
isReset: isReset,
expectedValue: 0,
);
}

final investment =
remaining * machine.investmentPerGame;

final expectedValue =
calculateSlotExpectedValue(
currentGame: currentGame,
ceiling: ceiling,
payoutRate: machine.payoutRate,
initialProbability:
machine.initialProbability,
averagePayout:
machine.averagePayout,
investmentPerGame:
machine.investmentPerGame,
);

return MachineResult(
machine: machine,
game: currentGame,
investment: investment,
isReset: isReset,
expectedValue:
expectedValue.roundToDouble(),
);
}

final remaining =
(machine.startGame - currentGame)
.clamp(0, 999999);

if (remaining <= 0) {
return MachineResult(
machine: machine,
game: currentGame,
investment: 0,
isReset: false,
expectedValue: 0,
);
}

final expectedHits =
remaining * machine.probability;

final expectedBalls =
expectedHits * machine.averageBall;

final expectedReturn =
expectedBalls * machine.ballPrice;

final investment =
((remaining / machine.startPer250) * 1000)
.ceil();

return MachineResult(
machine: machine,
game: currentGame,
investment: investment,
isReset: false,
expectedValue:
(expectedReturn - investment)
.roundToDouble(),
);
}

class HomePage extends StatefulWidget {
const HomePage({super.key});

@override
State<HomePage> createState() =>
_HomePageState();
}

class _HomePageState
extends State<HomePage> {
final List<MachineResult> results = [];

bool loading = true;

@override
void initState() {
super.initState();
initialize();
}

Future<void> initialize() async {
await loadMachineData();

if (!mounted) return;

setState(() {
loading = false;
});
}

Future<void> openAddCalculation() async {
if (machineDataList.isEmpty) {
showMessage(
'先に機種データを登録してください',
);
return;
}

final result =
await Navigator.push<MachineResult>(
context,
MaterialPageRoute(
builder: (_) =>
const AddCalculationPage(),
),
);

if (result == null) return;

setState(() {
results.add(result);
});
}

Future<void> openCompare() async {
if (machineDataList.isEmpty) {
showMessage(
'先に機種データを登録してください',
);
return;
}

final compareResults =
await Navigator.push<List<MachineResult>>(
context,
MaterialPageRoute(
builder: (_) =>
const ComparePage(),
),
);

if (compareResults == null ||
compareResults.isEmpty) {
return;
}

setState(() {
results.addAll(compareResults);
});
}

Future<void> openMachineData() async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const MachineDataPage(),
),
);

if (!mounted) return;

setState(() {});
}

void openRanking() {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
RankingPage(
results: results,
),
),
);
}

void deleteResult(int index) {
setState(() {
results.removeAt(index);
});
}

void showMessage(String message) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
),
);
}

@override
Widget build(BuildContext context) {
if (loading) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
);
}

return Scaffold(
appBar: AppBar(
title: const Text(
'期待値マスター',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
actions: [
IconButton(
tooltip: '機種データ',
onPressed: openMachineData,
icon: const Icon(
Icons.settings,
),
),
IconButton(
tooltip: 'ランキング',
onPressed: openRanking,
icon: const Icon(
Icons.emoji_events,
),
),
],
),
body: results.isEmpty
? _buildEmpty()
: ListView(
padding:
const EdgeInsets.all(16),
children: [
_buildSummary(),
const SizedBox(height: 16),
...List.generate(
results.length,
(index) =>
MachineResultCard(
result:
results[index],
onDelete: () =>
deleteResult(index),
),
),
],
),
floatingActionButton:
_buildFloatingButtons(),
);
}

Widget _buildFloatingButtons() {
return Column(
mainAxisSize:
MainAxisSize.min,
crossAxisAlignment:
CrossAxisAlignment.end,
children: [
FloatingActionButton.extended(
heroTag: 'compare',
onPressed: openCompare,
icon: const Icon(
Icons.compare_arrows,
),
label:
const Text('複数台比較'),
),
const SizedBox(height: 10),
FloatingActionButton.extended(
heroTag: 'calculate',
onPressed:
openAddCalculation,
icon: const Icon(
Icons.calculate,
),
label:
const Text('期待値を計算'),
),
],
);
}

Widget _buildEmpty() {
return Center(
child: Padding(
padding:
const EdgeInsets.all(30),
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Icon(
Icons.calculate_outlined,
size: 80,
color:
Colors.grey.shade400,
),
const SizedBox(height: 20),
const Text(
'期待値を計算してみよう！',
style: TextStyle(
fontSize: 24,
fontWeight:
FontWeight.bold,
),
textAlign:
TextAlign.center,
),
const SizedBox(height: 10),
Text(
'「期待値を計算」または\n'
'「複数台比較」から始められます。',
style: TextStyle(
fontSize: 16,
color:
Colors.grey.shade700,
),
textAlign:
TextAlign.center,
),
],
),
),
);
}

Widget _buildSummary() {
if (results.isEmpty) {
return const SizedBox.shrink();
}

final best = results.reduce(
(a, b) =>
a.expectedValue >=
b.expectedValue
? a
: b,
);

final positive =
best.expectedValue >= 0;

return Card(
child: Padding(
padding:
const EdgeInsets.all(18),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Row(
children: [
Icon(Icons.star),
SizedBox(width: 8),
Text(
'現在のおすすめ台',
style: TextStyle(
fontSize: 15,
fontWeight:
FontWeight.bold,
),
),
],
),
const SizedBox(height: 8),
Text(
best.machine.name,
style: const TextStyle(
fontSize: 22,
fontWeight:
FontWeight.bold,
),
),
Text(
'${best.machine.category.label} / '
'${best.machine.type}',
style: TextStyle(
color:
Colors.grey.shade700,
),
),
const SizedBox(height: 6),
Text(
'期待値：'
'${positive ? '+' : ''}'
'${formatYen(best.expectedValue)}',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
color: positive
? Colors.green.shade700
: Colors.red.shade700,
),
),
Text(
'時給：約'
'${formatYen(best.hourlyValue)}',
style: const TextStyle(
fontWeight:
FontWeight.bold,
),
),
],
),
),
);
}
}

class MachineResultCard extends StatelessWidget {
final MachineResult result;
final VoidCallback onDelete;

const MachineResultCard({
super.key,
required this.result,
required this.onDelete,
});

@override
Widget build(BuildContext context) {
final positive =
result.expectedValue >= 0;

final color =
positive ? Colors.green : Colors.red;

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
Icon(
result.machine.category.icon,
),
const SizedBox(width: 10),
Expanded(
child: Text(
result.machine.name,
style: const TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),
),
IconButton(
onPressed: onDelete,
icon: const Icon(
Icons.delete_outline,
),
),
],
),
Text(
'${result.machine.category.label} ・ '
'${result.machine.type}',
style: TextStyle(
color: Colors.grey.shade600,
),
),
const SizedBox(height: 12),
Container(
width: double.infinity,
padding:
const EdgeInsets.all(14),
decoration: BoxDecoration(
color:
color.withOpacity(0.08),
borderRadius:
BorderRadius.circular(12),
),
child: Column(
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
formatYen(
result.expectedValue,
),
style: TextStyle(
color: color,
fontSize: 28,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 8),
_row(
'現在ゲーム数',
'${result.game}G',
),
_row(
'天井・目標まで',
'${result.remainingGame}G',
),
_row(
'投資目安',
formatYen(
result.investment.toDouble(),
),
),
_row(
'時給',
formatYen(
result.hourlyValue,
),
),
],
),
),
],
),
),
);
}

Widget _row(
String label,
String value,
) {
return Padding(
padding:
const EdgeInsets.only(top: 6),
child: Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
Text(label),
Text(
value,
style: const TextStyle(
fontWeight:
FontWeight.bold,
),
),
],
),
);
}
}

class AddCalculationPage
extends StatefulWidget {
const AddCalculationPage({
super.key,
});

@override
State<AddCalculationPage>
createState() =>
_AddCalculationPageState();
}

class _AddCalculationPageState
extends State<AddCalculationPage> {
MachineData? selectedMachine;

final gameController =
TextEditingController();

bool isReset = false;

@override
void initState() {
super.initState();

if (machineDataList.isNotEmpty) {
selectedMachine =
machineDataList.first;
}
}

@override
void dispose() {
gameController.dispose();
super.dispose();
}

void calculate() {
final machine = selectedMachine;

if (machine == null) {
return;
}

final game =
int.tryParse(
gameController.text,
) ??
0;

final result =
calculateMachineResult(
machine: machine,
currentGame:
game < 0 ? 0 : game,
isReset: isReset,
);

Navigator.pop(
context,
result,
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'期待値を計算',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
body: Center(
child: ConstrainedBox(
constraints:
const BoxConstraints(
maxWidth: 700,
),
child: ListView(
padding:
const EdgeInsets.all(20),
children: [
const Text(
'機種を選択',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 10),
DropdownButtonFormField<
MachineData>(
value: selectedMachine,
decoration:
const InputDecoration(
labelText: '機種',
),
items: machineDataList
.map(
(machine) =>
DropdownMenuItem<
MachineData>(
value: machine,
child: Text(
machine.name,
),
),
)
.toList(),
onChanged: (value) {
setState(() {
selectedMachine =
value;
});
},
),
const SizedBox(height: 20),
if (selectedMachine?.category ==
MachineCategory.slot) ...[
const Text(
'現在ゲーム数',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 10),
TextField(
controller:
gameController,
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
labelText: '現在G数',
suffixText: 'G',
),
),
const SizedBox(height: 15),
SwitchListTile(
contentPadding:
EdgeInsets.zero,
title: const Text(
'リセット後として計算',
),
value: isReset,
onChanged: (value) {
setState(() {
isReset = value;
});
},
),
] else ...[
const Text(
'現在ゲーム数',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 10),
TextField(
controller:
gameController,
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
labelText: '現在回転数',
suffixText: '回',
),
),
],
const SizedBox(height: 30),
FilledButton.icon(
onPressed: calculate,
icon: const Icon(
Icons.calculate,
),
label: const Text(
'期待値を計算する',
),
style:
FilledButton.styleFrom(
minimumSize:
const Size
.fromHeight(55),
),
),
],
),
),
),
);
}
}

class MachineDataPage
extends StatefulWidget {
const MachineDataPage({
super.key,
});

@override
State<MachineDataPage>
createState() =>
_MachineDataPageState();
}

class _MachineDataPageState
extends State<MachineDataPage> {
Future<void> addMachine() async {
final machine =
await Navigator.push<
MachineData>(
context,
MaterialPageRoute(
builder: (_) =>
const EditMachinePage(),
),
);

if (machine == null) return;

setState(() {
machineDataList.add(machine);
});

await saveMachineData();
}

Future<void> editMachine(
int index) async {
final machine =
await Navigator.push<
MachineData>(
context,
MaterialPageRoute(
builder: (_) =>
EditMachinePage(
machine:
machineDataList[index],
),
),
);

if (machine == null) return;

setState(() {
machineDataList[index] =
machine;
});

await saveMachineData();
}

Future<void> deleteMachine(
int index) async {
final machine =
machineDataList[index];

final ok =
await showDialog<bool>(
context: context,
builder: (_) =>
AlertDialog(
title:
const Text('機種を削除'),
content: Text(
'「${machine.name}」を削除しますか？',
),
actions: [
TextButton(
onPressed: () =>
Navigator.pop(
context,
false,
),
child:
const Text('キャンセル'),
),
FilledButton(
onPressed: () =>
Navigator.pop(
context,
true,
),
child:
const Text('削除'),
),
],
),
);

if (ok != true) return;

setState(() {
machineDataList.removeAt(index);
});

await saveMachineData();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'機種データ',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
body: machineDataList.isEmpty
? const Center(
child: Text(
'登録されている機種がありません',
),
)
: ListView.builder(
padding:
const EdgeInsets.all(16),
itemCount:
machineDataList.length,
itemBuilder:
(context, index) {
final machine =
machineDataList[index];

return Card(
margin:
const EdgeInsets.only(
bottom: 10,
),
child: ListTile(
leading: CircleAvatar(
child: Icon(
machine.category
.icon,
),
),
title: Text(
machine.name,
style:
const TextStyle(
fontWeight:
FontWeight.bold,
),
),
subtitle: Text(
'${machine.category.label} ・ '
'${machine.type}',
),
trailing: Row(
mainAxisSize:
MainAxisSize.min,
children: [
IconButton(
onPressed: () =>
editMachine(
index,
),
icon: const Icon(
Icons.edit,
),
),
IconButton(
onPressed: () =>
deleteMachine(
index,
),
icon: const Icon(
Icons
.delete_outline,
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
icon:
const Icon(Icons.add),
label:
const Text('機種を追加'),
),
);
}
}

class EditMachinePage
extends StatefulWidget {
final MachineData? machine;

const EditMachinePage({
super.key,
this.machine,
});

@override
State<EditMachinePage>
createState() =>
_EditMachinePageState();
}

class _EditMachinePageState
extends State<EditMachinePage> {
late final TextEditingController
nameController;

late final TextEditingController
typeController;

late final TextEditingController
ceilingController;

late final TextEditingController
resetCeilingController;

late final TextEditingController
payoutRateController;

late final TextEditingController
gamesPerHourController;

late final TextEditingController
initialProbabilityController;

late final TextEditingController
averagePayoutController;

late final TextEditingController
investmentPerGameController;

late final TextEditingController
gamesPer50Controller;

late final TextEditingController
startGameController;

late final TextEditingController
probabilityController;

late final TextEditingController
averageBallController;

late final TextEditingController
ballPriceController;

late final TextEditingController
startPer250Controller;

late MachineCategory category;

bool get editing =>
widget.machine != null;

@override
void initState() {
super.initState();

final machine =
widget.machine;

category =
machine?.category ??
MachineCategory.slot;

nameController =
TextEditingController(
text: machine?.name ?? '',
);

typeController =
TextEditingController(
text: machine?.type ?? 'AT',
);

ceilingController =
TextEditingController(
text:
'${machine?.ceiling ?? 1000}',
);

resetCeilingController =
TextEditingController(
text:
'${machine?.resetCeiling ?? 500}',
);

payoutRateController =
TextEditingController(
text:
'${machine?.payoutRate ?? 100}',
);

gamesPerHourController =
TextEditingController(
text:
'${machine?.gamesPerHour ?? 800}',
);

initialProbabilityController =
TextEditingController(
text:
'${machine?.initialProbability ?? 200}',
);

averagePayoutController =
TextEditingController(
text:
'${machine?.averagePayout ?? 500}',
);

investmentPerGameController =
TextEditingController(
text:
'${machine?.investmentPerGame ?? 20}',
);

gamesPer50Controller =
TextEditingController(
text:
'${machine?.gamesPer50Coins ?? 50}',
);

startGameController =
TextEditingController(
text:
'${machine?.startGame ?? 1000}',
);

probabilityController =
TextEditingController(
text:
'${machine?.probability ?? 0.003}',
);

averageBallController =
TextEditingController(
text:
'${machine?.averageBall ?? 1500}',
);

ballPriceController =
TextEditingController(
text:
'${machine?.ballPrice ?? 4}',
);

startPer250Controller =
TextEditingController(
text:
'${machine?.startPer250 ?? 19}',
);
}

@override
void dispose() {
nameController.dispose();
typeController.dispose();
ceilingController.dispose();
resetCeilingController.dispose();
payoutRateController.dispose();
gamesPerHourController.dispose();
initialProbabilityController.dispose();
averagePayoutController.dispose();
investmentPerGameController.dispose();
gamesPer50Controller.dispose();
startGameController.dispose();
probabilityController.dispose();
averageBallController.dispose();
ballPriceController.dispose();
startPer250Controller.dispose();

super.dispose();
}

void save() {
final name =
nameController.text.trim();

if (name.isEmpty) {
ScaffoldMessenger.of(context)
.showSnackBar(
const SnackBar(
content:
Text('台名を入力してください'),
),
);
return;
}

MachineData machine;

if (category ==
MachineCategory.slot) {
machine =
MachineData.slot(
name: name,
type:
typeController.text.trim(),
ceiling:
int.tryParse(
ceilingController
.text,
) ??
1000,
resetCeiling:
int.tryParse(
resetCeilingController
.text,
) ??
500,
payoutRate:
double.tryParse(
payoutRateController
.text,
) ??
100,
gamesPerHour:
int.tryParse(
gamesPerHourController
.text,
) ??
800,
initialProbability:
int.tryParse(
initialProbabilityController
.text,
) ??
200,
averagePayout:
int.tryParse(
averagePayoutController
.text,
) ??
500,
investmentPerGame:
int.tryParse(
investmentPerGameController
.text,
) ??
20,
gamesPer50Coins:
double.tryParse(
gamesPer50Controller
.text,
) ??
50,
);
} else {
machine =
MachineData.pachinko(
name: name,
type:
typeController.text.trim(),
startGame:
int.tryParse(
startGameController
.text,
) ??
1000,
probability:
double.tryParse(
probabilityController
.text,
) ??
0.003,
averageBall:
int.tryParse(
averageBallController
.text,
) ??
1500,
ballPrice:
double.tryParse(
ballPriceController
.text,
) ??
4,
startPer250:
double.tryParse(
startPer250Controller
.text,
) ??
19,
);
}

Navigator.pop(
context,
machine,
);
}

Widget numberField(
TextEditingController controller,
String label,
String suffix,
) {
return Padding(
padding:
const EdgeInsets.only(
bottom: 12,
),
child: TextField(
controller: controller,
keyboardType:
const TextInputType
.numberWithOptions(
decimal: true,
),
decoration:
InputDecoration(
labelText: label,
suffixText: suffix,
),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(
editing
? '機種を編集'
: '機種を追加',
style: const TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
body: Center(
child: ConstrainedBox(
constraints:
const BoxConstraints(
maxWidth: 700,
),
child: ListView(
padding:
const EdgeInsets.all(20),
children: [
TextField(
controller:
nameController,
decoration:
const InputDecoration(
labelText: '台名',
hintText:
'例：スマスロ北斗の拳',
),
),
const SizedBox(height: 14),
TextField(
controller:
typeController,
decoration:
const InputDecoration(
labelText: 'タイプ',
hintText:
'例：AT・LT',
),
),
const SizedBox(height: 18),
DropdownButtonFormField<
MachineCategory>(
value: category,
decoration:
const InputDecoration(
labelText: '種類',
),
items: MachineCategory
.values
.map(
(item) =>
DropdownMenuItem<
MachineCategory>(
value: item,
child: Row(
children: [
Icon(
item.icon,
),
const SizedBox(
width: 8,
),
Text(
item.label,
),
],
),
),
)
.toList(),
onChanged: (value) {
if (value == null) {
return;
}

setState(() {
category = value;
});
},
),
const SizedBox(height: 25),
if (category ==
MachineCategory.slot)
...[
const Text(
'スロット設定',
style:
TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child:
numberField(
ceilingController,
'通常天井',
'G',
),
),
const SizedBox(
width: 10,
),
Expanded(
child:
numberField(
resetCeilingController,
'リセット天井',
'G',
),
),
],
),
numberField(
payoutRateController,
'出玉率',
'%',
),
numberField(
gamesPerHourController,
'1時間ゲーム数',
'G',
),
numberField(
initialProbabilityController,
'初当たり確率',
'分の1',
),
numberField(
averagePayoutController,
'平均払い出し',
'枚',
),
numberField(
investmentPerGameController,
'1Gあたり投資額',
'円',
),
numberField(
gamesPer50Controller,
'50枚あたりゲーム数',
'G',
),
]
else ...[
const Text(
'パチンコ設定',
style:
TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 12),
numberField(
startGameController,
'目標回転数',
'回',
),
numberField(
probabilityController,
'大当たり確率',
'',
),
numberField(
averageBallController,
'平均出玉',
'玉',
),
numberField(
ballPriceController,
'玉単価',
'円',
),
numberField(
startPer250Controller,
'250玉あたり回転数',
'回',
),
],
const SizedBox(height: 20),
FilledButton.icon(
onPressed: save,
icon:
const Icon(Icons.save),
label: Text(
editing
? '変更を保存'
: 'この台を保存',
),
style:
FilledButton.styleFrom(
minimumSize:
const Size
.fromHeight(
55,
),
),
),
],
),
),
),
);
}
}

class ComparePage
extends StatefulWidget {
const ComparePage({
super.key,
});

@override
State<ComparePage>
createState() =>
_ComparePageState();
}

class _ComparePageState
extends State<ComparePage> {
final Set<int> selected = {};

final Map<int,
TextEditingController>
games = {};

@override
void initState() {
super.initState();

for (int i = 0;
i < machineDataList.length;
i++) {
games[i] =
TextEditingController(
text: '0',
);

if (i < 3) {
selected.add(i);
}
}
}

@override
void dispose() {
for (final controller
in games.values) {
controller.dispose();
}

super.dispose();
}

MachineResult result(
int index) {
final machine =
machineDataList[index];

final game =
int.tryParse(
games[index]!.text,
) ??
0;

return calculateMachineResult(
machine: machine,
currentGame:
game < 0 ? 0 : game,
isReset: false,
);
}

void finish() {
final results = selected
.toList()
.map(result)
.toList();

Navigator.pop(
context,
results,
);
}

@override
Widget build(BuildContext context) {
final indexes =
selected.toList()..sort();

return Scaffold(
appBar: AppBar(
title: const Text(
'複数台比較',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
actions: [
IconButton(
onPressed:
selected.isEmpty
? null
: finish,
icon: const Icon(
Icons.check,
),
tooltip: '比較結果を追加',
),
],
),
body: Column(
children: [
Container(
width: double.infinity,
padding:
const EdgeInsets.all(12),
child:
SingleChildScrollView(
scrollDirection:
Axis.horizontal,
child: Row(
children: List.generate(
machineDataList.length,
(index) {
final machine =
machineDataList[
index];

return Padding(
padding:
const EdgeInsets
.only(
right: 8,
),
child: FilterChip(
selected:
selected.contains(
index,
),
label:
Text(
machine.name,
),
avatar:
Icon(
machine.category
.icon,
size: 18,
),
onSelected:
(value) {
setState(() {
if (value) {
selected
.add(
index,
);
} else {
selected
.remove(
index,
);
}
});
},
),
);
},
),
),
),
),
const Divider(height: 1),
Expanded(
child:
indexes.isEmpty
? const Center(
child: Text(
'比較する台を選択してください',
),
)
: ListView.builder(
padding:
const EdgeInsets
.all(12),
itemCount:
indexes.length,
itemBuilder:
(context,
position) {
return _buildCard(
indexes[
position],
position,
);
},
),
),
],
),
bottomNavigationBar:
SafeArea(
child: Padding(
padding:
const EdgeInsets.all(12),
child: FilledButton.icon(
onPressed:
selected.isEmpty
? null
: finish,
icon: const Icon(
Icons.add,
),
label: const Text(
'比較結果をホームに追加',
),
style:
FilledButton.styleFrom(
minimumSize:
const Size
.fromHeight(
52,
),
),
),
),
),
);
}

Widget _buildCard(
int index,
int position,
) {
final machine =
machineDataList[index];

final r = result(index);

final positive =
r.expectedValue >= 0;

final color =
positive
? Colors.green
: Colors.red;

return Card(
margin:
const EdgeInsets.only(
bottom: 12,
),
child: Padding(
padding:
const EdgeInsets.all(16),
child: Column(
children: [
Row(
children: [
Container(
width: 38,
height: 38,
alignment:
Alignment.center,
decoration:
BoxDecoration(
color:
position == 0
? Colors
.amber
.withOpacity(
0.2,
)
: Colors
.blue
.withOpacity(
0.08,
),
shape:
BoxShape.circle,
),
child: Text(
position == 0
? '🥇'
: '${position + 1}',
style:
const TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
const SizedBox(
width: 10),
Expanded(
child: Text(
machine.name,
style:
const TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
),
),
),
],
),
const SizedBox(
height: 12),
if (machine.category ==
MachineCategory.slot)
TextField(
controller:
games[index],
keyboardType:
TextInputType
.number,
decoration:
const InputDecoration(
labelText:
'現在ゲーム数',
suffixText: 'G',
),
onChanged: (_) =>
setState(() {}),
)
else
TextField(
controller:
games[index],
keyboardType:
TextInputType
.number,
decoration:
const InputDecoration(
labelText:
'現在回転数',
suffixText: '回',
),
onChanged: (_) =>
setState(() {}),
),
const SizedBox(
height: 14),
Container(
width:
double.infinity,
padding:
const EdgeInsets.all(
14,
),
decoration:
BoxDecoration(
color:
color.withOpacity(
0.08,
),
borderRadius:
BorderRadius.circular(
12,
),
),
child: Column(
children: [
const Text(
'期待値',
style:
TextStyle(
fontWeight:
FontWeight.bold,
),
),
Text(
formatYen(
r.expectedValue,
),
style:
TextStyle(
color: color,
fontSize: 27,
fontWeight:
FontWeight.bold,
),
),
_compareRow(
'目標まで',
'${r.remainingGame}G',
),
_compareRow(
'投資目安',
formatYen(
r.investment
.toDouble(),
),
),
_compareRow(
'時給',
formatYen(
r.hourlyValue,
),
),
],
),
),
],
),
),
);
}

Widget _compareRow(
String label,
String value,
) {
return Padding(
padding:
const EdgeInsets.only(
top: 6,
),
child: Row(
mainAxisAlignment:
MainAxisAlignment
.spaceBetween,
children: [
Text(label),
Text(
value,
style:
const TextStyle(
fontWeight:
FontWeight.bold,
),
),
],
),
);
}
}

class RankingPage
extends StatelessWidget {
final List<MachineResult> results;

const RankingPage({
super.key,
required this.results,
});

@override
Widget build(BuildContext context) {
final sorted =
[...results];

sorted.sort(
(a, b) =>
b.expectedValue
.compareTo(
a.expectedValue,
),
);

return Scaffold(
appBar: AppBar(
title: const Text(
'期待値ランキング',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
body: sorted.isEmpty
? const Center(
child: Text(
'まだ計算結果がありません',
),
)
: ListView.builder(
padding:
const EdgeInsets.all(16),
itemCount:
sorted.length,
itemBuilder:
(context, index) {
final result =
sorted[index];

final positive =
result.expectedValue >=
0;

return Card(
margin:
const EdgeInsets.only(
bottom: 10,
),
child: ListTile(
leading:
CircleAvatar(
child: Text(
'${index + 1}',
),
),
title: Text(
result.machine
.name,
style:
const TextStyle(
fontWeight:
FontWeight
.bold,
),
),
subtitle:
Text(
'${result.machine.category.label}'
' ・ '
'${result.game}G',
),
trailing:
Text(
formatYen(
result
.expectedValue,
),
style:
TextStyle(
fontSize: 18,
fontWeight:
FontWeight
.bold,
color: positive
? Colors
.green
: Colors
.red,
),
),
),
);
},
),
);
}
}

String formatYen(double value) {
final rounded =
value.round();

final absolute =
rounded.abs().toString();

final text =
absolute.replaceAllMapped(
RegExp(
r'(\d)(?=(\d{3})+(?!\d))',
),
(match) =>
'${match.group(1)},',
);

return rounded < 0
? '-¥$text'
: '¥$text';
}