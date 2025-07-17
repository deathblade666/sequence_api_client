class Crules {
  final int? id;
  final String name;
  final String timestamp;

  Crules({this.id, required this.name,required this.timestamp});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'timestamp': timestamp
  };

  factory Crules.fromMap(Map<String, dynamic> map) => Crules(
    id: map['id'],
    name: map['name'],
    timestamp: map['timestamp']
  );
}
