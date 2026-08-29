import 'dart:convert';
import 'dart:math' as math;

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
filled: true,
fillColor: Colors.white,
border: OutlineInputBorder(),
enabledBorder: OutlineInputBorder(),
focusedBorder: OutlineInputBorder(),
),
appBarTheme: const AppBarTheme(
centerTitle: true,
elevation: 0,
),
),
home: const HomePage(),
);
}
}

// ============================================================
// 台データ
// ============================================================

class MachineData {
String name;
String type;
int ceiling;
int resetCeiling;
double payoutRate;
double gamesPerHour;
double initialProbability;
double averagePayout;
double investmentPerGame;
double gamesPer50Coins;
bool favorite;

MachineData({
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
this.favorite = false,
});

MachineData copy() {
return MachineData(
name: name,
type: type,
ceiling: ceiling,
resetCeiling: resetCeiling,
payoutRate: payoutRate,
gamesPerHour: gamesPerHour,
initialProbability: initialProbability,
averagePayout: averagePayout,
investmentPerGame: investmentPerGame,
gamesPer50Coins: gamesPer50Coins,
favorite: favorite,
);
}

Map<String, dynamic> toJson() {
return {
'name': name,
'type': type,
'ceiling': ceiling,
'resetCeiling': resetCeiling,
'payoutRate': payoutRate,
'gamesPerHour': gamesPerHour,
'initialProbability': initialProbability,
'averagePayout': averagePayout,
'investmentPerGame': investmentPerGame,
'gamesPer50Coins': gamesPer50Coins,
'favorite': favorite,
};
}

factory MachineData.fromJson(Map<String, dynamic> json) {
return MachineData(
name: json['name']?.toString() ?? '',
type: json['type']?.toString() ?? 'スロット',
ceiling: _toInt(json['ceiling'], 999),
resetCeiling: _toInt(json['resetCeiling'], 500),
payoutRate: _toDouble(json['payoutRate'], 97),
gamesPerHour: _toDouble(json['gamesPerHour'], 800),
initialProbability: _toDouble(
json['initialProbability'],
1.0,
),
averagePayout: _toDouble(
json['averagePayout'],
500,
),
investmentPerGame: _toDouble(
json['investmentPerGame'],
20,
),
gamesPer50Coins: _toDouble(
json['gamesPer50Coins'],
33,
),
favorite: json['favorite'] == true,
);
}
}

int _toInt(dynamic value, int defaultValue) {
if (value is int) {
return value;
}

if (value is num) {
return value.toInt();
}

return int.tryParse(
value?.toString() ?? '',
) ??
defaultValue;
}

double _toDouble(dynamic value, double defaultValue) {
if (value is num) {
return value.toDouble();
}

return double.tryParse(
value?.toString() ?? '',
) ??
defaultValue;
}

// ============================================================
// 期待値計算
// ============================================================

double calculateHitProbability({
required int remainingGames,
required double initialProbability,
}) {
if (remainingGames <= 0) {
return 0;
}

final probabilityPerGame =
(initialProbability / 100).clamp(0.0, 1.0);

if (probabilityPerGame >= 1) {
return 1;
}

final missProbability = math.pow(
1 - probabilityPerGame,
remainingGames,
).toDouble();

return (1 - missProbability).clamp(0.0, 1.0);
}

double calculateExpectedValue({
required int currentGame,
required int ceiling,
required int investment,
required double payoutRate,
required double initialProbability,
required double averagePayout,
required double investmentPerGame,
}) {
final safeCeiling = ceiling > 0 ? ceiling : 1;

final remaining = math.max(
0,
safeCeiling - currentGame,
).toInt();

if (remaining <= 0) {
final returnValue =
averagePayout * (payoutRate / 100);

return returnValue - investment;
}

final additionalInvestment =
remaining * investmentPerGame;

final hitProbability = calculateHitProbability(
remainingGames: remaining,
initialProbability: initialProbability,
);

final expectedPayout =
averagePayout * hitProbability;

final expectedReturn =
expectedPayout * (payoutRate / 100);

return expectedReturn -
additionalInvestment -
investment;
}

// ============================================================
// 計算結果
// ============================================================

class MachineResult {
final MachineData machine;
final int currentGame;
final int investment;
final bool useResetCeiling;

late final int targetCeiling;
late final int remainingGame;
late final double expectedValue;
late final double hourlyValue;
late final double hitProbability;

MachineResult({
required this.machine,
required this.currentGame,
required this.investment,
required this.useResetCeiling,
}) {
final normalCeiling =
machine.ceiling > 0 ? machine.ceiling : 1;

final resetCeiling =
machine.resetCeiling > 0
? machine.resetCeiling
: normalCeiling;

targetCeiling =
useResetCeiling ? resetCeiling : normalCeiling;

remainingGame = math.max(
0,
targetCeiling - currentGame,
).toInt();

hitProbability = calculateHitProbability(
remainingGames: remainingGame,
initialProbability: machine.initialProbability,
);

expectedValue = calculateExpectedValue(
currentGame: currentGame,
ceiling: targetCeiling,
investment: investment,
payoutRate: machine.payoutRate,
initialProbability: machine.initialProbability,
averagePayout: machine.averagePayout,
investmentPerGame: machine.investmentPerGame,
);

if (remainingGame > 0 && machine.gamesPerHour > 0) {
hourlyValue =
expectedValue *
machine.gamesPerHour /
remainingGame;
} else {
hourlyValue = expectedValue;
}
}
}

