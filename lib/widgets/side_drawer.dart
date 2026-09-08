import 'package:flutter/material.dart';

/// 侧边菜单
class SideDrawer extends StatelessWidget {
  final VoidCallback onBluetoothSettings;
  final VoidCallback onHelpCenter;
  final VoidCallback onAbout;

  const SideDrawer({
    super.key,
    required this.onBluetoothSettings,
    required this.onHelpCenter,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // 用户信息区
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
            accountName: const Text(
              '欢乐马',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            accountEmail: null,
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Color(0xFF00E5FF),
              child: Icon(Icons.person, color: Colors.white, size: 32),
            ),
          ),
          const Divider(color: Color(0xFF333333)),
          // 菜单项
          _buildMenuItem(
            icon: Icons.bluetooth,
            title: '蓝牙设置',
            onTap: onBluetoothSettings,
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: '帮助中心',
            onTap: onHelpCenter,
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: '关于我们',
            onTap: onAbout,
          ),
          const Spacer(),
          // 版本号
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '版本 V1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00E5FF), size: 24),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
