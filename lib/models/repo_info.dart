/// Datos generales de un repositorio (GET /repos/{owner}/{repo}).
class RepoInfo {
  const RepoInfo({
    required this.fullName,
    required this.name,
    required this.ownerLogin,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.description,
    required this.stars,
    required this.forks,
    required this.watchers,
    required this.openIssues,
    required this.license,
    required this.sizeKb,
    required this.defaultBranch,
    required this.createdAt,
    required this.updatedAt,
    required this.pushedAt,
    required this.topics,
    this.isPrivate = false,
  });

  final String fullName;
  final String name;
  final String ownerLogin;
  final String avatarUrl;
  final String htmlUrl;
  final String? description;
  final int stars;
  final int forks;
  final int watchers;
  final int openIssues;

  /// Nombre de la licencia, o `null` si el repo no tiene.
  final String? license;
  final int sizeKb;
  final String defaultBranch;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Fecha del último push (se usa como respaldo del último commit).
  final DateTime? pushedAt;
  final List<String> topics;

  /// `true` si el repo es privado (solo visible con un token). Estos informes
  /// no se guardan en la caché compartida del dispositivo.
  final bool isPrivate;

  /// Construye el modelo a partir del JSON de GitHub.
  factory RepoInfo.fromJson(Map<String, dynamic> json) {
    final owner = (json['owner'] as Map<String, dynamic>?) ?? const {};
    final license = json['license'] as Map<String, dynamic>?;
    return RepoInfo(
      fullName: json['full_name'] as String,
      isPrivate: json['private'] == true,
      name: json['name'] as String,
      ownerLogin: (owner['login'] as String?) ?? '',
      avatarUrl: (owner['avatar_url'] as String?) ?? '',
      htmlUrl: (json['html_url'] as String?) ?? '',
      description: json['description'] as String?,
      stars: (json['stargazers_count'] as int?) ?? 0,
      forks: (json['forks_count'] as int?) ?? 0,
      watchers: (json['subscribers_count'] as int?) ?? (json['watchers_count'] as int?) ?? 0,
      openIssues: (json['open_issues_count'] as int?) ?? 0,
      license: license?['name'] as String?,
      sizeKb: (json['size'] as int?) ?? 0,
      defaultBranch: (json['default_branch'] as String?) ?? 'main',
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      pushedAt: _date(json['pushed_at']),
      topics: ((json['topics'] as List?) ?? const []).cast<String>(),
    );
  }

  /// Serializa con la misma forma que la API, para que `fromJson` lo relea.
  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'private': isPrivate,
        'name': name,
        'owner': {'login': ownerLogin, 'avatar_url': avatarUrl},
        'html_url': htmlUrl,
        'description': description,
        'stargazers_count': stars,
        'forks_count': forks,
        'subscribers_count': watchers,
        'open_issues_count': openIssues,
        'license': license == null ? null : {'name': license},
        'size': sizeKb,
        'default_branch': defaultBranch,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'pushed_at': pushedAt?.toIso8601String(),
        'topics': topics,
      };

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
}