// ============================================================
// 保存・読み込み
// ============================================================

Future<void> saveMachineData(
List<MachineData> machines,
) async {
final prefs = await SharedPreferences.getInstance();

final data = machines
.map(
(machine) => jsonEncode(machine.toJson()),
)
.toList();

await prefs.setStringList(
'machines',
data,
);
}

Future<List<MachineData>> loadMachineData() async {
final prefs = await SharedPreferences.getInstance();

final data = prefs.getStringList('machines');

if (data == null) {
return [];
}

try {
return data
.map((item) {
final decoded = jsonDecode(item);

if (decoded is Map<String, dynamic>) {
return MachineData.fromJson(decoded);
}

return MachineData(
name: '',
type: 'スロット',
ceiling: 999,
resetCeiling: 500,
payoutRate: 97,
gamesPerHour: 800,
initialProbability: 1,
averagePayout: 500,
investmentPerGame: 20,
gamesPer50Coins: 33,
);
})
.where(
(machine) => machine.name.isNotEmpty,
)
.toList();
} catch (_) {
return [];
}
}

// ============================================================
// 表示用
// ============================================================

String formatYen(double value) {
final rounded = value.round();

final text = rounded
.abs()
.toString()
.replaceAllMapped(
RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
(match) => '${match.group(1)},',
);

if (rounded < 0) {
return '-¥$text';
}

return '¥$text';
}

// ============================================================
// ホーム
// ============================================================

class HomePage extends StatefulWidget {
const HomePage({super.key});

@override
State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
List<MachineData> machines = [];

bool loading = true;
String searchText = '';
String selectedFilter = 'すべて';
bool favoriteOnly = false;

@override
void initState() {
super.initState();
loadMachines();
}

Future<void> loadMachines() async {
final loaded = await loadMachineData();

if (!mounted) {
return;
}

setState(() {
machines = loaded;
loading = false;
});
}

Future<void> addMachine(
MachineData machine,
) async {
setState(() {
machines.add(machine);
});

await saveMachineData(machines);
}

Future<void> updateMachine(
int index,
MachineData machine,
) async {
if (index < 0 || index >= machines.length) {
return;
}

setState(() {
machines[index] = machine;
});

await saveMachineData(machines);
}

Future<void> deleteMachine(
int index,
) async {
if (index < 0 || index >= machines.length) {
return;
}

setState(() {
machines.removeAt(index);
});

await saveMachineData(machines);
}

Future<void> toggleFavorite(
int index,
) async {
if (index < 0 || index >= machines.length) {
return;
}

setState(() {
machines[index].favorite =
!machines[index].favorite;
});

await saveMachineData(machines);
}

Future<void> duplicateMachine(
int index,
) async {
if (index < 0 || index >= machines.length) {
return;
}

final copied = machines[index].copy();

copied.name = '${copied.name} コピー';

setState(() {
machines.insert(
index + 1,
copied,
);
});

await saveMachineData(machines);

if (!mounted) {
return;
}

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('台を複製しました'),
),
);
}

Future<void> openAddMachinePage() async {
final result =
await Navigator.push<MachineData>(
context,
MaterialPageRoute(
builder: (_) => const AddMachinePage(),
),
);

if (result != null) {
await addMachine(result);
}
}

Future<void> openEditMachinePage(
int index,
) async {
if (index < 0 || index >= machines.length) {
return;
}

final result =
await Navigator.push<MachineData>(
context,
MaterialPageRoute(
builder: (_) => AddMachinePage(
machine: machines[index],
),
),
);

if (result != null) {
await updateMachine(
index,
result,
);
}
}

void showRanking() {
if (machines.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('まず台を追加してください'),
),
);
return;
}

Navigator.push(
context,
MaterialPageRoute(
builder: (_) => RankingPage(
machines: machines,
),
),
);
}

void showComparison() {
if (machines.length < 2) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('比較するには2台以上登録してください'),
),
);
return;
}

Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ComparisonPage(
machines: machines,
),
),
);
}

void showAbout() {
showAboutDialog(
context: context,
applicationName: '期待値マスター',
applicationVersion: '1.0.0',
applicationLegalese:
'期待値計算をサポートするアプリ',
);
}

List<MachineData> get filteredMachines {
return machines.where((machine) {
final matchesSearch =
searchText.isEmpty ||
machine.name
.toLowerCase()
.contains(
searchText.toLowerCase(),
);

final matchesType =
selectedFilter == 'すべて' ||
machine.type == selectedFilter;

final matchesFavorite =
!favoriteOnly || machine.favorite;

return matchesSearch &&
matchesType &&
matchesFavorite;
}).toList();
}

