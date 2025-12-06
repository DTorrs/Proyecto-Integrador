class Location {
  final int id;
  final String code;
  final String name;
  final String? description;

  Location({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
    );
  }
}