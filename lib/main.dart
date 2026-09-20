import 'package:flutter/material.dart';
import 'core/api_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UetShopsApp());
}

class UetShopsApp extends StatefulWidget {
  const UetShopsApp({super.key});

  @override
  State<UetShopsApp> createState() => _UetShopsAppState();
}

class _UetShopsAppState extends State<UetShopsApp> {
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    restoreSession();
  }

  Future<void> restoreSession() async {
    final saved = await ApiService.restoreUser();
    if (saved != null) {
      try {
        user = await ApiService.me();
      } catch (_) {
        await ApiService.logout();
      }
    }
    if (mounted) setState(() => loading = false);
  }

  void signedIn(Map<String, dynamic> value) => setState(() => user = value);

  Future<void> signOut() async {
    await ApiService.logout();
    setState(() => user = null);
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF176B3A);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UET Shops',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8F6),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : user == null
              ? AuthScreen(onSignedIn: signedIn)
              : _dashboard(user!),
    );
  }

  Widget _dashboard(Map<String, dynamic> value) {
    final role = value['role'];
    if (role == 'shopAdmin' || role == 'superAdmin') {
      return AdminScreen(user: value, onLogout: signOut);
    }
    return HomeScreen(user: value, onLogout: signOut);
  }
}