@override
Widget build(BuildContext context) {
final displayedMachines = filteredMachines;

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
tooltip: '比較',
onPressed: showComparison,
icon: const Icon(
Icons.compare_arrows,
),
),
IconButton(
tooltip: 'ランキング',
onPressed: showRanking,
icon: const Icon(
Icons.emoji_events,
),
),
PopupMenuButton<String>(
onSelected: (value) {
if (value == 'about') {
showAbout();
} else if (value == 'comparison') {
showComparison();
} else if (value == 'ranking') {
showRanking();
}
},
itemBuilder: (_) => const [
PopupMenuItem(
value: 'comparison',
child: ListTile(
leading: Icon(
Icons.compare_arrows,
),
title: Text('台を比較'),
contentPadding: EdgeInsets.zero,
),
),
PopupMenuItem(
value: 'ranking',
child: ListTile(
leading: Icon(
Icons.emoji_events,
),
title: Text('ランキング'),
contentPadding: EdgeInsets.zero,
),
),
PopupMenuItem(
value: 'about',
child: ListTile(
leading: Icon(
Icons.info_outline,
),
title: Text('アプリについて'),
contentPadding: EdgeInsets.zero,
),
),
],
),
],
),
body: loading
? const Center(
child: CircularProgressIndicator(),
)
: Column(
children: [
_buildTopPanel(),
Expanded(
child: displayedMachines.isEmpty
? _buildEmptyState()
: _buildMachineList(
displayedMachines,
),
),
],
),
floatingActionButton:
FloatingActionButton.extended(
onPressed: openAddMachinePage,
icon: const Icon(Icons.add),
label: const Text('台を追加'),
),
);
}

Widget _buildTopPanel() {
return Container(
padding: const EdgeInsets.fromLTRB(
12,
8,
12,
8,
),
color: Colors.white,
child: Column(
children: [
TextField(
decoration: InputDecoration(
hintText: '台名を検索',
prefixIcon: const Icon(
Icons.search,
),
suffixIcon: searchText.isNotEmpty
? IconButton(
onPressed: () {
setState(() {
searchText = '';
});
},
icon: const Icon(
Icons.clear,
),
)
: null,
isDense: true,
),
onChanged: (value) {
setState(() {
searchText = value;
});
},
),
const SizedBox(height: 8),
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: SegmentedButton<String>(
segments: const [
ButtonSegment(
value: 'すべて',
label: Text('すべて'),
),
ButtonSegment(
value: 'スロット',
label: Text('スロット'),
),
ButtonSegment(
value: 'パチンコ',
label: Text('パチンコ'),
),
],
selected: {
selectedFilter,
},
onSelectionChanged: (values) {
setState(() {
selectedFilter = values.first;
});
},
),
),
const SizedBox(height: 6),
Row(
children: [
FilterChip(
selected: favoriteOnly,
avatar: Icon(
favoriteOnly
? Icons.star
: Icons.star_border,
size: 18,
),
label: const Text(
'お気に入りのみ',
),
onSelected: (value) {
setState(() {
favoriteOnly = value;
});
},
),
const Spacer(),
Text(
displayCountText(),
style: const TextStyle(
fontSize: 13,
color: Colors.black54,
),
),
],
),
],
),
);
}

String displayCountText() {
if (searchText.isEmpty &&
selectedFilter == 'すべて' &&
!favoriteOnly) {
return '登録台数 ${machines.length}台';
}

return '表示 ${filteredMachines.length}台 / ${machines.length}台';
}

Widget _buildEmptyState() {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(
Icons.calculate_outlined,
size: 80,
color: Colors.blueGrey,
),
const SizedBox(height: 20),
Text(
machines.isEmpty
? '期待値マスターへようこそ！'
: '該当する台がありません',
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 12),
Text(
machines.isEmpty
? '台を追加して期待値を計算しよう。'
: '検索条件を変更してください。',
style: const TextStyle(
fontSize: 16,
color: Colors.black54,
),
textAlign: TextAlign.center,
),
if (machines.isEmpty) ...[
const SizedBox(height: 28),
FilledButton.icon(
onPressed: openAddMachinePage,
icon: const Icon(Icons.add),
label: const Text(
'最初の台を追加',
),
),
],
],
),
),
);
}

Widget _buildMachineList(
List<MachineData> list,
) {
return ListView.builder(
padding: const EdgeInsets.fromLTRB(
12,
12,
12,
110,
),
itemCount: list.length,
itemBuilder: (
context,
displayIndex,
) {
final machine = list[displayIndex];

final originalIndex =
machines.indexOf(machine);

return MachineResultCard(
key: ValueKey(
'${machine.name}_${machine.hashCode}',
),
machine: machine,
onDelete: () {
_confirmDelete(
originalIndex,
);
},
onEdit: () {
openEditMachinePage(
originalIndex,
);
},
onDuplicate: () {
duplicateMachine(
originalIndex,
);
},
onFavorite: () {
toggleFavorite(
originalIndex,
);
},
);
},
);
}

