import 'package:Seqeunce_API_Client/utils/db/dbhelper.dart';
import 'package:Seqeunce_API_Client/utils/history.dart';
import 'package:flutter/foundation.dart';

class HistoryProvider with ChangeNotifier {
  List<HistoryItem> _items = [];

  List<HistoryItem> get items => _items;

  Future<void> loadHistory() async {
    _items = await DatabaseHelper().getHistory();
    notifyListeners();
  }

  Future<void> addHistory(String name) async {
    final newItem = HistoryItem(
      name: name,
      timestamp: DateTime.now().toIso8601String(),
    );
    await DatabaseHelper().insertHistory(newItem);
    await loadHistory(); 
  }

  Future<void> clearHistory() async {
  final db = await DatabaseHelper().database;
  await db.delete('history');
  _items = [];
  notifyListeners();
}

}
