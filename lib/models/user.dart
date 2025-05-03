class AppUser {
  final String id;
  final String firebaseId;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String role; // 'user' or 'officer'

  AppUser({
    required this.id,
    required this.firebaseId,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['_id'] ?? map['id'] ?? '',
      firebaseId: map['firebaseId'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      role: map['role'] ?? 'user',
    );
  }

  @override
  String toString() {
    return 'AppUser{id: $id, firebaseId: $firebaseId, email: $email, displayName: $displayName, photoURL: $photoURL, role: $role}';
  }
}