Future<void> _confirmDelete(
int index,
) async {
if (index < 0 || index >= machines.length) {
return;
}

final machine = machines[index];

final result = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text(
'削除しますか？',
),
content: Text(
'${machine.name}を削除します。',
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(
dialogContext,
false,
);
},
child: const Text('キャンセル'),
),
FilledButton(
onPressed: () {
Navigator.pop(
dialogContext,
true,
);
},
child: const Text('削除'),
),
],
);
},
);

if (result == true) {
await deleteMachine(index);
}
}
}

// ============================================================
// 台カード
// ============================================================

class MachineResultCard extends StatefulWidget {
final MachineData machine;
final VoidCallback onDelete;
final VoidCallback onEdit;
final VoidCallback onDuplicate;
final VoidCallback onFavorite;

const MachineResultCard({
super.key,
required this.machine,
required this.onDelete,
required this.onEdit,
required this.onDuplicate,
required this.onFavorite,
});

@override
State<MachineResultCard> createState() =>
_MachineResultCardState();
}

class _MachineResultCardState
extends State<MachineResultCard> {
late TextEditingController gameController;
late TextEditingController investmentController;

MachineResult? result;

bool useResetCeiling = false;

@override
void initState() {
super.initState();

gameController = TextEditingController(
text: '0',
);

investmentController =
TextEditingController(
text: '0',
);

calculate();
}

@override
void dispose() {
gameController.dispose();
investmentController.dispose();
super.dispose();
}

void calculate() {
final game =
int.tryParse(
gameController.text,
) ??
0;

final investment =
int.tryParse(
investmentController.text,
) ??
0;

final targetCeiling = useResetCeiling
? widget.machine.resetCeiling
: widget.machine.ceiling;

final safeCeiling =
targetCeiling > 0 ? targetCeiling : 1;

final safeGame = game
.clamp(
0,
safeCeiling,
)
.toInt();

final safeInvestment =
investment < 0 ? 0 : investment;

final newResult = MachineResult(
machine: widget.machine,
currentGame: safeGame,
investment: safeInvestment,
useResetCeiling: useResetCeiling,
);

if (!mounted) {
return;
}

setState(() {
result = newResult;
});
}

@override
Widget build(BuildContext context) {
final currentResult = result;

return Card(
margin: const EdgeInsets.only(
bottom: 12,
),
elevation: 1,
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
IconButton(
tooltip: widget.machine.favorite
? 'お気に入り解除'
: 'お気に入り登録',
onPressed: widget.onFavorite,
icon: Icon(
widget.machine.favorite
? Icons.star
: Icons.star_border,
color:
widget.machine.favorite
? Colors.amber
: null,
),
),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
widget.machine.name,
style: const TextStyle(
fontSize: 19,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 4),
Row(
children: [
Container(
padding:
const EdgeInsets
.symmetric(
horizontal: 8,
vertical: 3,
),
decoration:
BoxDecoration(
color: Colors.blue
.withOpacity(
0.08,
),
borderRadius:
BorderRadius
.circular(
6,
),
),
child: Text(
widget.machine.type,
style:
const TextStyle(
fontSize: 12,
fontWeight:
FontWeight.bold,
),
),
),
const SizedBox(
width: 8,
),
Flexible(
child: Text(
'天井 ${widget.machine.ceiling}G',
style:
const TextStyle(
fontSize: 12,
color:
Colors.black54,
),
),
),
],
),
],
),
),
PopupMenuButton<String>(
onSelected: (value) {
if (value == 'edit') {
widget.onEdit();
} else if (value ==
'duplicate') {
widget.onDuplicate();
} else if (value ==
'delete') {
widget.onDelete();
}
},
itemBuilder: (_) => const [
PopupMenuItem(
value: 'edit',
child: ListTile(
leading:
Icon(Icons.edit),
title:
Text('編集'),
contentPadding:
EdgeInsets.zero,
),
),
PopupMenuItem(
value: 'duplicate',
child: ListTile(
leading:
Icon(Icons.copy),
title:
Text('複製'),
contentPadding:
EdgeInsets.zero,
),
),
PopupMenuItem(
value: 'delete',
child: ListTile(
leading:
Icon(
Icons.delete_outline,
),
title:
Text('削除'),
contentPadding:
EdgeInsets.zero,
),
),
],
),
],
),
const Divider(),
const SizedBox(height: 6),
Row(
children: [
Expanded(
child: TextField(
controller:
gameController,
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
labelText:
'現在ゲーム数',
suffixText: 'G',
isDense: true,
),
onChanged: (_) =>
calculate(),
),
),
const SizedBox(width: 10),
Expanded(
child: TextField(
controller:
investmentController,
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
labelText: '投資額',
suffixText: '円',
isDense: true,
),
onChanged: (_) =>
calculate(),
),
),
],
),
const SizedBox(height: 10),
SwitchListTile(
contentPadding: EdgeInsets.zero,
dense: true,
title: const Text(
'リセット天井で計算',
),
subtitle: Text(
'リセット天井 ${widget.machine.resetCeiling}G',
),
value: useResetCeiling,
onChanged: (value) {
setState(() {
useResetCeiling = value;
});

calculate();
},
),
const SizedBox(height: 6),
if (currentResult != null)
_buildResult(
currentResult,
),
],
),
),
);
}

