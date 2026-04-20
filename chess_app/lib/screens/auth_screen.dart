import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onSkip;

  const AuthScreen({
    super.key,
    required this.onSuccess,
    required this.onSkip,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool   _isLogin   = true;
  bool   _loading   = false;
  String _error     = "";
  bool   _showPass  = false;

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = "Fill in all fields");
      return;
    }

    setState(() { _loading = true; _error = ""; });

    final err = _isLogin
        ? await AuthService.login(username, password)
        : await AuthService.register(username, password);

    setState(() => _loading = false);

    if (err == null) {
      widget.onSuccess();
    } else {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("♟", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  _isLogin ? "Welcome Back" : "Create Account",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLogin
                      ? "Sign in to track your score"
                      : "Username: letters only, max 7 chars",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Username
                _buildField(
                  controller: _userCtrl,
                  hint: "Username",
                  icon: Icons.person_outline,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                ),
                const SizedBox(height: 12),

                // Password
                _buildField(
                  controller: _passCtrl,
                  hint: "Password",
                  icon: Icons.lock_outline,
                  obscure: !_showPass,
                  suffix: IconButton(
                    icon: Icon(
                      _showPass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _showPass = !_showPass),
                  ),
                ),

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Submit button
                GestureDetector(
                  onTap: _loading ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _loading
                        ? const Center(
                            child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Text(
                            _isLogin ? "Sign In" : "Register",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Toggle login/register
                GestureDetector(
                  onTap: () => setState(() {
                    _isLogin = !_isLogin;
                    _error   = "";
                  }),
                  child: Text(
                    _isLogin
                        ? "New here? Create account"
                        : "Already have an account? Sign in",
                    style: const TextStyle(
                      color: Color(0xFF4A90D9),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Skip
                GestureDetector(
                  onTap: widget.onSkip,
                  child: Text(
                    "Skip — play anonymously",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: TextField(
        controller:       controller,
        obscureText:      obscure,
        inputFormatters:  inputFormatters,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText:        hint,
          hintStyle:       TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon:      Icon(icon, color: Colors.grey[600], size: 18),
          suffixIcon:      suffix,
          border:          InputBorder.none,
          contentPadding:  const EdgeInsets.symmetric(
              vertical: 14, horizontal: 12),
        ),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}