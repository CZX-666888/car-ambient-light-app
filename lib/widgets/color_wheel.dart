import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/light_controller.dart';
import '../providers/bluetooth_manager.dart';
import '../models/light_state.dart';
import '../utils/color_utils.dart';
import '../l10n/app_localizations.dart';
import '../screens/bluetooth_settings_screen.dart';

/// 三层色盘组件
/// 第1层（最外圈上半圆）：亮度调节睫毛环（180度，左0右100）
/// 第2层（中间，占比最大）：完整HSV全色域取色圆盘
/// 第3层（最中心）：灯泡图标（亮暗反映亮度）+ 灯泡内亮度数字（常显）
class ColorWheel extends StatefulWidget {
  final double size;

  const ColorWheel({super.key, this.size = 280});

  @override
  State<ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<ColorWheel> {
  double _colorHue = 0.0;
  double _colorSaturation = 1.0;
  // P010：倒三角当前角度（整圈360度，从x轴正方向逆时针）
  // 亮度 = 50 + 50*cos(angle)，右=100，左=0，上下=50
  double _brightnessAngle = pi / 2; // 默认顶部，亮度50
  bool _isDraggingColor = false;
  bool _isDraggingBrightness = false;
  // Q012：动态模式提示框防抖Timer
  Timer? _tipTimer;
  bool _tipVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<LightController>();
      final hsv = HSVColor.fromColor(controller.currentState.color);
      _colorHue = hsv.hue;
      _colorSaturation = hsv.saturation;
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LightController>(
      builder: (context, controller, child) {
        final currentColor = controller.currentState.color;
        final brightness = controller.currentState.brightness;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: GestureDetector(
            onTapDown: (details) => _onTapDown(details, controller),
            onPanStart: (details) => _onPanStart(details, controller),
            onPanUpdate: (details) => _onPanUpdate(details, controller),
            onPanEnd: _onPanEnd,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _buildHSVDisk(),
                _buildBrightnessRing(currentColor, brightness),
                _buildTriangleIndicator(brightness),
                _buildColorSelector(),
                _buildCenterBulb(brightness),
              ],
            ),
          ),
        );
      },
    );
  }

  /// HSV全色域取色圆盘（完整实心圆盘）
  Widget _buildHSVDisk() {
    final diskSize = widget.size * 0.80;
    return SizedBox(
      width: diskSize,
      height: diskSize,
      child: CustomPaint(painter: _HSVDiskPainter()),
    );
  }

  /// 亮度调节睫毛环（整圈360度）
  Widget _buildBrightnessRing(Color currentColor, int brightness) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _BrightnessRingPainter(
        currentColor: currentColor,
        brightnessAngle: _brightnessAngle,
      ),
    );
  }

  /// 倒三角指示器（整圈可移动，随旋转指向圆心，尖角正对睫毛）
  Widget _buildTriangleIndicator(int brightness) {
    final angle = _brightnessAngle;
    final outerRadius = widget.size * 0.495;
    final dx = widget.size / 2 + cos(angle) * outerRadius;
    final dy = widget.size / 2 + sin(angle) * outerRadius;
    // 旋转角度使尖角指向圆心：angle + pi/2
    final rotation = angle + pi / 2;

    return Positioned(
      left: dx - 24,
      top: dy - 24,
      child: Transform.rotate(
        angle: rotation,
        child: const Icon(
          Icons.arrow_drop_down,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  /// 颜色选择点（白色空心圆，内部透明）
  Widget _buildColorSelector() {
    final diskRadius = widget.size * 0.40;
    final selectorRadius = 14.0;
    // Q017：选择点几何角度需还原90度偏移（hue加了90度，位置计算要减回去）
    final angle = (_colorHue - 90) * pi / 180;
    // Q034：取色点中心限制在 diskRadius - selectorRadius，确保外圈不溢出色盘
    final radius = _colorSaturation * (diskRadius - selectorRadius);
    final dx = widget.size / 2 + cos(angle) * radius;
    final dy = widget.size / 2 + sin(angle) * radius;

    return Positioned(
      left: dx - 14,
      top: dy - 14,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6),
          ],
        ),
      ),
    );
  }

  /// 中心灯泡 + 亮度数字（灯泡图标放大至0.85，数字放大至0.16）
  Widget _buildCenterBulb(int brightness) {
    final bulbSize = widget.size * 0.22;
    final isLit = brightness > 10;
    final bulbOpacity = (brightness / 100).clamp(0.2, 1.0);

    return Container(
      width: bulbSize,
      height: bulbSize,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: isLit
                ? Colors.white.withOpacity(bulbOpacity)
                : Colors.grey.withOpacity(0.4),
            size: bulbSize * 0.92,
          ),
          Positioned(
            top: bulbSize * 0.30,
            child: Text(
              '$brightness',
              style: TextStyle(
                color: Colors.white,
                fontSize: bulbSize * 0.16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Q020：检查蓝牙连接状态，未连接则提示并跳转连接界面
  bool _checkBluetooth() {
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

  void _onTapDown(TapDownDetails details, LightController controller) {
    if (!_checkBluetooth()) return;
    final center = widget.size / 2;
    final dx = details.localPosition.dx - center;
    final dy = details.localPosition.dy - center;
    final distance = sqrt(dx * dx + dy * dy);

    // Q033：轻触与拖动使用同一套严格判定逻辑
    // 0~0.43*size（色盘+间隙）→ 颜色选取
    // 0.43*size以外（睫毛+倒三角区域）→ 亮度调节
    if (distance >= widget.size * 0.43) {
      _isDraggingBrightness = true;
      _updateBrightness(details.localPosition, controller);
    } else {
      _isDraggingColor = true;
      _updateColor(details.localPosition, controller);
    }
  }

  void _onPanStart(DragStartDetails details, LightController controller) {
    if (!_checkBluetooth()) return;
    final center = widget.size / 2;
    final dx = details.localPosition.dx - center;
    final dy = details.localPosition.dy - center;
    final distance = sqrt(dx * dx + dy * dy);

    // Q033：首次按下严格判定
    // 0~0.43*size（色盘+间隙）→ 颜色选取（只要手指接触色盘区域默认颜色）
    // 0.43*size以外（睫毛+倒三角区域，不接触色盘）→ 亮度调节
    if (distance >= widget.size * 0.43) {
      _isDraggingBrightness = true;
      _updateBrightness(details.localPosition, controller);
    } else {
      _isDraggingColor = true;
      _updateColor(details.localPosition, controller);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, LightController controller) {
    final center = widget.size / 2;
    final dx = details.localPosition.dx - center;
    final dy = details.localPosition.dy - center;
    final distance = sqrt(dx * dx + dy * dy);

    if (_isDraggingBrightness) {
      // Q033：拖动过程中使用容差范围，保持滑动连贯性
      if (_isInBrightnessRing(dx, dy, distance)) {
        _updateBrightness(details.localPosition, controller);
      }
    } else if (_isDraggingColor) {
      // Q033：颜色选取拖动容差，外圈扩大到0.48*size
      final colorOuter = widget.size * 0.48;
      if (distance <= colorOuter) {
        _updateColor(details.localPosition, controller);
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _isDraggingBrightness = false;
    _isDraggingColor = false;
  }

  /// Q033：拖动过程容差判定（允许侵入保持连贯），内圈0.30*size，外圈0.47*size+55
  bool _isInBrightnessRing(double dx, double dy, double distance) {
    final outer = widget.size * 0.47;
    final inner = widget.size * 0.30;
    return distance >= inner && distance <= outer + 55;
  }

  /// 更新亮度（P010：整圈360度对称，brightness = 50 + 50*cos(angle)）
  /// 右(0度)=100，上(90度)=50，左(180度)=0，下(270度)=50
  /// Q019：角度吸附到最近的睫毛（60根，每根6度），尖角永远正对某根睫毛
  void _updateBrightness(Offset position, LightController controller) {
    final center = widget.size / 2;
    final dx = position.dx - center;
    final dy = position.dy - center;
    var angle = atan2(dy, dx); // -pi到pi

    // Q019：吸附到最近的睫毛角度（从顶部-pi/2开始，每根间隔2*pi/60）
    const step = 2 * pi / 60; // 6度
    final normalized = angle + pi / 2;
    final snapped = (normalized / step).round() * step;
    angle = snapped - pi / 2;

    setState(() {
      _brightnessAngle = angle;
    });

    final brightness = (50 + 50 * cos(angle)).round().clamp(0, 100);
    controller.setBrightness(brightness);
  }

  /// 更新颜色（动态模式+非单色时不下发指令，仅提示）
  void _updateColor(Offset position, LightController controller) {
    final center = widget.size / 2;
    final diskRadius = widget.size * 0.40;

    final dx = position.dx - center;
    final dy = position.dy - center;
    final distance = sqrt(dx * dx + dy * dy);
    final angle = atan2(dy, dx);

    // Q034：饱和度使用实际色盘半径计算，确保手指滑到边缘时 saturation=1.0（最饱和）
    final clampedForSaturation = distance.clamp(0.0, diskRadius);
    var hue = (angle * 180 / pi + 90) % 360;
    final saturation = (clampedForSaturation / diskRadius).clamp(0.0, 1.0);

    setState(() {
      _colorHue = hue;
      _colorSaturation = saturation;
    });

    final color = ColorUtils.hsvToColor(hue, saturation, 1.0);

    final state = controller.currentState;
    final isDynamicMode = state.effect == LightEffect.breathing || state.effect == LightEffect.jump;
    final isNotSingleColor = state.colorMode != ColorMode.single;

    if (isDynamicMode && isNotSingleColor) {
      controller.updateColorOnly(color);
      // Q012+Q016+Q018：防抖，duration设为很长完全由Timer控制隐藏，确保状态同步
      _tipTimer?.cancel();
      if (!_tipVisible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).dynamicModeNoColor),
            duration: const Duration(hours: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _tipVisible = true;
      }
      _tipTimer = Timer(const Duration(seconds: 2), () {
        _tipVisible = false;
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      });
    } else {
      controller.setColor(color);
    }
  }
}

/// HSV全色域圆盘绘制器（drawVertices三角形扇，无环纹）
class _HSVDiskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const segmentCount = 64;
    final vertices = <Offset>[];
    final colors = <Color>[];

    vertices.add(center);
    colors.add(Colors.white);

    for (int i = 0; i <= segmentCount; i++) {
      final angle = i / segmentCount * 2 * pi;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      vertices.add(Offset(x, y));
      var hue = (angle * 180 / pi + 90) % 360;
      colors.add(ColorUtils.hsvToColor(hue, 1.0, 1.0));
    }

    canvas.drawVertices(
      Vertices(VertexMode.triangleFan, vertices, colors: colors),
      BlendMode.src,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 亮度调节睫毛环绘制器（整圈360度，颜色跟随当前色，已调节亮/未调节暗）
class _BrightnessRingPainter extends CustomPainter {
  final Color currentColor;
  final double brightnessAngle;

  _BrightnessRingPainter({
    required this.currentColor,
    required this.brightnessAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.47;
    final innerRadius = size.width * 0.43;
    const lineCount = 60; // 整圈60根

    for (int i = 0; i < lineCount; i++) {
      // 睫毛角度：从顶部(-pi/2)开始顺时针整圈
      final angle = (i / lineCount) * 2 * pi - pi / 2;

      // P004：所有睫毛颜色完全跟随用户选中色，不区分已调节/未调节
      // 调节亮度时睫毛颜色和透明度完全不变，只有倒三角移动
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final x1 = center.dx + cos(angle) * innerRadius;
      final y1 = center.dy + sin(angle) * innerRadius;
      final x2 = center.dx + cos(angle) * outerRadius;
      final y2 = center.dy + sin(angle) * outerRadius;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrightnessRingPainter oldDelegate) {
    return oldDelegate.currentColor != currentColor ||
        oldDelegate.brightnessAngle != brightnessAngle;
  }
}

/// Q015：标准细线灯泡绘制器（线宽1.0，标准灯泡比例）
class _ThinBulbPainter extends CustomPainter {
  final Color color;

  _ThinBulbPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 标准灯泡比例：玻璃泡65%，灯头35%
    final glassRadius = w * 0.34;
    final glassCenterY = h * 0.35;
    final neckWidth = w * 0.22;
    final baseWidth = w * 0.30;
    final baseTop = h * 0.62;
    final baseBottom = h * 0.88;

    final path = Path();

    // 左侧：从灯头左上角开始
    path.moveTo(cx - baseWidth / 2, baseTop);
    // 颈部左斜线（向上向外到玻璃泡）
    path.lineTo(cx - neckWidth / 2, glassCenterY + glassRadius * 0.55);
    // 玻璃泡左半圆（向上到顶部再向右）
    path.arcToPoint(
      Offset(cx + neckWidth / 2, glassCenterY + glassRadius * 0.55),
      radius: Radius.circular(glassRadius),
      largeArc: true,
      clockwise: true,
    );
    // 颈部右斜线（向下到灯头右上角）
    path.lineTo(cx + baseWidth / 2, baseTop);
    // 灯头右侧竖线
    path.lineTo(cx + baseWidth / 2, baseBottom);
    // 灯头底部横线
    path.lineTo(cx - baseWidth / 2, baseBottom);
    // 灯头左侧竖线（回到起点）
    path.close();

    canvas.drawPath(path, paint);

    // 灯头螺纹线（两条横线）
    final threadY1 = baseTop + (baseBottom - baseTop) * 0.30;
    final threadY2 = baseTop + (baseBottom - baseTop) * 0.58;
    canvas.drawLine(
      Offset(cx - baseWidth / 2 + 2, threadY1),
      Offset(cx + baseWidth / 2 - 2, threadY1),
      paint,
    );
    canvas.drawLine(
      Offset(cx - baseWidth / 2 + 2, threadY2),
      Offset(cx + baseWidth / 2 - 2, threadY2),
      paint,
    );

    // 底部触点（小圆弧）
    final contactWidth = baseWidth * 0.4;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, baseBottom),
        width: contactWidth,
        height: h * 0.06,
      ),
      0,
      pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ThinBulbPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Q024：带灯丝灯泡绘制器（与APP图标灯泡形状一致，含灯丝和螺纹）
class _FilamentBulbPainter extends CustomPainter {
  final Color color;

  _FilamentBulbPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 玻璃泡：圆形，占整体约62%高度
    final glassRadius = w * 0.36;
    final glassCenterY = h * 0.36;

    // 绘制玻璃泡轮廓（圆形）
    canvas.drawCircle(Offset(cx, glassCenterY), glassRadius, paint);

    // 灯丝：M形波浪线，在玻璃泡内部
    final filamentTop = glassCenterY - glassRadius * 0.15;
    final filamentBottom = glassCenterY + glassRadius * 0.35;
    final filamentWidth = glassRadius * 0.55;

    final filamentPath = Path();
    filamentPath.moveTo(cx - filamentWidth, filamentBottom);
    filamentPath.lineTo(cx - filamentWidth * 0.5, filamentTop);
    filamentPath.lineTo(cx, filamentBottom * 0.85);
    filamentPath.lineTo(cx + filamentWidth * 0.5, filamentTop);
    filamentPath.lineTo(cx + filamentWidth, filamentBottom);
    canvas.drawPath(filamentPath, paint);

    // 灯丝支撑杆（从灯丝底部到灯头顶部）
    final supportTop = filamentBottom;
    final supportBottom = h * 0.62;
    canvas.drawLine(Offset(cx - filamentWidth * 0.5, supportTop), Offset(cx - filamentWidth * 0.3, supportBottom), paint);
    canvas.drawLine(Offset(cx + filamentWidth * 0.5, supportTop), Offset(cx + filamentWidth * 0.3, supportBottom), paint);

    // 灯头：矩形，占整体约30%高度
    final baseWidth = w * 0.42;
    final baseLeft = cx - baseWidth / 2;
    final baseRight = cx + baseWidth / 2;
    final baseTop = h * 0.62;
    final baseBottom = h * 0.88;

    // 灯头左右竖线
    canvas.drawLine(Offset(baseLeft, baseTop), Offset(baseLeft, baseBottom), paint);
    canvas.drawLine(Offset(baseRight, baseTop), Offset(baseRight, baseBottom), paint);

    // 灯头底部横线
    canvas.drawLine(Offset(baseLeft, baseBottom), Offset(baseRight, baseBottom), paint);

    // 灯头螺纹线（3条横线）
    final threadSpacing = (baseBottom - baseTop) / 4;
    for (int i = 1; i <= 3; i++) {
      final ty = baseTop + threadSpacing * i;
      canvas.drawLine(Offset(baseLeft + 2, ty), Offset(baseRight - 2, ty), paint);
    }

    // 玻璃泡与灯头连接处（颈部斜线）
    final neckWidth = glassRadius * 0.55;
    canvas.drawLine(Offset(cx - neckWidth, baseTop), Offset(baseLeft, baseTop), paint);
    canvas.drawLine(Offset(cx + neckWidth, baseTop), Offset(baseRight, baseTop), paint);
  }

  @override
  bool shouldRepaint(covariant _FilamentBulbPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
