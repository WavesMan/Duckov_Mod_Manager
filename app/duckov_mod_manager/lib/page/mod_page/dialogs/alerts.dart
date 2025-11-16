import 'package:flutter/material.dart';

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('错误'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}

void showSuccessDialog(BuildContext context, String message, {VoidCallback? onOk}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('成功'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onOk != null) onOk();
          },
          child: const Text('确定'),
        ),
      ],
    ),
  );
}