Widget _buildResult(
MachineResult value,
) {
final isPositive =
value.expectedValue >= 0;

final resultColor =
isPositive ? Colors.green : Colors.red;

return Container(
width: double.infinity,
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: isPositive
? Colors.green.withOpacity(0.08)
: Colors.red.withOpacity(0.08),
borderRadius:
BorderRadius.circular(12),
border: Border.all(
color: resultColor.withOpacity(0.2),
),
),
child: Column(
children: [
Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
const Text(
'期待値',
style: TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
),
),
Flexible(
child: Text(
formatYen(
value.expectedValue,
),
textAlign:
TextAlign.end,
style: TextStyle(
fontSize: 24,
fontWeight:
FontWeight.bold,
color: resultColor,
),
),
),
],
),
const SizedBox(height: 10),
Container(
width: double.infinity,
padding:
const EdgeInsets.symmetric(
vertical: 8,
horizontal: 10,
),
decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(8),
),
child: Text(
isPositive
? '打つ価値あり'
: '慎重に判断',
textAlign: TextAlign.center,
style: TextStyle(
color: resultColor,
fontWeight:
FontWeight.bold,
),
),
),
const SizedBox(height: 8),
_resultRow(
'計算天井',
'${value.targetCeiling} G',
),
_resultRow(
'天井まで',
'${value.remainingGame} G',
),
_resultRow(
'時給換算',
formatYen(
value.hourlyValue,
),
),
_resultRow(
'初当たり期待確率',
'${(value.hitProbability * 100).toStringAsFixed(1)}%',
),
_resultRow(
'出玉率',
'${widget.machine.payoutRate.toStringAsFixed(1)}%',
),
_resultRow(
'1時間ゲーム数',
'${widget.machine.gamesPerHour.toStringAsFixed(0)} G',
),
],
),
);
}

