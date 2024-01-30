class Fish {
  final String name;
  final String species;
  final String description;
  final String location;
  final String endangered;

  Fish({
    required this.name,
    required this.species,
    required this.description,
    required this.location,
    required this.endangered,
  });

  factory Fish.fromJson(Map<String, dynamic> json) {
    return Fish(
      name: json['name'] as String,
      species: json['species'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      endangered: json['endangered'] as String,
    );
  }
}
