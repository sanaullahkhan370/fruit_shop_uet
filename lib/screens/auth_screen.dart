import 'package:flutter/material.dart';
import '../core/api_service.dart';

class AuthScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onSignedIn;
  const AuthScreen({super.key, required this.onSignedIn});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();

  bool registerMode = false;
  bool otpMode = false;
  bool forgotMode = false;
  bool resetCodeSent = false;
  bool obscurePassword = true;
  bool busy = false;
  String? error;
  String? message;

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
      message = null;
    });
    try {
      final emailValue = email.text.trim();
      if (forgotMode) {
        if (!resetCodeSent) {
          await ApiService.forgotPassword(emailValue);
          if (mounted) {
            setState(() {
              resetCodeSent = true;
              message = 'A 6-digit reset code has been sent to your email';
            });
          }
        } else {
          await ApiService.resetPassword(
            emailValue,
            code.text.trim(),
            password.text,
          );
          if (mounted) {
            setState(() {
              forgotMode = false;
              resetCodeSent = false;
              code.clear();
              password.clear();
              message = 'Password reset successfully. Please log in.';
            });
          }
        }
      } else if (otpMode) {
        widget.onSignedIn(
          await ApiService.verify(emailValue, code.text.trim()),
        );
      } else if (registerMode) {
        await ApiService.register({
          'name': name.text.trim(),
          'email': emailValue,
          'phone': phone.text.trim(),
          'password': password.text,
        });
        if (mounted) setState(() => otpMode = true);
      } else {
        widget.onSignedIn(
          await ApiService.login(emailValue, password.text),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void openForgotPassword() {
    setState(() {
      forgotMode = true;
      resetCodeSent = false;
      registerMode = false;
      otpMode = false;
      password.clear();
      code.clear();
      error = null;
      message = null;
    });
  }

  void backToLogin() {
    setState(() {
      forgotMode = false;
      resetCodeSent = false;
      registerMode = false;
      otpMode = false;
      password.clear();
      code.clear();
      error = null;
      message = null;
    });
  }

  String get subtitle {
    if (forgotMode && resetCodeSent) return 'Enter the code and your new password';
    if (forgotMode) return 'Reset your password by email';
    if (otpMode) return 'Enter the code sent to your email';
    if (registerMode) return 'Create your customer account';
    return 'Sign in to continue';
  }

  String get buttonText {
    if (forgotMode && resetCodeSent) return 'Reset Password';
    if (forgotMode) return 'Send Reset Code';
    if (otpMode) return 'Verify Email';
    if (registerMode) return 'Register';
    return 'Login';
  }

  Widget passwordField({String label = 'Password'}) => TextField(
        controller: password,
        obscureText: obscurePassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            tooltip: obscurePassword ? 'Show password' : 'Hide password',
            onPressed: () =>
                setState(() => obscurePassword = !obscurePassword),
            icon: Icon(
              obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
      );

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showResetFields = forgotMode && resetCodeSent;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Image.asset(
                      'assets/images/uet_shops_logo.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'UET Shops',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(subtitle),
                    const SizedBox(height: 24),
                    if (registerMode && !otpMode) ...[
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: email,
                      enabled: !otpMode && !showResetFields,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (registerMode && !otpMode) ...[
                      TextField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (otpMode)
                      TextField(
                        controller: code,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit verification code',
                          prefixIcon: Icon(Icons.verified),
                        ),
                      )
                    else if (showResetFields) ...[
                      TextField(
                        controller: code,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit reset code',
                          prefixIcon: Icon(Icons.pin),
                        ),
                      ),
                      const SizedBox(height: 12),
                      passwordField(label: 'New password'),
                    ] else if (!forgotMode)
                      passwordField(),
                    if (!registerMode && !otpMode && !forgotMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: busy ? null : openForgotPassword,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          message!,
                          style: const TextStyle(color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy ? null : submit,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(buttonText),
                        ),
                      ),
                    ),
                    if (forgotMode)
                      TextButton(
                        onPressed: busy ? null : backToLogin,
                        child: const Text('Back to Login'),
                      )
                    else if (!otpMode)
                      TextButton(
                        onPressed: () => setState(() {
                          registerMode = !registerMode;
                          error = null;
                          message = null;
                        }),
                        child: Text(
                          registerMode
                              ? 'Already registered? Login'
                              : 'New customer? Create account',
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
