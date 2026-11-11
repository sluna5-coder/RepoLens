/// Contribuidor (GET /repos/{owner}/{repo}/contributors).
class Contributor {
  const Contributor({
    required this.login,
    required this.avatarUrl,
    required this.contributions,
  });

  final String login;
  final String avatarUrl;
  final int contributions;

  factory Contributor.fromJson(Map<String, dynamic> json) => Contributor(
        login: json['login'] as String,
        avatarUrl: (json['avatar_url'] as String?) ?? '',
        contributions: (json['contributions'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'login': login, 'avatar_url': avatarUrl, 'contributions': contributions};
}
