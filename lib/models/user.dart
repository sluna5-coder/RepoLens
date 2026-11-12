/// Usuario local (tabla `users`). La contraseña nunca se guarda en claro:
/// solo su hash (PBKDF2-HMAC-SHA256, o SHA-256 en cuentas antiguas) y el salt.
class User {
  const User({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  User copyWith({int? id}) => User(
        id: id ?? this.id,
        name: name,
        email: email,
        passwordHash: passwordHash,
        salt: salt,
        createdAt: createdAt,
      );

  /// Desde una fila de SQLite.
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int?,
        name: json['name'] as String,
        email: json['email'] as String,
        passwordHash: json['password_hash'] as String,
        salt: json['salt'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// Hacia una fila de SQLite.
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': createdAt.toIso8601String(),
      };
}