Widget _resultRow(
String label,
String value,
) {
return Padding(
padding: const EdgeInsets.only(
top: 5,
),
child: Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
Flexible(
child: Text(label),
),
const SizedBox(width: 8),
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

// ============================================================
// 台追加・編集
// ============================================================

class AddMachinePage extends StatefulWidget {
final MachineData? machine;

const AddMachinePage({
super.key,
this.machine,
});

@override
State<AddMachinePage> createState() =>
_AddMachinePageState();
}

class _AddMachinePageState
extends State<AddMachinePage> {
late TextEditingController nameController;
late TextEditingController ceilingController;
late TextEditingController resetCeilingController;
late TextEditingController payoutRateController;
late TextEditingController gamesPerHourController;
late TextEditingController probabilityController;
late TextEditingController averagePayoutController;
late TextEditingController investmentPerGameController;
late TextEditingController gamesPer50CoinsController;

String selectedType = 'スロット';
bool favorite = false;

bool get isEdit => widget.machine != null;

@override
void initState() {
super.initState();

final machine = widget.machine;

nameController = TextEditingController(
text: machine?.name ?? '',
);

ceilingController = TextEditingController(
text: '${machine?.ceiling ?? 999}',
);

resetCeilingController =
TextEditingController(
text: '${machine?.resetCeiling ?? 500}',
);

payoutRateController =
TextEditingController(
text: '${machine?.payoutRate ?? 97}',
);

gamesPerHourController =
TextEditingController(
text: '${machine?.gamesPerHour ?? 800}',
);

probabilityController =
TextEditingController(
text: '${machine?.initialProbability ?? 1.0}',
);

averagePayoutController =
TextEditingController(
text: '${machine?.averagePayout ?? 500}',
);

investmentPerGameController =
TextEditingController(
text: '${machine?.investmentPerGame ?? 20}',
);

gamesPer50CoinsController =
TextEditingController(
text: '${machine?.gamesPer50Coins ?? 33}',
);

selectedType =
machine?.type ?? 'スロット';

favorite = machine?.favorite ?? false;
}

@override
void dispose() {
nameController.dispose();
ceilingController.dispose();
resetCeilingController.dispose();
payoutRateController.dispose();
gamesPerHourController.dispose();
probabilityController.dispose();
averagePayoutController.dispose();
investmentPerGameController.dispose();
gamesPer50CoinsController.dispose();

super.dispose();
}

double parseDouble(
TextEditingController controller,
double defaultValue,
) {
final value = double.tryParse(
controller.text.trim(),
);

if (value == null ||
value.isNaN ||
value.isInfinite) {
return defaultValue;
}

return value;
}

int parseInt(
TextEditingController controller,
int defaultValue,
) {
return int.tryParse(
controller.text.trim(),
) ??
defaultValue;
}

void save() {
final name =
nameController.text.trim();

if (name.isEmpty) {
ScaffoldMessenger.of(context)
.showSnackBar(
const SnackBar(
content: Text(
'台名を入力してください',
),
),
);
return;
}

final ceiling =
parseInt(
ceilingController,
999,
);

final resetCeiling =
parseInt(
resetCeilingController,
500,
);

final payoutRate =
parseDouble(
payoutRateController,
97,
);

final gamesPerHour =
parseDouble(
gamesPerHourController,
800,
);

final probability =
parseDouble(
probabilityController,
1.0,
);

final averagePayout =
parseDouble(
averagePayoutController,
500,
);

final investmentPerGame =
parseDouble(
investmentPerGameController,
20,
);

final gamesPer50Coins =
parseDouble(
gamesPer50CoinsController,
33,
);

final machine = MachineData(
name: name,
type: selectedType,
ceiling:
ceiling > 0 ? ceiling : 999,
resetCeiling:
resetCeiling > 0
? resetCeiling
: 500,
payoutRate:
payoutRate >= 0
? payoutRate
: 97,
gamesPerHour:
gamesPerHour > 0
? gamesPerHour
: 800,
initialProbability:
probability > 0
? probability
: 1.0,
averagePayout:
averagePayout >= 0
? averagePayout
: 500,
investmentPerGame:
investmentPerGame >= 0
? investmentPerGame
: 20,
gamesPer50Coins:
gamesPer50Coins > 0
? gamesPer50Coins
: 33,
favorite: favorite,
);

Navigator.pop(
context,
machine,
);
}

Widget numberField({
required TextEditingController controller,
required String label,
required String suffix,
bool decimal = false,
String? helperText,
}) {
return TextField(
controller: controller,
keyboardType:
TextInputType.numberWithOptions(
decimal: decimal,
),
decoration: InputDecoration(
labelText: label,
suffixText: suffix,
helperText: helperText,
border:
const OutlineInputBorder(),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(
isEdit ? '台を編集' : '台を追加',
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
),
body: SafeArea(
child: ListView(
padding:
const EdgeInsets.all(16),
children: [
const Text(
'基本設定',
style: TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 16),
TextField(
controller:
nameController,
decoration:
const InputDecoration(
labelText: '台名',
hintText:
'例：スマスロ北斗の拳',
border:
OutlineInputBorder(),
prefixIcon:
Icon(
Icons
.casino_outlined,
),
),
),
const SizedBox(height: 16),
DropdownButtonFormField<String>(
initialValue: selectedType,
decoration:
const InputDecoration(
labelText: '種類',
border:
OutlineInputBorder(),
),
items: const [
DropdownMenuItem(
value: 'スロット',
child: Text('スロット'),
),
DropdownMenuItem(
value: 'パチンコ',
child: Text('パチンコ'),
),
],
onChanged: (value) {
if (value == null) {
return;
}

setState(() {
selectedType = value;
});
},
),
const SizedBox(height: 12),
SwitchListTile(
contentPadding:
EdgeInsets.zero,
title:
const Text(
'お気に入り登録',
),
subtitle:
const Text(
'よく使う台をお気に入りに登録できます',
),
value: favorite,
onChanged:
(value) {
setState(() {
favorite =
value;
});
},
secondary:
Icon(
favorite
? Icons.star
: Icons.star_border,
),
),
const SizedBox(height: 20),
const Text(
'天井・ゲーム数設定',
style: TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: numberField(
controller:
ceilingController,
label: '通常天井',
suffix: 'G',
),
),
const SizedBox(width: 12),
Expanded(
child: numberField(
controller:
resetCeilingController,
label: 'リセット天井',
suffix: 'G',
),
),
],
),
const SizedBox(height: 8),
const Text(
'リセット時と通常時で別々の天井を設定できます。',
style: TextStyle(
fontSize: 12,
color: Colors.black54,
),
),
const SizedBox(height: 28),
const Text(
'期待値計算設定',
style: TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 16),
numberField(
controller:
payoutRateController,
label: '出玉率',
suffix: '%',
decimal: true,
),
const SizedBox(height: 12),
numberField(
controller:
gamesPerHourController,
label: '1時間あたりのゲーム数',
suffix: 'G',
decimal: true,
),
const SizedBox(height: 12),
numberField(
controller:
probabilityController,
label: '初当たり確率',
suffix: '%',
decimal: true,
helperText:
'例：1/100なら 1.0%',
),
const SizedBox(height: 12),
numberField(
controller:
averagePayoutController,
label: '平均払い出し',
suffix: '円',
decimal: true,
),
const SizedBox(height: 12),
numberField(
controller:
investmentPerGameController,
label: '1Gあたり投資額',
suffix: '円',
decimal: true,
),
const SizedBox(height: 12),
numberField(
controller:
gamesPer50CoinsController,
label: '50枚あたりゲーム数',
suffix: 'G',
decimal: true,
),
const SizedBox(height: 28),
Container(
padding:
const EdgeInsets.all(14),
decoration:
BoxDecoration(
color:
Colors.blue.withOpacity(
0.06,
),
borderRadius:
BorderRadius.circular(
12,
),
),
child: const Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Icon(
Icons.info_outline,
size: 20,
),
SizedBox(width: 10),
Expanded(
child: Text(
'設定した数値をもとに期待値を計算します。実際の期待値は機種ごとの仕様や状況によって変動します。',
style:
TextStyle(
fontSize: 13,
),
),
),
],
),
),
const SizedBox(height: 30),
FilledButton.icon(
onPressed: save,
icon:
const Icon(Icons.save),
label: Text(
isEdit
? '変更を保存'
: 'この台を保存',
style:
const TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),
style:
FilledButton.styleFrom(
minimumSize:
const Size.fromHeight(
54,
),
),
),
const SizedBox(height: 12),
OutlinedButton(
onPressed: () {
Navigator.pop(context);
},
style:
OutlinedButton.styleFrom(
minimumSize:
const Size.fromHeight(
50,
),
),
child:
const Text('キャンセル'),
),
const SizedBox(height: 20),
],
),
),
);
}
}

