enum ModManagementMode { fileSystem, websocket, hybrid }

class LocalModInfo {
  final String id;
  final String path;
  final String name;
  final String displayName;
  final String description;
  final String version;
  final String size;
  final String? author;
  final String? previewImagePath;
  final bool? enabled;
  final bool? isActive;
  final bool? dllFound;
  final bool? isSteamItem;
  final int? publishedFileId;
  final String? dllPath;
  final bool? hasPreview;
  final int? priority;

  LocalModInfo({
    required this.id,
    required this.path,
    required this.name,
    required this.displayName,
    required this.description,
    required this.version,
    required this.size,
    this.author,
    this.previewImagePath,
    this.enabled,
    this.isActive,
    this.dllFound,
    this.isSteamItem,
    this.publishedFileId,
    this.dllPath,
    this.hasPreview,
    this.priority,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'name': name,
    'display_name': displayName,
    'description': description,
    'version': version,
    'size': size,
    'author': author,
    'preview_image_path': previewImagePath,
    'enabled': enabled,
    'isActive': isActive,
    'dllFound': dllFound,
    'isSteamItem': isSteamItem,
    'publishedFileId': publishedFileId,
    'dllPath': dllPath,
    'hasPreview': hasPreview,
    'priority': priority,
  };

  LocalModInfo copyWith({
    String? id,
    String? path,
    String? name,
    String? displayName,
    String? description,
    String? version,
    String? size,
    String? author,
    String? previewImagePath,
    bool? enabled,
    bool? isActive,
    bool? dllFound,
    bool? isSteamItem,
    int? publishedFileId,
    String? dllPath,
    bool? hasPreview,
    int? priority,
  }) {
    return LocalModInfo(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      version: version ?? this.version,
      size: size ?? this.size,
      author: author ?? this.author,
      previewImagePath: previewImagePath ?? this.previewImagePath,
      enabled: enabled ?? this.enabled,
      isActive: isActive ?? this.isActive,
      dllFound: dllFound ?? this.dllFound,
      isSteamItem: isSteamItem ?? this.isSteamItem,
      publishedFileId: publishedFileId ?? this.publishedFileId,
      dllPath: dllPath ?? this.dllPath,
      hasPreview: hasPreview ?? this.hasPreview,
      priority: priority ?? this.priority,
    );
  }
}