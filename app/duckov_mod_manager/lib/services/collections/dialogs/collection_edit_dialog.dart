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
    final screenSize = MediaQuery.of(context).size;
    
    return AlertDialog(
      title: Text(isEditMode ? '编辑合集' : '创建合集'),
      content: Container(
        width: screenSize.width * 0.8,
        height: screenSize.height * 0.7,
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧列：合集信息
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 合集名称输入
                      TextFormField(
                        initialValue: _name,
                        decoration: const InputDecoration(
                          labelText: '合集名称',
                          border: OutlineInputBorder(),
                        ),
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
                      
                      const SizedBox(height: 16),
                      
                      // 合集描述输入
                      TextFormField(
                        initialValue: _description,
                        decoration: const InputDecoration(
                          labelText: '合集描述（可选）',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        maxLength: 200,
                        onChanged: (value) => _description = value,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 互斥选项
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '互斥设置',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                title: const Text('与其他合集互斥'),
                                subtitle: const Text('启用此合集时，将自动禁用其他所有互斥合集'),
                                value: _exclusive,
                                onChanged: (value) {
                                  setState(() => _exclusive = value ?? false);
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 已选择模组数量提示
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _selectedModIds.isEmpty 
                              ? Colors.red.withAlpha(25) // 0.1 opacity = 25/255 alpha
                              : Colors.green.withAlpha(25), // 0.1 opacity = 25/255 alpha
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedModIds.isEmpty ? Colors.red : Colors.green,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '已选择 ${_selectedModIds.length} 个模组',
                          style: TextStyle(
                            color: _selectedModIds.isEmpty ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 右侧列：模组选择
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 模组搜索栏
                    TextField(
                      decoration: InputDecoration(
                        hintText: '搜索模组...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _modSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _modSearchQuery = '';
                                    _updateFilteredMods();
                                  });
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _modSearchQuery = value;
                          _updateFilteredMods();
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 模组列表标题
                    Row(
                      children: [
                        const Text(
                          '选择模组',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '共 ${_filteredMods.length} 个模组',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 模组卡片列表（两列瀑布流）
                    Expanded(
                      child: _filteredMods.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _modSearchQuery.isEmpty 
                                        ? '暂无可用模组'
                                        : '未找到匹配的模组',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 2.5,
                              ),
                              itemCount: _filteredMods.length,
                              itemBuilder: (context, index) {
                                final mod = _filteredMods[index];
                                final isSelected = _selectedModIds.contains(mod.id);
                                return _buildModCard(mod, isSelected);
                              },
                            ),
                    ),
                  ],
                ),
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

  // 构建模组描述（滚动显示）- 与mod_page.dart保持一致
  Widget _buildModDescription(String description) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Scrollbar(
            child: Text(
              description.isEmpty ? '暂无描述' : description,
              style: ThemeManager.bodyTextStyle().copyWith(
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建模组卡片
  Widget _buildModCard(ModInfo mod, bool isSelected) {
    return Card(
      elevation: 3,
      color: isSelected ? Colors.blue.withAlpha(25) : Colors.white, // 0.1 opacity = 25/255 alpha
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _toggleModSelection(mod.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧：1:1预览图片
              SizedBox(
                width: 80,
                height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildModPreview(mod),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 右侧：模组信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 上方：选择框和标题
                    Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) => _toggleModSelection(mod.id),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: Text(
                            mod.displayName,
                            style: ThemeManager.headingTextStyle(level: 6),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 版本信息
                    Text(
                      '版本: ${mod.version}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 描述文本（滚动显示）- 与mod_page.dart保持一致
                    Expanded(
                      child: SizedBox(
                        height: 40, // 设置固定高度以确保滚动空间
                        child: _buildModDescription(mod.description),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建模组预览图片
  Widget _buildModPreview(ModInfo mod) {
    if (mod.previewImagePath != null) {
      try {
        return Image.file(
          File(mod.previewImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultPreview();
          },
        );
      } catch (e) {
        return _buildDefaultPreview();
      }
    } else {
      return _buildDefaultPreview();
    }
  }

  // 构建默认预览
  Widget _buildDefaultPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 24,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            '无预览图',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
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