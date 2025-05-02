class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String role; // 'user' or 'officer'

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      role: map['role'] ?? 'user',
    );
  }
}
