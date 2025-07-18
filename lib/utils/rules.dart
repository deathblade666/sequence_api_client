class Rule {
  final int? id;
  final String name;
  final String ruleId;
  final String timestamp;
  final String token;
  final int orderIndex;

  Rule({
    this.id, 
    required this.name, 
    required this.ruleId, 
    required this.timestamp, 
    required this.token,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'ruleId': ruleId,
    'timestamp': timestamp,
    'token': token,
    'order_index': orderIndex,
  };

  factory Rule.fromMap(Map<String, dynamic> map) => Rule(
    id: map['id'],
    name: map['name'],
    ruleId: map['ruleId'],
    timestamp: map['timestamp'],
    token: map['token'],
    orderIndex: map['order_index'] ?? 0,
  );

  Rule copyWith({
    int? id,
    String? name,
    String? ruleId,
    String? timestamp,
    String? token,
    int? orderIndex,
  }) {
    return Rule(
      id: id ?? this.id,
      name: name ?? this.name,
      ruleId: ruleId ?? this.ruleId,
      timestamp: timestamp ?? this.timestamp,
      token: token ?? this.token,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}