class AppUser {
  String uid;
  String name;
  String email;
  String photoUrl;
  DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
    };
  }

  factory AppUser.fromMap(Map map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
    );
  }
}