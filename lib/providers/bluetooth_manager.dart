import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bluetooth_protocol.dart';

class BluetoothManager extends ChangeNotifier {
  // 蓝牙状态
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothAdapterState get adapterState => _adapterState;

  // 扫描状态
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // 扫描结果（R002：仅显示以"LED"开头的设备）
  final List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);

  // 设备列表（Q025：已连接设备置顶显示，去重）
  List<BluetoothDevice> get devices {
    final seen = <String>{};
    final allDevices = _scanResults
        .where((r) {
          final name = _getDeviceNameFromResult(r).trim();
          // Q037/Q040：仅在显示层过滤，trim去除前后空格后判断是否以"LED"开头
          return name.startsWith('LED');
        })
        .map((r) => r.device)
        .where((d) => seen.add(d.remoteId.toString()))
        .toList();

    // Q025：已连接设备置顶
    if (_connectedDevice != null) {
      allDevices.removeWhere((d) => d.remoteId == _connectedDevice!.remoteId);
      allDevices.insert(0, _connectedDevice!);
    }
    return allDevices;
  }

  /// 从扫描结果中获取设备名称（同时检查 platformName 和 advName，trim去除前后空格）
  String _getDeviceNameFromResult(ScanResult result) {
    final platformName = result.device.platformName;
    if (platformName.isNotEmpty) return platformName.trim();
    final advName = result.advertisementData.advName;
    if (advName.isNotEmpty) return advName.trim();
    return '';
  }

  // 已连接设备
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // 连接状态流订阅（用于监听断连事件）
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  // GATT 可写特征值
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? get writeCharacteristic => _writeCharacteristic;

  // 连接状态
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  bool _isDiscoveringServices = false;
  bool get isDiscoveringServices => _isDiscoveringServices;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  String? _lastCommandHex;
  String? get lastCommandHex => _lastCommandHex;

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  bool _scanResultsSubscribed = false;
  Timer? _scanNotifyTimer; // Q021：扫描结果节流，避免频繁刷新导致列表跳动
  bool _isUserInitiatedDisconnect = false; // Q036：标记用户主动断开，避免触发自动回连
  Timer? _disconnectDebounceTimer; // Q036：断连防抖，避免临时波动触发回连

  // R001：最后连接的设备信息
  String? _savedDeviceName;
  String? _savedDeviceId;
  String? get savedDeviceName => _savedDeviceName;

  bool _isAutoReconnecting = false;
  bool get isAutoReconnecting => _isAutoReconnecting;

  bool _stopAutoReconnect = false;

  static const String _prefsDeviceNameKey = 'last_bt_device_name';
  static const String _prefsDeviceIdKey = 'last_bt_device_id';

  BluetoothManager() {
    _init();
  }

  void _init() {
    // 监听蓝牙适配器状态
    FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });

    // 监听扫描状态
    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });

    // 只订阅一次扫描结果（Q021：增量更新+节流，避免列表频繁跳动）
    if (!_scanResultsSubscribed) {
      FlutterBluePlus.scanResults.listen((results) {
        // 增量更新：只添加新设备，更新已有设备的RSSI，不每次clear
        for (final result in results) {
          final existingIndex = _scanResults.indexWhere(
            (r) => r.device.remoteId == result.device.remoteId,
          );
          if (existingIndex >= 0) {
            _scanResults[existingIndex] = result;
          } else {
            _scanResults.add(result);
          }
        }
        // 节流：每300ms才通知一次UI，避免频繁刷新导致列表跳动
        _scanNotifyTimer?.cancel();
        _scanNotifyTimer = Timer(const Duration(milliseconds: 300), () {
          notifyListeners();
        });
      });
      _scanResultsSubscribed = true;
    }

    // R001：加载已保存的设备并尝试自动回连
    _loadSavedDevice();
  }

  /// R001：加载已保存的最后连接设备
  Future<void> _loadSavedDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedDeviceName = prefs.getString(_prefsDeviceNameKey);
      _savedDeviceId = prefs.getString(_prefsDeviceIdKey);
      notifyListeners();

      // 立即尝试自动回连（高优先级，仅延迟200ms确保初始化完成）
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_savedDeviceId != null && !_isConnected) {
          autoReconnect();
        }
      });
    } catch (e) {
      // 忽略
    }
  }

  /// R001：保存最后连接的设备信息
  Future<void> _saveDevice(BluetoothDevice device) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = device.platformName;
      final id = device.remoteId.toString();
      await prefs.setString(_prefsDeviceNameKey, name);
      await prefs.setString(_prefsDeviceIdKey, id);
      _savedDeviceName = name;
      _savedDeviceId = id;
      notifyListeners();
    } catch (e) {
      // 忽略
    }
  }

  /// R001：清除已保存的设备
  Future<void> clearSavedDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsDeviceNameKey);
      await prefs.remove(_prefsDeviceIdKey);
      _savedDeviceName = null;
      _savedDeviceId = null;
      notifyListeners();
    } catch (e) {
      // 忽略
    }
  }

  /// R001：自动回连最后连接的设备（循环搜索，直到连接成功）
  Future<void> autoReconnect() async {
    if (_savedDeviceId == null || _isConnected || _isConnecting) return;

    _isAutoReconnecting = true;
    _stopAutoReconnect = false;
    _statusMessage = '正在回连上次设备...';
    notifyListeners();

    try {
      final hasPerm = await requestPermissions();
      if (!hasPerm) {
        _isAutoReconnecting = false;
        _statusMessage = null;
        notifyListeners();
        return;
      }

      // Q021：循环搜索，使用独立的扫描结果监听，不清空全局列表
      while (!_stopAutoReconnect && !_isConnected) {
        // Q038：每次循环开始检查是否已停止
        if (_stopAutoReconnect) break;

        // 扫描前先停止之前的扫描
        try { await FlutterBluePlus.stopScan(); } catch (_) {}

        // Q038：再次检查
        if (_stopAutoReconnect) break;

        // 使用临时列表收集本次扫描结果，避免影响全局列表
        final List<ScanResult> tempResults = [];
        StreamSubscription<List<ScanResult>>? sub;
        try {
          sub = FlutterBluePlus.scanResults.listen((results) {
            tempResults.clear();
            tempResults.addAll(results);
          });

          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
          // Q038：扫描完成后立即检查是否已停止
          if (_stopAutoReconnect) break;

          await Future.delayed(const Duration(milliseconds: 200));
          if (_stopAutoReconnect) break;

          // 查找匹配的设备
          BluetoothDevice? target;
          for (final result in tempResults) {
            if (result.device.remoteId.toString() == _savedDeviceId) {
              target = result.device;
              break;
            }
          }

          if (target != null) {
            await connect(target);
            if (_isConnected) break;
          }
        } finally {
          // Q038：确保临时监听器在循环退出时被正确取消
          await sub?.cancel();
        }

        // 没找到或连接失败，等待1秒后继续搜索
        if (!_stopAutoReconnect && !_isConnected) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    } catch (e) {
      _statusMessage = null;
    } finally {
      _isAutoReconnecting = false;
      _stopAutoReconnect = false;
      notifyListeners();
    }
  }

  /// 停止自动回连循环
  void stopAutoReconnect() {
    _stopAutoReconnect = true;
    // Q038：立即停止当前正在进行的扫描，避免自动回连扫描中断手动扫描
    try { FlutterBluePlus.stopScan(); } catch (_) {}
  }

  /// 请求蓝牙权限
  Future<bool> requestPermissions() async {
    final scanPermission = await Permission.bluetoothScan.request();
    final connectPermission = await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();

    _hasPermission = scanPermission.isGranted && connectPermission.isGranted;
    notifyListeners();
    return _hasPermission;
  }

  /// 开始扫描（R002：LED过滤在devices getter中处理）
  Future<void> startScan() async {
    // Q021：手动扫描前停止自动回连，避免两个扫描冲突
    stopAutoReconnect();
    // Q038：等待500ms确保自动回连循环完全停止，避免扫描冲突
    await Future.delayed(const Duration(milliseconds: 500));

    final hasPerm = await requestPermissions();
    if (!hasPerm) {
      _statusMessage = '蓝牙权限被拒绝，请在设置中开启';
      notifyListeners();
      return;
    }

    if (_adapterState == BluetoothAdapterState.unknown) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (_adapterState != BluetoothAdapterState.on) {
      _statusMessage = '蓝牙未开启，请先打开手机蓝牙';
      notifyListeners();
      try {
        await FlutterBluePlus.turnOn();
        _statusMessage = '正在打开蓝牙...';
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        _statusMessage = '无法自动打开蓝牙，请手动开启';
        notifyListeners();
        return;
      }
    }

    // Q021：增量更新模式下不需要clear，只清除旧结果避免残留
    _scanResults.clear();
    notifyListeners();

    try {
      // 扫描前先停止之前的扫描
      try { await FlutterBluePlus.stopScan(); } catch (_) {}

      _statusMessage = '正在扫描蓝牙设备...';
      notifyListeners();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );

      _statusMessage = '扫描完成';
      notifyListeners();
    } catch (e) {
      _statusMessage = '扫描失败: $e';
      notifyListeners();
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      // 忽略
    }
  }

  /// 连接设备并发现GATT服务
  Future<void> connect(BluetoothDevice device) async {
    final connectPerm = await Permission.bluetoothConnect.request();
    if (!connectPerm.isGranted) {
      _statusMessage = '蓝牙连接权限被拒绝';
      notifyListeners();
      return;
    }

    _isConnecting = true;
    _statusMessage = '连接中...';
    notifyListeners();

    try {
      await device.connect(
        timeout: const Duration(seconds: 8),
        license: License.nonprofit,
        autoConnect: false,
      );
      _connectedDevice = device;
      _isConnected = true;
      _isUserInitiatedDisconnect = false;
      _statusMessage = '蓝牙连接成功，正在发现服务...';
      notifyListeners();

      // Q036：监听连接状态变化，断连时刷新状态并自动回连
      // skip(1)：跳过监听器添加时立即发送的当前状态，避免误触发
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.skip(1).listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          // 用户主动断开时不触发自动回连
          if (_isUserInitiatedDisconnect) return;

          // 防抖：等待2秒确认是否真的断开，避免临时信号波动
          _disconnectDebounceTimer?.cancel();
          _disconnectDebounceTimer = Timer(const Duration(seconds: 2), () {
            if (_isConnected) {
              _isConnected = false;
              _connectedDevice = null;
              _writeCharacteristic = null;
              _connectionSubscription = null;
              _statusMessage = '蓝牙已断开';
              notifyListeners();
              // 断连后自动启动回连搜索
              autoReconnect();
            }
          });
        } else if (state == BluetoothConnectionState.connected) {
          // 重新连接时取消防抖
          _disconnectDebounceTimer?.cancel();
        }
      });

      // R001：保存最后连接的设备
      await _saveDevice(device);

      // 发现GATT服务
      await _discoverServices(device);
    } catch (e) {
      _statusMessage = '连接失败: $e';
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// 发现GATT服务并找到可写特征值
  Future<void> _discoverServices(BluetoothDevice device) async {
    _isDiscoveringServices = true;
    notifyListeners();

    try {
      final services = await device.discoverServices();

      for (final service in services) {
        for (final characteristic in service.characteristics) {
          final props = characteristic.properties;
          if (props.write || props.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            _statusMessage = '已就绪，可控制灯光';
            notifyListeners();
            _isDiscoveringServices = false;
            return;
          }
        }
      }

      _statusMessage = '未找到可写特征值，服务发现完成';
    } catch (e) {
      _statusMessage = '服务发现失败: $e';
    } finally {
      _isDiscoveringServices = false;
      notifyListeners();
    }
  }

  /// 发送灯光控制指令
  Future<bool> sendCommand(List<int> command) async {
    if (_writeCharacteristic == null) {
      _statusMessage = '设备未就绪，请先连接蓝牙';
      notifyListeners();
      return false;
    }

    try {
      final bytes = Uint8List.fromList(command);
      // 使用Write Without Response，不等待设备响应，实现实时控制无延迟
      await _writeCharacteristic!.write(
        bytes,
        withoutResponse: true,
      );
      _lastCommandHex = BluetoothProtocol.toHexString(command);
      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = '指令发送失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    stopAutoReconnect(); // 停止自动回连循环
    _isUserInitiatedDisconnect = true; // 标记用户主动断开
    _disconnectDebounceTimer?.cancel(); // 取消防抖
    _connectionSubscription?.cancel(); // 取消连接状态监听
    _connectionSubscription = null;
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        // 忽略
      }
      _connectedDevice = null;
      _writeCharacteristic = null;
      _isConnected = false;
      _statusMessage = '已断开连接';
      notifyListeners();
    }
  }

  /// 清除状态消息
  void clearStatus() {
    _statusMessage = null;
    notifyListeners();
  }

  /// 获取设备显示名称（同时检查 platformName 和 advName）
  String getDeviceName(BluetoothDevice device) {
    final name = device.platformName;
    if (name.isNotEmpty) return name;
    // 从扫描结果中查找广播名称
    for (final r in _scanResults) {
      if (r.device.remoteId == device.remoteId) {
        final advName = r.advertisementData.advName;
        if (advName.isNotEmpty) return advName;
      }
    }
    return '未知设备 (${device.remoteId.toString().substring(0, 8)})';
  }

  @override
  void dispose() {
    _scanNotifyTimer?.cancel();
    stopAutoReconnect();
    super.dispose();
  }
}
