import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../data/token_storage.dart';
import '../pages/owner_dashboard_page.dart';
import '../pages/station_worker_dashboard_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _bg = Color(0xFFF1F3F7);
  static const Color _blue = Color(0xFF0C4F8D);
  static const Color _textDark = Color(0xFF2E3644);
  static const Color _inputBg = Color(0xFFD4D6DB);
  static const Color _inputIcon = Color(0xFFB2B9C5);
  static const Color _inputText = Color(0xFF6C7484);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _authService = AuthServiceImpl(tokenStorage: SecureTokenStorage());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorText = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final session = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      switch (session.user.role) {
        case 'VEHICLE_OWNER':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OwnerDashboardPage(profile: session.user),
            ),
          );
          break;
        case 'STATION_WORKER':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StationWorkerDashboardPage(profile: session.user),
            ),
          );
          break;
        default:
          setState(() {
            _errorText = 'This account type cannot access the mobile app.';
          });
          await _authService.logout();
      }
    } on InvalidCredentialsException {
      setState(() => _errorText = 'Invalid email or password.');
    } on NetworkAuthException catch (e) {
      setState(() => _errorText = e.message);
    } on ServerAuthException catch (e) {
      setState(() => _errorText = e.message);
    } on AuthException catch (e) {
      setState(() => _errorText = e.message);
    } catch (_) {
      setState(() {
        _errorText = 'Login failed. Please try again.';
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 2),
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
                          child: Center(
                            child: Image.asset(
                              'assets/images/madeya_logo.png',
                              width: 52,
                              height: 52,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.local_gas_station_rounded,
                                color: _blue,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Mekelle Fuel Tracker',
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
                      const Text(
                        'Sign in to access your dashboard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                          border: Border.all(
                            color: const Color(0xFFE9ECF1),
                            width: 1.1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(
                                'EMAIL',
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _inputBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    color: _inputIcon,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailController,
                                      enabled: !_isLoading,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        color: _inputText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'email@example.com',
                                        hintStyle: TextStyle(
                                          color: _inputText,
                                          fontSize: 14,
                                        ),
                                      ),
                                      validator: (value) {
                                        final v = value?.trim() ?? '';
                                        if (v.isEmpty)
                                          return 'Email is required';
                                        final emailRegex = RegExp(
                                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                        );
                                        if (!emailRegex.hasMatch(v)) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.only(left: 6, right: 4),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'PASSWORD',
                                      style: TextStyle(
                                        color: Color(0xFF2E3644),
                                        fontSize: 13,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(ForgotPasswordPage.routeName);
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: _blue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _inputBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lock_rounded,
                                    color: _inputIcon,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _passwordController,
                                      enabled: !_isLoading,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _login(),
                                      style: const TextStyle(
                                        color: _inputText,
                                        fontSize: 14,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '••••••••',
                                        hintStyle: TextStyle(
                                          color: _inputText,
                                          fontSize: 18,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      validator: (value) {
                                        if ((value ?? '').isEmpty) {
                                          return 'Password is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                    icon: const Icon(
                                      Icons.visibility_rounded,
                                      color: _inputIcon,
                                      size: 22,
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
                                onPressed: _isLoading ? null : _login,
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
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Login',
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
                      const SizedBox(height: 14),
                      const Text(
                        '© 2026 Mekele Fuel Tracker.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6D7482),
                          fontSize: 10,
                          height: 1.35,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
