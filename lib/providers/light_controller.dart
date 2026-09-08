import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/light_state.dart';
import '../services/bluetooth_protocol.dart';
import '../utils/color_utils.dart';
import 'bluetooth_manager.dart';

class LightController extends ChangeNotifier {
  final BluetoothManager bluetoothManager;

  // 当前选中的分区
  LightZone _currentZone = LightZone.all;
  LightZone get currentZone => _currentZone;

  // 各分区状态
  final Map<LightZone, ZoneLightState> _zoneStates = {};
  Map<LightZone, ZoneLightState> get zoneStates => Map.unmodifiable(_zoneStates);

  // 当前分区状态
  ZoneLightState get currentState => _zoneStates[_currentZone]!;

  // 最后发送的指令（用于调试显示）
  String? _lastSentCommand;
  String? get lastSentCommand => _lastSentCommand;

  // R006：当前选中的预设颜色索引（-1表示未选中）
  int _selectedPresetIndex = -1;
  int get selectedPresetIndex => _selectedPresetIndex;

  // R006：用户自定义的预设颜色（持久化）
  List<Color> _customPresetColors = [];
  List<Color> get customPresetColors => List.unmodifiable(_customPresetColors);

  static const String _prefsPresetColorsKey = 'custom_preset_colors_v2';

  LightController({required this.bluetoothManager}) {
    // 初始化所有分区状态
    for (final zone in LightZone.values) {
      _zoneStates[zone] = ZoneLightState(zone: zone);
    }
    // R006：加载用户自定义预设颜色
    _loadCustomPresetColors();
  }

  /// R006：加载用户自定义预设颜色
  Future<void> _loadCustomPresetColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorStrings = prefs.getStringList(_prefsPresetColorsKey);
      if (colorStrings != null && colorStrings.length == 10) {
        _customPresetColors = colorStrings
            .map((s) => Color(int.parse(s, radix: 16)))
            .toList();
      } else {
        // 使用默认预设颜色
        _customPresetColors = List.from(ColorUtils.presetColors);
      }
      notifyListeners();
    } catch (e) {
      _customPresetColors = List.from(ColorUtils.presetColors);
    }
  }

  /// R006：保存用户自定义预设颜色
  Future<void> _saveCustomPresetColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorStrings = _customPresetColors
          .map((c) => c.value.toRadixString(16).padLeft(8, '0'))
          .toList();
      await prefs.setStringList(_prefsPresetColorsKey, colorStrings);
    } catch (e) {
      // 忽略
    }
  }

  /// R006：获取有效的预设颜色（用户自定义或默认）
  List<Color> get effectivePresetColors {
    if (_customPresetColors.length == 10) {
      return _customPresetColors;
    }
    return ColorUtils.presetColors;
  }

  /// R006：选择预设颜色
  void selectPresetColor(int index) {
    _selectedPresetIndex = index;
    final colors = effectivePresetColors;
    if (index >= 0 && index < colors.length) {
      setColor(colors[index]);
    }
    notifyListeners();
  }

  /// R006：更新当前选中的预设颜色（当调色盘变化时）
  void updateSelectedPresetColor(Color color) {
    if (_selectedPresetIndex >= 0 && _selectedPresetIndex < 10) {
      if (_customPresetColors.length < 10) {
        _customPresetColors = List.from(ColorUtils.presetColors);
      }
      _customPresetColors[_selectedPresetIndex] = color;
      _saveCustomPresetColors();
      notifyListeners();
    }
  }

  /// R006：取消选中预设颜色
  void clearPresetSelection() {
    _selectedPresetIndex = -1;
    notifyListeners();
  }

  /// 切换分区
  /// P007：切换分区时继承当前分区的颜色模式和动态效果，确保三个参数独立互不影响
  void setZone(LightZone zone) {
    final current = currentState;
    _zoneStates[zone] = _zoneStates[zone]!.copyWith(
      colorMode: current.colorMode,
      effect: current.effect,
    );
    _currentZone = zone;
    notifyListeners();
  }

  /// 设置颜色
  void setColor(Color color) {
    _zoneStates[_currentZone] = currentState.copyWith(color: color);
    // R006：如果选中了预设颜色，同步更新该预设颜色
    if (_selectedPresetIndex >= 0) {
      updateSelectedPresetColor(color);
    }
    notifyListeners();
    _sendCurrentState();
  }

  /// R010：仅更新颜色显示，不下发蓝牙指令（动态模式下使用）
  void updateColorOnly(Color color) {
    _zoneStates[_currentZone] = currentState.copyWith(color: color);
    notifyListeners();
  }

  /// 设置亮度
  void setBrightness(int brightness) {
    final clamped = brightness.clamp(0, 100);
    // 去重：相同亮度值不重复发送
    if (currentState.brightness == clamped) return;
    _zoneStates[_currentZone] = currentState.copyWith(brightness: clamped);
    notifyListeners();
    _sendCurrentState();
  }

  /// 更新速度显示（仅本地UI，不发送蓝牙指令，用于拖动过程中）
  void updateSpeedDisplay(int speed) {
    _zoneStates[_currentZone] = currentState.copyWith(speed: speed.clamp(0, 100));
    notifyListeners();
  }

  /// 设置速度并发送蓝牙指令（拖动结束时调用）
  void setSpeed(int speed) {
    _zoneStates[_currentZone] = currentState.copyWith(speed: speed.clamp(0, 100));
    notifyListeners();
    _sendCurrentState();
  }

  /// 获取UI显示的速度（0~100，与协议一致）
  int get speedPercent {
    return currentState.speed;
  }

  /// 设置颜色模式
  void setColorMode(ColorMode mode) {
    _zoneStates[_currentZone] = currentState.copyWith(colorMode: mode);
    notifyListeners();
    _sendCurrentState();
  }

  /// 设置动态效果
  void setEffect(LightEffect effect) {
    _zoneStates[_currentZone] = currentState.copyWith(effect: effect);
    notifyListeners();
    _sendCurrentState();
  }

  /// 获取当前颜色的 RGB
  Map<String, int> get currentRGB {
    final color = currentState.color;
    return {'R': color.red, 'G': color.green, 'B': color.blue};
  }

  /// R006：通过RGB设置颜色
  void setColorFromRGB(int r, int g, int b) {
    final color = Color.fromARGB(255, r, g, b);
    setColor(color);
  }

  /// 发送当前分区状态到蓝牙设备
  Future<void> _sendCurrentState() async {
    if (!bluetoothManager.isConnected || bluetoothManager.writeCharacteristic == null) {
      return;
    }

    final state = currentState;
    final command = BluetoothProtocol.buildFromZoneState(state);
    _lastSentCommand = BluetoothProtocol.toHexString(command);
    await bluetoothManager.sendCommand(command);
    notifyListeners();
  }

  /// 手动发送当前状态（用于连接后同步）
  Future<void> sendCurrentStateManual() async {
    await _sendCurrentState();
  }
}
