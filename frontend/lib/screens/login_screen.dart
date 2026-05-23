import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

const _red = Color(0xFFFE2C55);
const _dkS1 = Color(0xFF111111);
const _dkBorder = Color(0xFF2A2A2A);
const _textMuted = Color(0xFF8A8A8A);

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
    } else if (auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red[700]),
      );
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
            colors: [Color(0xFF000000), _dkS1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(28, 0, 28, bottomInset + 32),
            child: Column(
              children: [
                const SizedBox(height: 72),
                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_red, Color(0xFFFF4D6A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _red.withValues(alpha: 0.35), blurRadius: 32, offset: const Offset(0, 12))],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 44),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: Column(
                    key: ValueKey(_isRegisterMode),
                    children: [
                      Text(_isRegisterMode ? '创建账号' : '欢迎回来',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(_isRegisterMode ? '注册后即可使用全部功能' : '登录您的账号继续观看',
                          style: const TextStyle(fontSize: 14, color: _textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Inputs
                TextField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: '用户名 / 邮箱',
                    hintStyle: TextStyle(color: _textMuted, fontSize: 15),
                    prefixIcon: Icon(Icons.person_outline, size: 20, color: _textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
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
                const SizedBox(height: 28),
                // Submit
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _red.withValues(alpha: 0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isRegisterMode ? '注 册' : '登 录'),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Expanded(child: Divider(color: _dkBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('或者', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ),
                    const Expanded(child: Divider(color: _dkBorder)),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _dkBorder),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isRegisterMode ? '已有账号？' : '还没有账号？', style: const TextStyle(color: _textMuted, fontSize: 13)),
                    GestureDetector(
                      onTap: _toggleMode,
                      child: const Text(' 立即切换', style: TextStyle(color: _red, fontSize: 13, fontWeight: FontWeight.w600)),
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
