import 'dart:math';
import 'package:flutter/material.dart';

class ColorUtils {
  /// HSV 转 Color
  static Color hsvToColor(double hue, double saturation, double value) {
    final hsv = HSVColor.fromAHSV(1.0, hue, saturation, value);
    return hsv.toColor();
  }

  /// Color 转 HSV
  static HSVColor colorToHsv(Color color) {
    return HSVColor.fromColor(color);
  }

  /// 根据角度和半径计算色盘上的颜色
  static Color colorFromWheel(double angle, double radiusRatio) {
    // angle: 0-360 degrees, radiusRatio: 0-1
    final hue = angle % 360;
    final saturation = radiusRatio.clamp(0.0, 1.0);
    return hsvToColor(hue, saturation, 1.0);
  }

  /// 计算色盘上某点对应的角度和半径比例
  static Map<String, double> wheelPosition(Offset point, double centerX, double centerY, double outerRadius, double innerRadius) {
    final dx = point.dx - centerX;
    final dy = point.dy - centerY;
    var angle = atan2(dy, dx) * 180 / pi;
    if (angle < 0) angle += 360;
    final distance = sqrt(dx * dx + dy * dy);
    final radiusRatio = ((distance - innerRadius) / (outerRadius - innerRadius)).clamp(0.0, 1.0);
    return {'angle': angle, 'radiusRatio': radiusRatio};
  }

  /// 调整颜色亮度
  static Color adjustBrightness(Color color, int brightness) {
    final factor = brightness / 100.0;
    return Color.fromARGB(
      color.alpha,
      (color.red * factor).round(),
      (color.green * factor).round(),
      (color.blue * factor).round(),
    );
  }

  /// 预设颜色列表（10个，2行x5列）
  static final List<Color> presetColors = [
    const Color(0xFFFFD700), // 黄色
    const Color(0xFFFF8C00), // 橙色
    const Color(0xFFFF0000), // 红色
    const Color(0xFF0000FF), // 蓝色
    const Color(0xFFFF0066), // 玫红
    const Color(0xFF00008B), // 深蓝
    const Color(0xFF00FF00), // 绿色
    const Color(0xFF7FFF00), // 浅绿
    const Color(0xFFFFFFFF), // 白色
    const Color(0xFFFFF8DC), // 暖白
  ];
}
