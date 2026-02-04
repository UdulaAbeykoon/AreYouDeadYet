class Contact {
  final String id;
  final String name;
  final String email;
  final String relationship;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.relationship,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'relationship': relationship,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      relationship: json['relationship'],
    );
  }
}
