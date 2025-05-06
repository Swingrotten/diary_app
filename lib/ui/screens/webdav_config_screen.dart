import 'package:flutter/material.dart';
import '../../services/webdav_service.dart';

class WebDavConfigScreen extends StatefulWidget {
  const WebDavConfigScreen({super.key});

  @override
  State<WebDavConfigScreen> createState() => _WebDavConfigScreenState();
}

class _WebDavConfigScreenState extends State<WebDavConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = true;
  bool _syncOnStart = false;
  bool _syncOnChange = false;
  bool _obscurePassword = true;
  String? _error;
  
  final WebDavService _webDavService = WebDavService();
  
  @override
  void initState() {
    super.initState();
    _loadConfig();
  }
  
  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final config = await _webDavService.getCurrentConfig();
      
      if (config != null) {
        _serverController.text = config['serverUrl'] as String? ?? '';
        _usernameController.text = config['username'] as String? ?? '';
        _passwordController.text = config['password'] as String? ?? '';
        
        _syncOnStart = config['syncOnStart'] as bool? ?? false;
        _syncOnChange = config['syncOnChange'] as bool? ?? false;
      }
    } catch (e) {
      _error = '加载WebDAV配置失败: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // 先测试连接
      final testResult = await _webDavService.testConnection(
        _serverController.text,
        _usernameController.text,
        _passwordController.text,
      );
      
      if (!testResult) {
        setState(() {
          _isLoading = false;
          _error = 'WebDAV连接测试失败，请检查服务器地址和账号密码';
        });
        return;
      }
      
      // 保存配置
      final saveResult = await _webDavService.saveConfig(
        serverUrl: _serverController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        syncOnStart: _syncOnStart,
        syncOnChange: _syncOnChange,
      );
      
      if (saveResult) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WebDAV配置保存成功')),
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _error = 'WebDAV配置保存失败';
        });
      }
    } catch (e) {
      setState(() {
        _error = '保存WebDAV配置时出错: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV同步设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    
                    // 服务器地址
                    TextFormField(
                      controller: _serverController,
                      decoration: const InputDecoration(
                        labelText: 'WebDAV服务器地址',
                        hintText: 'https://example.com/dav/',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入WebDAV服务器地址';
                        }
                        if (!value.startsWith('http://') && !value.startsWith('https://')) {
                          return '服务器地址必须以http://或https://开头';
                        }
                        if (!value.endsWith('/')) {
                          return '服务器地址必须以/结尾';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 用户名
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入用户名';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 密码
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '密码',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 同步选项
                    const Text(
                      '同步选项',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    CheckboxListTile(
                      title: const Text('启动时同步'),
                      subtitle: const Text('应用启动时自动同步日记'),
                      value: _syncOnStart,
                      onChanged: (value) {
                        setState(() {
                          _syncOnStart = value ?? false;
                        });
                      },
                    ),
                    
                    CheckboxListTile(
                      title: const Text('更改后同步'),
                      subtitle: const Text('日记更改后自动同步到WebDAV'),
                      value: _syncOnChange,
                      onChanged: (value) {
                        setState(() {
                          _syncOnChange = value ?? false;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 测试和保存按钮
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              if (_serverController.text.isEmpty ||
                                  _usernameController.text.isEmpty ||
                                  _passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请填写完整信息后再测试连接')),
                                );
                                return;
                              }
                              
                              setState(() {
                                _isLoading = true;
                              });
                              
                              final result = await _webDavService.testConnection(
                                _serverController.text,
                                _usernameController.text,
                                _passwordController.text,
                              );
                              
                              setState(() {
                                _isLoading = false;
                              });
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result ? 'WebDAV连接测试成功' : 'WebDAV连接测试失败'),
                                    backgroundColor: result ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('测试连接'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveConfig,
                            child: const Text('保存配置'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 