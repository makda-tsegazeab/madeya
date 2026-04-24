import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../data/token_storage.dart';

class VerifyResetCodePage extends StatefulWidget {
  const VerifyResetCodePage({super.key});

  static const String routeName = '/verify-reset-code';

  @override
  State<VerifyResetCodePage> createState() => _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends State<VerifyResetCodePage> {
  static const Color _bg = Color(0xFFF1F3F7);
  static const Color _blue = Color(0xFF0C4F8D);
  static const Color _textDark = Color(0xFF2E3644);
  static const Color _inputBg = Color(0xFFD4D6DB);
  static const Color _inputIcon = Color(0xFFB2B9C5);
  static const Color _inputText = Color(0xFF6C7484);

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late final AuthService _authService;

  bool _isLoading = false;
  String? _errorText;
  String? _email;

  @override
  void initState() {
    super.initState();
    _authService = AuthServiceImpl(tokenStorage: SecureTokenStorage());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_email == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _errorText = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final isValid = await _authService.verifyResetCode(
        _email!,
        _codeController.text.trim(),
      );

      if (!isValid) {
        setState(() {
          _errorText = 'Invalid reset code. Please try again.';
        });
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code verified successfully!')),
      );
      // Since reset password is not yet implemented, navigate back to login
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on NetworkAuthException catch (e) {
      setState(() => _errorText = e.message);
    } on ServerAuthException catch (e) {
      setState(() => _errorText = e.message);
    } catch (_) {
      setState(() {
        _errorText = 'Failed to verify code. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
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
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x120A2540),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.password_rounded,
                        color: _blue,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Verify Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _blue,
                    fontSize: 24,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a reset code to\n${_email ?? ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
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
                ],
                const SizedBox(height: 12),
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
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text(
                          'RESET CODE',
                          style: TextStyle(
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
                            const Icon(
                              Icons.pin_outlined,
                              color: _inputIcon,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _codeController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _verifyCode(),
                                style: const TextStyle(
                                  color: _inputText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '123456',
                                  hintStyle: TextStyle(
                                    color: _inputText,
                                    fontSize: 14,
                                  ),
                                ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return 'Code is required';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyCode,
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
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Verify Code',
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
