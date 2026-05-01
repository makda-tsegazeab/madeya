import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../data/token_storage.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  static const String routeName = '/change-password';

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  static const Color _bg = Color(0xFFF1F3F7);
  static const Color _blue = Color(0xFF0C4F8D);
  // static const Color _textDark = Color(0xFF2E3644); // Unused
  static const Color _inputBg = Color(0xFFD4D6DB);
  static const Color _inputIcon = Color(0xFFB2B9C5);
  static const Color _inputText = Color(0xFF6C7484);

  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final AuthService _authService;

  bool _isLoading = false;
  String? _errorText;
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthServiceImpl(tokenStorage: SecureTokenStorage());
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorText = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!')),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => _errorText = e.message);
    } catch (_) {
      setState(() {
        _errorText = 'Failed to change password. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleObscure,
    required String? Function(String?) validator,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2E3644),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: _inputIcon, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: !_isLoading,
                  obscureText: obscureText,
                  textInputAction: textInputAction,
                  onFieldSubmitted: onFieldSubmitted,
                  style: const TextStyle(
                    color: _inputText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '••••••••',
                    hintStyle: const TextStyle(color: _inputText, fontSize: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: _inputIcon,
                        size: 18,
                      ),
                      onPressed: toggleObscure,
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  validator: validator,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Change Password', style: TextStyle(color: _blue, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _blue),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE9ECF1), width: 1.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordField(
                        label: 'CURRENT PASSWORD',
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        toggleObscure: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                        validator: (value) => (value == null || value.isEmpty) ? 'Current password is required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        label: 'NEW PASSWORD',
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        toggleObscure: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.isEmpty) return 'New password is required';
                          if (v.length < 6) return 'At least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        label: 'CONFIRM NEW PASSWORD',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _changePassword(),
                        validator: (value) {
                          if (value != _newPasswordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(0x2A0A2540),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Update Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
