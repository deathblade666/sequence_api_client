class Tag {
  final int? id;
  final String name;
  final String color;
  final String type;

  Tag({this.id, required this.name, required this.color, required this.type});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color,
    'type': type,
  };

  factory Tag.fromMap(Map<String, dynamic> map) => Tag(
    id: map['id'] as int?,
    name: map['name'] as String,
    color: map['color'] as String,
    type: map['type'] as String,
  );
}
