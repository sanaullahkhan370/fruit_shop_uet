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
    const darkBlue = Color(0xFF0A2E5D);
    const backgroundBlue = Color(0xFFF2F6FC);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UET Shops',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkBlue,
          primary: darkBlue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundBlue,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          prefixIconColor: darkBlue,
          suffixIconColor: darkBlue,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: darkBlue, width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: darkBlue,
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: darkBlue),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFF8FAFD),
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
