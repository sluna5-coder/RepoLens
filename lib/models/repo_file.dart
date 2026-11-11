/// Archivo o carpeta de la raíz (GET /repos/{owner}/{repo}/contents).
class RepoFile {
  const RepoFile({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
  });

  final String name;
  final String path;

  /// "file" o "dir".
  final String type;
  final int size;

  bool get isDir => type == 'dir';

  factory RepoFile.fromJson(Map<String, dynamic> json) => RepoFile(
        name: json['name'] as String,
        path: (json['path'] as String?) ?? json['name'] as String,
        type: (json['type'] as String?) ?? 'file',
        size: (json['size'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {'name': name, 'path': path, 'type': type, 'size': size};
}