// ============================================================
// ランキング
// ============================================================

class RankingPage extends StatefulWidget {
final List<MachineData> machines;

const RankingPage({
super.key,
required this.machines,
});

@override
State<RankingPage> createState() =>
_RankingPageState();
}

class _RankingPageState
extends State<RankingPage> {
String selectedType = 'すべて';

double calculateRankingValue(
MachineData machine,
) {
return calculateExpectedValue(
currentGame: 0,
ceiling: machine.ceiling,
investment: 0,
payoutRate: machine.payoutRate,
initialProbability:
machine.initialProbability,
averagePayout:
machine.averagePayout,
investmentPerGame:
machine.investmentPerGame,
);
}

@override
Widget build(BuildContext context) {
final filtered = widget.machines
.where(
(machine) =>
selectedType == 'すべて' ||
machine.type == selectedType,
)
.toList();

filtered.sort(
(a, b) {
return calculateRankingValue(b)
.compareTo(
calculateRankingValue(a),
);
},
);

return Scaffold(
appBar: AppBar(
title: const Text(
'期待値ランキング',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
body: Column(
children: [
Container(
padding:
const EdgeInsets.all(12),
color: Colors.white,
child:
SingleChildScrollView(
scrollDirection:
Axis.horizontal,
child:
SegmentedButton<String>(
segments: const [
ButtonSegment(
value: 'すべて',
label: Text('すべて'),
),
ButtonSegment(
value: 'スロット',
label: Text('スロット'),
),
ButtonSegment(
value: 'パチンコ',
label: Text('パチンコ'),
),
],
selected: {
selectedType,
},
onSelectionChanged:
(values) {
setState(() {
selectedType =
values.first;
});
},
),
),
),
Expanded(
child: filtered.isEmpty
? const Center(
child: Text(
'登録されている台がありません',
),
)
: ListView.builder(
padding:
const EdgeInsets.all(
16,
),
itemCount:
filtered.length,
itemBuilder:
(context, index) {
final machine =
filtered[index];

final value =
calculateRankingValue(
machine,
);

return _buildRankingCard(
machine,
value,
index,
);
},
),
),
],
),
);
}

Widget _buildRankingCard(
MachineData machine,
double value,
int index,
) {
final rank = index + 1;

IconData? icon;

if (rank == 1) {
icon = Icons.emoji_events;
} else if (rank == 2) {
icon = Icons.workspace_premium;
} else if (rank == 3) {
icon = Icons.military_tech;
}

return Card(
margin:
const EdgeInsets.only(
bottom: 12,
),
child: Padding(
padding:
const EdgeInsets.all(16),
child: Row(
children: [
Container(
width: 48,
height: 48,
alignment:
Alignment.center,
decoration:
const BoxDecoration(
shape: BoxShape.circle,
color: Colors.blueGrey,
),
child:
icon != null
? Icon(
icon,
color:
Colors.white,
)
: Text(
'$rank',
style:
const TextStyle(
color:
Colors.white,
fontWeight:
FontWeight.bold,
fontSize: 18,
),
),
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Flexible(
child: Text(
machine.name,
style:
const TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),
),
if (machine.favorite)
const Padding(
padding:
EdgeInsets.only(
left: 5,
),
child:
Icon(
Icons.star,
size: 17,
color: Colors.amber,
),
),
],
),
const SizedBox(height: 4),
Text(
'${machine.type} ・ 天井 ${machine.ceiling}G',
style:
const TextStyle(
fontSize: 13,
color:
Colors.black54,
),
),
],
),
),
const SizedBox(width: 8),
Column(
crossAxisAlignment:
CrossAxisAlignment.end,
children: [
const Text(
'期待値',
style:
TextStyle(
fontSize: 12,
color:
Colors.black54,
),
),
const SizedBox(height: 2),
Text(
formatYen(value),
style: TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
color:
value >= 0
? Colors.green
: Colors.red,
),
),
],
),
],
),
),
);
}
}

// ============================================================
// 比較
// ============================================================

