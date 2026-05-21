import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

const _black = Color(0xFF000000);
const _surface1 = Color(0xFF0C0C0C);
const _surface3 = Color(0xFF262626);
const _violet500 = Color(0xFF8B5CF6);
const _violet300 = Color(0xFFC4B5FD);
const _textMuted = Color(0xFF71717A);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _obscure = true;

  late final AnimationController _modeCtrl;

  @override
  void initState() {
    super.initState();
    _modeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _modeCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _modeCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    _modeCtrl.forward(from: 0).then((_) {
      setState(() => _isRegisterMode = !_isRegisterMode);
      _modeCtrl.forward();
    });
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    final auth = context.read<AuthProvider>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入用户名和密码'), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    if (_isRegisterMode) {
      await auth.register(username, password, null);
    } else {
      await auth.login(username, password);
    }

    if (auth.isLoggedIn && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_black, _surface1, _surface1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(28, 0, 28, bottomInset + 32),
            child: Column(
              children: [
                const SizedBox(height: 72),
                // Logo with glow
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_violet500, Color(0xFFA855F7), Color(0xFFD946EF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _violet500.withValues(alpha: 0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 44),
                // Title
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: Column(
                    key: ValueKey(_isRegisterMode),
                    children: [
                      Text(
                        _isRegisterMode ? '创建账号' : '欢迎回来',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isRegisterMode ? '注册后即可使用全部功能' : '登录您的账号继续观看',
                        style: const TextStyle(fontSize: 14, color: _textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Inputs
                Semantics(
                  label: '用户名',
                  hint: '请输入用户名或邮箱',
                  child: TextField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: '用户名 / 邮箱',
                      hintStyle: TextStyle(color: _textMuted, fontSize: 15),
                      prefixIcon: Icon(Icons.person_outline, size: 20, color: _textMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: '密码',
                  hint: '请输入密码',
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '密码',
                      hintStyle: const TextStyle(color: _textMuted, fontSize: 15),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20, color: _textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: _textMuted),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Submit button
                Semantics(
                  button: true,
                  label: _isRegisterMode ? '注册' : '登录',
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _black,
                        disabledBackgroundColor: Colors.white38,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _black))
                          : Text(_isRegisterMode ? '注 册' : '登 录'),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: _surface3)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('或者', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ),
                    const Expanded(child: Divider(color: _surface3)),
                  ],
                ),
                const SizedBox(height: 32),
                // Phone register
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _surface3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android_rounded, size: 18, color: Colors.grey[400]),
                        const SizedBox(width: 10),
                        const Text('手机号注册'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 52),
                // Toggle mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRegisterMode ? '已有账号？' : '还没有账号？',
                      style: const TextStyle(color: _textMuted, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: _toggleMode,
                      child: const Text(
                        ' 立即切换',
                        style: TextStyle(color: _violet300, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
