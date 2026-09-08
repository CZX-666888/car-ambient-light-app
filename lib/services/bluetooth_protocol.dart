import 'dart:typed_data';
import '../models/light_state.dart';

/// 蓝牙通讯协议服务（氛围通通信协议）
/// 协议帧格式（共11字节）：
/// Byte0:  起始码 0x7F（固定）
/// Byte1:  命令码 0x09（固定）
/// Byte2:  命令码 0x01（固定）
/// Byte3:  位置 0x00~0x08
/// Byte4:  亮度 0x00~0x64（0-100）
/// Byte5:  R 0x00~0xFF（0-255）
/// Byte6:  G 0x00~0xFF（0-255）
/// Byte7:  B 0x00~0xFF（0-255）
/// Byte8:  颜色和模式（高4位=颜色模式，低4位=动态效果）
/// Byte9:  速度 0x00~0x64（0-100）
/// Byte10: 结束码 0x00（固定）
class BluetoothProtocol {
  // 固定字段
  static const int startCode = 0x7F;
  static const int command1 = 0x09;
  static const int command2 = 0x01;
  static const int endCode = 0x00;

  // 范围常量
  static const int brightnessMin = 0;
  static const int brightnessMax = 100; // 0x64
  static const int speedMin = 0;
  static const int speedMax = 100; // 0x64
  static const int colorMin = 0;
  static const int colorMax = 255; // 0xFF

  /// 构建设置指令
  static List<int> buildCommand({
    required LightZone zone,
    required int brightness,
    required int red,
    required int green,
    required int blue,
    required ColorMode colorMode,
    required LightEffect effect,
    required int speed,
  }) {
    // 颜色和模式复合字节：高4位颜色模式，低4位动态效果
    final colorAndMode = (colorMode.code << 4) | (effect.code & 0x0F);

    final data = <int>[
      startCode,                          // Byte0: 起始码 0x7F
      command1,                           // Byte1: 命令码 0x09
      command2,                           // Byte2: 命令码 0x01
      zone.code,                          // Byte3: 位置 0x00~0x08
      brightness.clamp(0, 100),           // Byte4: 亮度 0~100 (0x00~0x64)
      red.clamp(0, 255),                  // Byte5: R 0~255
      green.clamp(0, 255),                // Byte6: G 0~255
      blue.clamp(0, 255),                 // Byte7: B 0~255
      colorAndMode,                       // Byte8: 颜色和模式
      speed.clamp(0, 100),                // Byte9: 速度 0~100 (0x00~0x64)
      endCode,                            // Byte10: 结束码 0x00
    ];

    return data;
  }

  /// 从灯光状态构建指令
  static List<int> buildFromZoneState(ZoneLightState state) {
    return buildCommand(
      zone: state.zone,
      brightness: state.brightness,
      red: state.color.red,
      green: state.color.green,
      blue: state.color.blue,
      colorMode: state.colorMode,
      effect: state.effect,
      speed: state.speed,
    );
  }

  /// 指令转十六进制字符串（用于调试）
  static String toHexString(List<int> data) {
    return data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(' ');
  }

  /// Uint8List 转换
  static Uint8List toUint8List(List<int> data) {
    return Uint8List.fromList(data);
  }
}