class ComparisonPage extends StatefulWidget {
final List<MachineData> machines;

const ComparisonPage({
super.key,
required this.machines,
});

@override
State<ComparisonPage> createState() =>
_ComparisonPageState();
}

class _ComparisonPageState
extends State<ComparisonPage> {
final Set<int> selectedIndexes = <int>{};

final Map<int, TextEditingController>
gameControllers = {};

final Map<int, TextEditingController>
investmentControllers = {};

@override
void initState() {
super.initState();

for (int i = 0;
i < widget.machines.length;
i++) {
gameControllers[i] =
TextEditingController(
text: '0',
);

investmentControllers[i] =
TextEditingController(
text: '0',
);
}

for (
int i = 0;
i < widget.machines.length && i < 3;
i++
) {
selectedIndexes.add(i);
}
}

@override
void dispose() {
for (final controller
in gameControllers.values) {
controller.dispose();
}

for (final controller
in investmentControllers.values) {
controller.dispose();
}

super.dispose();
}

MachineResult calculate(
int index,
) {
final machine =
widget.machines[index];

final game =
int.tryParse(
gameControllers[index]?.text ??
'0',
) ??
0;

final investment =
int.tryParse(
investmentControllers[index]
?.text ??
'0',
) ??
0;

final safeCeiling =
machine.ceiling > 0
? machine.ceiling
: 1;

final safeGame = game
.clamp(
0,
safeCeiling,
)
.toInt();

return MachineResult(
machine: machine,
currentGame: safeGame,
investment:
investment < 0
? 0
: investment,
useResetCeiling: false,
);
}

@override
Widget build(BuildContext context) {
final selected =
selectedIndexes.toList()..sort();

return Scaffold(
appBar: AppBar(
title: const Text(
'台を比較',
style:
TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
body: Column(
children: [
_buildSelectionHeader(),
Expanded(
child: selected.isEmpty
? const Center(
child: Text(
'比較する台を選択してください',
),
)
: ListView.builder(
padding:
const EdgeInsets.fromLTRB(
12,
12,
12,
30,
),
itemCount:
selected.length,
itemBuilder:
(context, position) {
final index =
selected[position];

return _buildComparisonCard(
index,
);
},
),
),
],
),
);
}

Widget _buildSelectionHeader() {
return Container(
width: double.infinity,
padding:
const EdgeInsets.all(12),
color: Colors.white,
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'比較する台を選択',
style: TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 16,
),
),
const SizedBox(height: 8),
SizedBox(
height: 48,
child: ListView.builder(
scrollDirection:
Axis.horizontal,
itemCount:
widget.machines.length,
itemBuilder:
(context, index) {
final machine =
widget.machines[index];

final selected =
selectedIndexes
.contains(index);

return Padding(
padding:
const EdgeInsets.only(
right: 8,
),
child: FilterChip(
selected: selected,
label: Text(
machine.name,
),
onSelected:
(value) {
setState(() {
if (value) {
selectedIndexes
.add(index);
} else {
selectedIndexes
.remove(index);
}
});
},
),
);
},
),
),
const SizedBox(height: 4),
Text(
'${selectedIndexes.length}台を比較中',
style: const TextStyle(
fontSize: 12,
color: Colors.black54,
),
),
],
),
);
}

Widget _buildComparisonCard(
int index,
) {
final machine =
widget.machines[index];

final result = calculate(index);

final positive =
result.expectedValue >= 0;

return Card(
margin:
const EdgeInsets.only(
bottom: 12,
),
child: Padding(
padding:
const EdgeInsets.all(16),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
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
Text(
formatYen(
result.expectedValue,
),
style:
TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
color:
positive
? Colors.green
: Colors.red,
),
),
],
),
const SizedBox(height: 4),
Text(
'${machine.type} ・ 天井 ${machine.ceiling}G',
style:
const TextStyle(
color:
Colors.black54,
),
),
const Divider(),
Row(
children: [
Expanded(
child: TextField(
controller:
gameControllers[index],
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
labelText:
'現在ゲーム数',
suffixText:
'G',
isDense: true,
),
onChanged:
(_) {
setState(() {});
},
),
),
const SizedBox(
width: 10,
),
Expanded(
child: TextField(
controller:
investmentControllers[index],
keyboardType:
TextInputType.number,
decoration:
const InputDecoration(
labelText:
'投資額',
suffixText:
'円',
isDense: true,
),
onChanged:
(_) {
setState(() {});
},
),
),
],
),
const SizedBox(height: 12),
_comparisonRow(
'天井まで',
'${result.remainingGame}G',
),
_comparisonRow(
'時給換算',
formatYen(
result.hourlyValue,
),
),
_comparisonRow(
'初当たり期待確率',
'${(result.hitProbability * 100).toStringAsFixed(1)}%',
),
],
),
),
);
}

Widget _comparisonRow(
String label,
String value,
) {
return Padding(
padding:
const EdgeInsets.only(
top: 5,
),
child: Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
Flexible(
child: Text(label),
),
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