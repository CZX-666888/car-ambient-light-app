import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/light_controller.dart';
import '../l10n/app_localizations.dart';
import '../screens/main_control_screen.dart';

/// 预设颜色块 + RGB 显示（R006优化版，水平并排布局）
/// 左侧：RGB三个色块垂直排列
/// 右侧：2行x5列预设颜色
class PresetColors extends StatelessWidget {
  const PresetColors({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer<LightController>(
      builder: (context, controller, child) {
        final rgb = controller.currentRGB;
        final presetColors = controller.effectivePresetColors;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 内容区：左侧RGB（带RGB标签居中），右侧预设颜色（2排x5列），上下精确对齐
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧：RGB标签居中 + 三个色块垂直排列居中
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'RGB',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        _buildRGBBlock('R', rgb['R']!, Colors.red),
                        const SizedBox(height: 6),
                        _buildRGBBlock('G', rgb['G']!, Colors.green),
                        const SizedBox(height: 6),
                        _buildRGBBlock('B', rgb['B']!, Colors.blue),
                      ],
                    ),
                    // 中间竖线分隔
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: const Color(0xFF333333),
                    ),
                    // 右侧：常用颜色收藏标签（与RGB标签同一水平线）+ 2排x5列预设颜色
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Q032：常用颜色收藏文字，与左侧RGB标签同一水平线，居中
                          Text(
                            l10n.commonColors,
                            style: const TextStyle(color: Color(0xFF888888), fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (i) => _buildPresetColorDot(context, presetColors, i, controller)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (i) => _buildPresetColorDot(context, presetColors, i + 5, controller)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// RGB 色块（底色 + 白色数值，点击弹出调节弹窗）
  Widget _buildRGBBlock(String label, int value, Color bgColor) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            if (!MainControlScreen.checkBluetooth(context)) return;
            _showRGBDialog(context);
          },
          child: Container(
            width: 50,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$label $value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 预设颜色圆点
  Widget _buildPresetColorDot(BuildContext context, List<Color> presetColors, int index, LightController controller) {
    if (index >= presetColors.length) return const SizedBox.shrink();
    final color = presetColors[index];
    final isSelected = controller.selectedPresetIndex == index;
    return GestureDetector(
      onTap: () {
        if (!MainControlScreen.checkBluetooth(context)) return;
        controller.selectPresetColor(index);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: const Color(0xFF00E5FF), width: 3)
              : Border.all(color: Colors.white24, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  /// RGB 调节弹窗
  void _showRGBDialog(BuildContext context) {
    final controller = context.read<LightController>();
    final l10n = AppLocalizations.of(context);
    int r = controller.currentRGB['R']!;
    int g = controller.currentRGB['G']!;
    int b = controller.currentRGB['B']!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: Center(
                child: Text(
                  l10n.rgbColorAdjust,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 预览颜色
                  Container(
                    width: double.infinity,
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, r, g, b),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                  _buildRGBSlider('R', r, Colors.red, (val) {
                    setState(() => r = val);
                  }),
                  _buildRGBSlider('G', g, Colors.green, (val) {
                    setState(() => g = val);
                  }),
                  _buildRGBSlider('B', b, Colors.blue, (val) {
                    setState(() => b = val);
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    controller.setColorFromRGB(r, g, b);
                    Navigator.pop(context);
                  },
                  child: Text(l10n.confirm, style: const TextStyle(color: Color(0xFF00E5FF))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRGBSlider(String label, int value, Color color, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: color,
            inactiveColor: Colors.grey,
            onChanged: (val) => onChanged(val.round()),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
