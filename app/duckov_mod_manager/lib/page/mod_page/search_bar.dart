import 'package:flutter/material.dart';
import '../../services/theme_manager.dart';

class SearchBarCompact extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchBarCompact({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索模组...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}