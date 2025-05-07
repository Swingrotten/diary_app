import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../services/webdav_service.dart';
import 'webdav_config_screen.dart';
import 'tag_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final WebDavService _webDavService = WebDavService();
  
  @override
  void initState() {
    super.initState();
    _webDavService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 主题设置卡片
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '外观',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 主题模式选择
                  ListTile(
                    title: const Text('主题模式'),
                    subtitle: Text(_getThemeModeText(themeService.currentThemeMode)),
                    leading: const Icon(Icons.brightness_6),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showThemeModeDialog(themeService),
                  ),
                  
                  // 主题预览
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '当前主题',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '点击图标快速切换主题',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _getThemeIcon(themeService.currentThemeMode),
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          onPressed: () {
                            themeService.toggleTheme();
                            // 显示提示
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('已切换到${_getThemeModeText(themeService.currentThemeMode)}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 数据同步卡片
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '数据同步',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // WebDAV设置
                  ListTile(
                    title: const Text('WebDAV同步设置'),
                    subtitle: Text(_webDavService.isEnabled 
                        ? '已启用 - ${_webDavService.serverUrl}'
                        : '未配置'
                    ),
                    leading: const Icon(Icons.cloud_sync),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => const WebDavConfigScreen(),
                        ),
                      );
                    },
                  ),
                  
                  // 立即同步按钮
                  if (_webDavService.isEnabled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.sync),
                        label: const Text('立即同步'),
                        onPressed: () {
                          // 执行同步操作
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('同步已开始，请稍候...'),
                            ),
                          );
                          // TODO: 实现同步逻辑
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 数据管理卡片
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '数据管理',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 标签管理
                  ListTile(
                    title: const Text('标签管理'),
                    subtitle: const Text('查看和编辑所有标签'),
                    leading: const Icon(Icons.tag),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => const TagManagerScreen(),
                        ),
                      );
                    },
                  ),
                  
                  // 导出数据
                  ListTile(
                    title: const Text('导出数据'),
                    subtitle: const Text('将日记导出为TXT或PDF格式'),
                    leading: const Icon(Icons.upload_file),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: 导出功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('导出功能即将上线'),
                        ),
                      );
                    },
                  ),
                  
                  // 备份数据
                  ListTile(
                    title: const Text('本地备份'),
                    subtitle: const Text('在设备上创建备份'),
                    leading: const Icon(Icons.backup),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: 备份功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('备份功能即将上线'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // 关于应用
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '关于',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    title: const Text('版本信息'),
                    subtitle: const Text('v0.1.0'),
                    leading: const Icon(Icons.info_outline),
                    onTap: () {
                      // 显示版本信息对话框
                      showAboutDialog(
                        context: context,
                        applicationName: '每日心情',
                        applicationVersion: 'v0.1.0',
                        applicationIcon: const Icon(Icons.book, size: 48),
                        children: [
                          const Text('一款简单易用的跨平台日记应用，帮助您记录每一天的心情与点滴。'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showThemeModeDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              icon: Icons.brightness_auto,
              title: '跟随系统',
              subtitle: '自动适应系统主题设置',
              isSelected: themeService.currentThemeMode == 'system',
              onTap: () {
                themeService.setSystemTheme();
                Navigator.pop(context);
              },
            ),
            _buildThemeOption(
              context,
              icon: Icons.light_mode,
              title: '浅色模式',
              subtitle: '始终使用浅色主题',
              isSelected: themeService.currentThemeMode == 'light',
              onTap: () {
                themeService.setLightTheme();
                Navigator.pop(context);
              },
            ),
            _buildThemeOption(
              context,
              icon: Icons.dark_mode,
              title: '深色模式',
              subtitle: '始终使用深色主题',
              isSelected: themeService.currentThemeMode == 'dark',
              onTap: () {
                themeService.setDarkTheme();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected 
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
  
  String _getThemeModeText(String mode) {
    switch (mode) {
      case 'light':
        return '浅色模式';
      case 'dark':
        return '深色模式';
      case 'system':
      default:
        return '跟随系统';
    }
  }
  
  IconData _getThemeIcon(String mode) {
    switch (mode) {
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      case 'system':
      default:
        return Icons.brightness_auto;
    }
  }
} 