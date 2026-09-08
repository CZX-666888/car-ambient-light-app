import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// 灯光分区（协议定义 0x00~0x08，共9个区域）
enum LightZone {
  all('全部', 0x00),
  front('前部', 0x01),
  rear('后部', 0x02),
  door('车门', 0x03),
  foot('脚部', 0x04),
  top('顶部', 0x05),
  door1('车门一', 0x06),
  door2('车门二', 0x07),
  saddle('马鞍', 0x08);

  final String displayName;
  final int code;
  const LightZone(this.displayName, this.code);

  String getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case LightZone.all: return l10n.zoneAll;
      case LightZone.front: return l10n.zoneFront;
      case LightZone.rear: return l10n.zoneRear;
      case LightZone.door: return l10n.zoneDoor;
      case LightZone.foot: return l10n.zoneFoot;
      case LightZone.top: return l10n.zoneTop;
      case LightZone.door1: return l10n.zoneDoor1;
      case LightZone.door2: return l10n.zoneDoor2;
      case LightZone.saddle: return l10n.zoneSaddle;
    }
  }
}

/// 颜色模式（协议定义：高4位，共7种）
enum ColorMode {
  single('单色', 0),
  sevenColor('七色', 1),
  threeColor('三色', 2),
  redGreen('红绿', 3),
  redBlue('红蓝', 4),
  greenBlue('绿蓝', 5),
  twelveColor('十二色', 6);

  final String displayName;
  final int code;
  const ColorMode(this.displayName, this.code);

  String getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case ColorMode.single: return l10n.colorSingle;
      case ColorMode.sevenColor: return l10n.colorSeven;
      case ColorMode.threeColor: return l10n.colorThree;
      case ColorMode.redGreen: return l10n.colorRedGreen;
      case ColorMode.redBlue: return l10n.colorRedBlue;
      case ColorMode.greenBlue: return l10n.colorGreenBlue;
      case ColorMode.twelveColor: return l10n.colorTwelve;
    }
  }
}

/// 动态效果（协议定义：低4位，共3种）
enum LightEffect {
  off('关闭', 0),
  breathing('呼吸', 1),
  jump('跳变', 2);

  final String displayName;
  final int code;
  const LightEffect(this.displayName, this.code);

  String getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case LightEffect.off: return l10n.effectOff;
      case LightEffect.breathing: return l10n.effectBreathing;
      case LightEffect.jump: return l10n.effectJump;
    }
  }
}

/// UI中显示的动态效果
List<LightEffect> get visibleEffects => LightEffect.values;

/// UI中显示的位置列表（R008：隐藏"后部"和"马鞍"）
List<LightZone> get visibleZones => [
  LightZone.all,
  LightZone.front,
  LightZone.door,
  LightZone.foot,
  LightZone.top,
  LightZone.door1,
  LightZone.door2,
];

/// 单个分区的灯光状态
class ZoneLightState {
  LightZone zone;
  Color color;
  int brightness;
  ColorMode colorMode;
  LightEffect effect;
  int speed;

  ZoneLightState({
    required this.zone,
    this.color = Colors.red,
    this.brightness = 80,
    this.colorMode = ColorMode.single,
    this.effect = LightEffect.off,
    this.speed = 50,
  });

  ZoneLightState copyWith({
    LightZone? zone,
    Color? color,
    int? brightness,
    ColorMode? colorMode,
    LightEffect? effect,
    int? speed,
  }) {
    return ZoneLightState(
      zone: zone ?? this.zone,
      color: color ?? this.color,
      brightness: brightness ?? this.brightness,
      colorMode: colorMode ?? this.colorMode,
      effect: effect ?? this.effect,
      speed: speed ?? this.speed,
    );
  }
}
