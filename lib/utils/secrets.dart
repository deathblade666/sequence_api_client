class Secrets {
  final int? id;
  final String secret;

  Secrets({this.id, required this.secret});

  Map<String, dynamic> toMap() => {
    'id': id,
    'secret': secret
  };

  factory Secrets.fromMap(Map<String, dynamic> map) => Secrets(
    id: map['id'],
    secret: map['secret']
  );
}