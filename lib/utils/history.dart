class HistoryItem {
  final int? id;
  final String name;
  final String timestamp;

  HistoryItem({this.id, required this.name, required this.timestamp});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'timestamp': timestamp};

  factory HistoryItem.fromMap(Map<String, dynamic> map) =>
      HistoryItem(id: map['id'], name: map['name'], timestamp: map['timestamp']);
}
