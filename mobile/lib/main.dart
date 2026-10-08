import 'package:flutter/material.dart';

import 'data/auth_api.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

const _ink = Color(0xFF171A17);
const _paper = Color(0xFFF6F5F0);
const _lime = Color(0xFFC9F36A);

void main() {
  runApp(const RepForgeApp());
}

class RepForgeApp extends StatefulWidget {
  const RepForgeApp({super.key});

  @override
  State<RepForgeApp> createState() => _RepForgeAppState();
}

class _RepForgeAppState extends State<RepForgeApp> {
  final _authApi = AuthApi();
  AppUser? _user;
  String? _token;

  void _onAuthenticated(AppUser user, String token) {
    setState(() {
      _user = user;
      _token = token;
    });
  }

  Future<void> _onLogout() async {
    final token = _token;
    if (token != null) {
      await _authApi.logout(token);
    }
    if (!mounted) return;
    setState(() {
      _user = null;
      _token = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _lime,
          brightness: Brightness.light,
          surface: _paper,
          primary: _ink,
        ),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE9E9E2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE9E9E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _ink, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFB94032)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFB94032), width: 1.5),
          ),
        ),
      ),
      home: _user == null
          ? AuthScreen(api: _authApi, onAuthenticated: _onAuthenticated)
          : HomeScreen(user: _user!, onLogout: _onLogout),
    );
  }
}
