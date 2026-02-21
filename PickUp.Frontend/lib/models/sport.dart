class Sport {
  final int id;
  final String name;

  Sport({required this.id, required this.name});

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String,
    );
  }
}