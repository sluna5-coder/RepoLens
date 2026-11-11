/// Commit reciente (GET /repos/{owner}/{repo}/commits).
class CommitInfo {
  const CommitInfo({
    required this.sha,
    required this.message,
    required this.authorName,
    required this.date,
    this.avatarUrl,
  });

  final String sha;
  final String message;
  final String authorName;
  final DateTime? date;
  final String? avatarUrl;

  /// Primeros 7 caracteres del hash, como los muestra GitHub.
  String get shortSha => sha.length > 7 ? sha.substring(0, 7) : sha;

  /// Primera línea del mensaje.
  String get title => message.split('\n').first;

  factory CommitInfo.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>;
    final author = (commit['author'] as Map<String, dynamic>?) ?? const {};
    final user = json['author'] as Map<String, dynamic>?;
    final date = author['date'];
    return CommitInfo(
      sha: json['sha'] as String,
      message: (commit['message'] as String?) ?? '',
      authorName: (author['name'] as String?) ?? 'Desconocido',
      date: date is String ? DateTime.tryParse(date) : null,
      avatarUrl: user?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'sha': sha,
        'commit': {
          'message': message,
          'author': {'name': authorName, 'date': date?.toIso8601String()},
        },
        'author': avatarUrl == null ? null : {'avatar_url': avatarUrl},
      };
}
