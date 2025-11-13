import 'dart:io';
import 'package:flutter/material.dart';
import 'package:duckov_mod_manager/services/mod_manager.dart';
import 'package:duckov_mod_manager/services/collections/mod_collection.dart';
import 'package:duckov_mod_manager/services/theme_manager.dart';

/// 合集编辑对话框组件
class CollectionEditDialog extends StatefulWidget {
  final ModCollection? collection; // 编辑时传入，创建时为null
  final List<ModInfo>? availableMods;  // 可选的模组列表

  const CollectionEditDialog({
    super.key,
    this.collection,
    required this.availableMods,
  });

  @override
  State<CollectionEditDialog> createState() => _CollectionEditDialogState();
}

class _CollectionEditDialogState extends State<CollectionEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  late bool _exclusive;
  late Set<String> _selectedModIds;
  bool _isSaving = false;
  String _modSearchQuery = '';
  List<ModInfo> _filteredMods = [];

  @override
  void initState() {
    super.initState();
    
    // 如果是编辑模式，使用现有合集的数据
    if (widget.collection != null) {
      _name = widget.collection!.name;
      _description = widget.collection!.description;
      _exclusive = widget.collection!.exclusive;
      _selectedModIds = Set.from(widget.collection!.modIds);
    } else {
      // 创建模式，使用默认值
      _name = '';
      _description = '';
      _exclusive = false;
      _selectedModIds = {};
    }
    
    // 初始化过滤后的模组列表
    _updateFilteredMods();
  }

  void _toggleModSelection(String modId) {
    setState(() {
      if (_selectedModIds.contains(modId)) {
        _selectedModIds.remove(modId);
      } else {
        _selectedModIds.add(modId);
      }
    });
  }

  void _updateFilteredMods() {
    if (_modSearchQuery.isEmpty) {
      _filteredMods = widget.availableMods ?? [];
    } else {
      _filteredMods = (widget.availableMods ?? []).where((mod) =>
          mod.displayName.toLowerCase().contains(_modSearchQuery.toLowerCase()) ||
          mod.description.toLowerCase().contains(_modSearchQuery.toLowerCase()) ||
          mod.name.toLowerCase().contains(_modSearchQuery.toLowerCase())).toList();
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final collection = ModCollection(
        id: widget.collection?.id,
        name: _name,
        description: _description,
        modIds: _selectedModIds.toList(),
        exclusive: _exclusive,
        createdAt: widget.collection?.createdAt,
        updatedAt: DateTime.now(),
      );
      
      // 返回创建/更新的合集
      Navigator.pop(context, collection);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.collection != null;
    
    return AlertDialog(
      title: Text(isEditMode ? '编辑合集' : '创建合集'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 合集名称输入
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: '合集名称'),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return '请输入合集名称';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!.trim(),
                onChanged: (value) => _name = value.trim(),
                maxLength: 50,
              ),
              
              // 合集描述输入
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: '合集描述（可选）'),
                maxLines: 3,
                maxLength: 200,
                onChanged: (value) => _description = value,
              ),
              
              // 互斥选项
              CheckboxListTile(
                title: const Text('与其他合集互斥'),
                subtitle: const Text('启用此合集时，将自动禁用其他所有互斥合集'),
                value: _exclusive,
                onChanged: (value) {
                  setState(() => _exclusive = value ?? false);
                },
              ),
              
              // 模组选择列表
              const SizedBox(height: 16),
              const Text('选择模组:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: List.generate(widget.availableMods?.length ?? 0, (index) {
                    final mod = widget.availableMods![index];
                    final isSelected = _selectedModIds.contains(mod.id);
                    return CheckboxListTile(
                      title: Text(mod.name, style: const TextStyle(fontSize: 14)),
                      subtitle: Text('${mod.version} - ${mod.name}', style: const TextStyle(fontSize: 12)),
                      value: isSelected,
                      onChanged: (_) => _toggleModSelection(mod.id),
                      dense: true,
                    );
                  }),
                ),
              ),
              
              // 已选择模组数量提示
              Text(
                '已选择 ${_selectedModIds.length} 个模组',
                style: TextStyle(color: _selectedModIds.isEmpty ? Colors.red : Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSaving || _selectedModIds.isEmpty ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
              : const Text('保存'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.end,
    );
  }
}

/// 显示合集编辑对话框的便捷方法
Future<ModCollection?> showCollectionEditDialog(
  BuildContext context,
  List<ModInfo> availableMods,
  {ModCollection? collection}
) async {
  return await showDialog<ModCollection?>(
    context: context,
    builder: (context) => CollectionEditDialog(
      collection: collection,
      availableMods: availableMods,
    ),
  );
}