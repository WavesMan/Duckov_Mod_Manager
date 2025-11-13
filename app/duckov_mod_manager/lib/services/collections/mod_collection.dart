import 'dart:convert';
import 'package:uuid/uuid.dart';

/// 模组合集数据模型类
class ModCollection {
  final String id;               // UUID生成的唯一标识
  final String name;             // 合集名称
  final String description;      // 合集描述
  final List<String> modIds;      // 包含的模组ID列表
  final bool exclusive;          // 是否与其它合集互斥
  final DateTime createdAt;      // 创建时间
  final DateTime updatedAt;      // 更新时间

  ModCollection({
    String? id,
    required this.name,
    required this.description,
    required this.modIds,
    this.exclusive = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'modIds': modIds,
        'exclusive': exclusive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// 从JSON创建实例
  factory ModCollection.fromJson(Map<String, dynamic> json) {
    return ModCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      modIds: List<String>.from(json['modIds'] as List),
      exclusive: json['exclusive'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 创建一个修改后的副本
  ModCollection copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? modIds,
    bool? exclusive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      modIds: modIds ?? this.modIds,
      exclusive: exclusive ?? this.exclusive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ModCollection(id: $id, name: $name, modCount: ${modIds.length}, exclusive: $exclusive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ModCollection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}