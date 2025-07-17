class Rule {
  final int? id;
  final String name;
  final String ruleId;
  final String timestamp;
  final String token;

  Rule({this.id, required this.name, required this.ruleId, required this.timestamp, required this.token});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'ruleId': ruleId,
    'timestamp': timestamp,
    'token': token
  };

  factory Rule.fromMap(Map<String, dynamic> map) => Rule(
    id: map['id'],
    name: map['name'],
    ruleId: map['ruleId'],
    timestamp: map['timestamp'],
    token: map['token']
  );
}
