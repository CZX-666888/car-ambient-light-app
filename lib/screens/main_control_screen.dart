import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/light_state.dart';
import '../providers/light_controller.dart';
import '../providers/bluetooth_manager.dart';
import '../widgets/color_wheel.dart';
import '../widgets/preset_colors.dart';
import '../widgets/selection_dialog.dart';
import '../l10n/app_localizations.dart';
import 'bluetooth_settings_screen.dart';
import 'user_manual_screen.dart';

/// 主控制页
class MainControlScreen extends StatelessWidget {
  const MainControlScreen({super.key});

  /// Q020：检查蓝牙连接状态，未连接则提示并跳转连接界面
  static bool checkBluetooth(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bluetoothManager = context.read<BluetoothManager>();
    if (!bluetoothManager.isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.bluetoothNotConnected),
          content: Text(l10n.pleaseConnectBluetooth),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BluetoothSettingsScreen()),
                );
              },
              child: Text(l10n.goConnect),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _buildAppBar(context, l10n),
      body: Consumer<LightController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                const ColorWheel(size: 300),
                const SizedBox(height: 20),
                _buildSpeedSlider(context, controller, l10n),
                const SizedBox(height: 20),
                _buildParameterButtons(context, controller, l10n),
                const SizedBox(height: 20),
                const PresetColors(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppLocalizations l10n) {
    final bluetoothManager = context.watch<BluetoothManager>();
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: null,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    bluetoothManager.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                    color: bluetoothManager.isConnected
                        ? const Color(0xFF00E5FF)
                        : Colors.grey.withOpacity(0.4),
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BluetoothSettingsScreen()),
                    );
                  },
                ),
                Container(width: 1, height: 20, color: const Color(0xFF444444)),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.grey, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserManualScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedSlider(BuildContext context, LightController controller, AppLocalizations l10n) {
    return Row(
      children: [
        Text(l10n.slow, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: Slider(
            value: controller.speedPercent.toDouble(),
            min: 0,
            max: 100,
            activeColor: const Color(0xFF00E5FF),
            inactiveColor: const Color(0xFF333333),
            thumbColor: Colors.white,
            onChanged: (value) {
              controller.updateSpeedDisplay(value.round());
            },
            onChangeEnd: (value) {
              if (!MainControlScreen.checkBluetooth(context)) return;
              controller.setSpeed(value.round());
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(l10n.fast, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _buildParameterButtons(BuildContext context, LightController controller, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildParamButton(
            text: controller.currentZone.getLabel(context),
            onTap: () {
              if (!MainControlScreen.checkBluetooth(context)) return;
              showSelectionDialog<LightZone>(
                context: context,
                title: l10n.selectZone,
                options: visibleZones,
                selectedValue: controller.currentZone,
                displayName: (zone) => zone.getLabel(context),
                onConfirm: (zone) {
                  controller.setZone(zone);
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildParamButton(
            text: controller.currentState.colorMode.getLabel(context),
            onTap: () {
              if (!MainControlScreen.checkBluetooth(context)) return;
              showSelectionDialog<ColorMode>(
                context: context,
                title: l10n.selectColorMode,
                options: const [
                  ColorMode.single,
                  ColorMode.twelveColor,
                  ColorMode.sevenColor,
                  ColorMode.threeColor,
                  ColorMode.redGreen,
                  ColorMode.redBlue,
                  ColorMode.greenBlue,
                ],
                selectedValue: controller.currentState.colorMode,
                displayName: (mode) => mode.getLabel(context),
                onConfirm: (mode) {
                  controller.setColorMode(mode);
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildParamButton(
            text: controller.currentState.effect.getLabel(context),
            onTap: () {
              if (!MainControlScreen.checkBluetooth(context)) return;
              showSelectionDialog<LightEffect>(
                context: context,
                title: l10n.selectDynamicEffect,
                options: visibleEffects,
                selectedValue: controller.currentState.effect,
                displayName: (effect) => effect.getLabel(context),
                onConfirm: (effect) {
                  controller.setEffect(effect);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParamButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
