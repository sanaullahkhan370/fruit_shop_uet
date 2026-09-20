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
  bool busy = false;
  String? error;

  Future<void> submit() async {
    setState(() { busy = true; error = null; });
    try {
      if (otpMode) {
        widget.onSignedIn(await ApiService.verify(email.text.trim(), code.text.trim()));
      } else if (registerMode) {
        await ApiService.register({
          'name': name.text.trim(), 'email': email.text.trim(),
          'phone': phone.text.trim(), 'password': password.text,
        });
        setState(() => otpMode = true);
      } else {
        widget.onSignedIn(await ApiService.login(email.text.trim(), password.text));
      }
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const CircleAvatar(radius: 38, child: Icon(Icons.storefront, size: 42)),
                    const SizedBox(height: 16),
                    Text('UET Shops', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(otpMode ? 'Enter the code sent to your email' : registerMode ? 'Create your customer account' : 'Sign in to continue'),
                    const SizedBox(height: 24),
                    if (registerMode && !otpMode) ...[
                      TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person))),
                      const SizedBox(height: 12),
                    ],
                    TextField(controller: email, enabled: !otpMode, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
                    const SizedBox(height: 12),
                    if (registerMode && !otpMode) ...[
                      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
                      const SizedBox(height: 12),
                    ],
                    if (otpMode)
                      TextField(controller: code, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: '6-digit verification code', prefixIcon: Icon(Icons.verified)))
                    else
                      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
                    if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
                    const SizedBox(height: 18),
                    SizedBox(width: double.infinity, child: FilledButton(
                      onPressed: busy ? null : submit,
                      child: Padding(padding: const EdgeInsets.all(14), child: busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(otpMode ? 'Verify Email' : registerMode ? 'Register' : 'Login')),
                    )),
                    if (!otpMode) TextButton(
                      onPressed: () => setState(() { registerMode = !registerMode; error = null; }),
                      child: Text(registerMode ? 'Already registered? Login' : 'New customer? Create account'),
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
