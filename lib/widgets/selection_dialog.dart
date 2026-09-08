import 'package:flutter/material.dart';

/// 通用底部弹出选择弹窗（R008/R009优化版）
/// - 点击选项直接生效并关闭，无需底部确定/取消按钮
/// - 弹窗高度不超过屏幕一半
class SelectionDialog<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T selectedValue;
  final String Function(T) displayName;
  final ValueChanged<T> onConfirm;

  const SelectionDialog({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.displayName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Color(0xFF333333), height: 1),
            // 选项列表
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == selectedValue;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.grey,
                      size: 20,
                    ),
                    title: Text(
                      displayName(option),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () {
                      // 点击选项直接生效并关闭
                      onConfirm(option);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 显示选择弹窗
Future<void> showSelectionDialog<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required T selectedValue,
  required String Function(T) displayName,
  required ValueChanged<T> onConfirm,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => SelectionDialog<T>(
      title: title,
      options: options,
      selectedValue: selectedValue,
      displayName: displayName,
      onConfirm: onConfirm,
    ),
  );
}
