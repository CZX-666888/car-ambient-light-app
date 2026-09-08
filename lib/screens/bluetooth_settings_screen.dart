import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_manager.dart';
import '../l10n/app_localizations.dart';

/// 蓝牙设置页
class BluetoothSettingsScreen extends StatefulWidget {
  const BluetoothSettingsScreen({super.key});

  @override
  State<BluetoothSettingsScreen> createState() => _BluetoothSettingsScreenState();
}

class _BluetoothSettingsScreenState extends State<BluetoothSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothManager>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          l10n.bluetoothSettings,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Consumer<BluetoothManager>(
          builder: (context, manager, child) {
            return Column(
              children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: GestureDetector(
                  onTap: manager.isScanning ? null : () => manager.startScan(),
                  child: Column(
                    children: [
                      manager.isScanning
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: Color(0xFF00E5FF),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.refresh, color: Color(0xFF00E5FF), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        manager.isScanning ? l10n.searching : l10n.tapToRescan,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Color(0xFF333333)),
              Expanded(
                child: manager.devices.isEmpty
                    ? _buildEmptyState(manager, l10n)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: manager.devices.length,
                        itemBuilder: (context, index) {
                          final device = manager.devices[index];
                          final isConnected = manager.connectedDevice?.remoteId == device.remoteId;
                          return _buildDeviceItem(device, isConnected, manager, l10n);
                        },
                      ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BluetoothManager manager, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_searching,
            color: Colors.grey.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            manager.isScanning ? l10n.searchingDevices : l10n.noDevicesFound,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.checkDevicePower,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(device, bool isConnected, BluetoothManager manager, AppLocalizations l10n) {
    final deviceName = manager.getDeviceName(device);
    final scanResult = manager.scanResults.firstWhere(
      (r) => r.device.remoteId == device.remoteId,
      orElse: () => manager.scanResults.first,
    );
    final rssi = scanResult.rssi;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
        color: isConnected ? const Color(0xFF00E5FF) : Colors.grey,
        size: 28,
      ),
      title: Text(
        deviceName,
        style: TextStyle(
          color: isConnected ? Colors.white : Colors.grey,
          fontSize: 16,
          fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${device.remoteId}  |  ${l10n.signal}: ${rssi}dBm',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: isConnected ? const Color(0xFF00E5FF) : Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
      onTap: () {
        if (isConnected) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: Text(l10n.disconnect, style: const TextStyle(color: Colors.white)),
              content: Text(l10n.confirmDisconnect, style: const TextStyle(color: Colors.grey)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    manager.disconnect();
                    Navigator.pop(context);
                  },
                  child: Text(l10n.confirm, style: const TextStyle(color: Color(0xFF00E5FF))),
                ),
              ],
            ),
          );
        } else {
          manager.connect(device);
        }
      },
    );
  }
}
