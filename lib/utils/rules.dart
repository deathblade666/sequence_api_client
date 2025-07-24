class Rule {
  final int? id;
  final String name;
  final String ruleId;
  final String timestamp;
  final String token;
  final int orderIndex;
  String? tags;
  String? color;

  Rule({
    this.id,
    required this.name,
    required this.ruleId,
    required this.timestamp,
    required this.token,
    this.orderIndex = 0,
    this.tags,
    this.color,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'ruleId': ruleId,
    'timestamp': timestamp,
    'token': token,
    'order_index': orderIndex,
    'tags': tags,
    'color': color,
  };

  factory Rule.fromMap(Map<String, dynamic> map) => Rule(
    id: map['id'] as int?,
    name: map['name'] as String,
    ruleId: map['ruleId'] as String,
    timestamp: map['timestamp'] as String,
    token: map['token'] as String,
    orderIndex: map['order_index'] as int? ?? 0,
    tags: map['tags'] as String?,
    color: map['color'] as String?,
  );

  Rule copyWith({
    int? id,
    String? name,
    String? ruleId,
    String? timestamp,
    String? token,
    int? orderIndex,
    String? tags,
    String? color
  }) {
    return Rule(
      id: id ?? this.id,
      name: name ?? this.name,
      ruleId: ruleId ?? this.ruleId,
      timestamp: timestamp ?? this.timestamp,
      token: token ?? this.token,
      orderIndex: orderIndex ?? this.orderIndex,
      tags: tags,
      color: color
    );
  }
}
