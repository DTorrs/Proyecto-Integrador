class Status {
  final int id;
  final String name;
  final String? description;

  Status({
    required this.id,
    required this.name,
    this.description,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}