import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'data/auth_api.dart';
import 'data/auth_token_store.dart';
import 'screens/auth_screen.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RepForgeApp());
}

class RepForgeApp extends StatefulWidget {
  const RepForgeApp({this.authApi, this.tokenStore, super.key});

  final AuthApi? authApi;
  final AuthTokenStore? tokenStore;

  @override
  State<RepForgeApp> createState() => _RepForgeAppState();
}

class _RepForgeAppState extends State<RepForgeApp> {
  late final AuthApi _authApi = widget.authApi ?? AuthApi();
  late final AuthTokenStore _tokenStore =
      widget.tokenStore ?? SecureAuthTokenStore();
  final _navigatorKey = GlobalKey<NavigatorState>();
  AppUser? _user;
  String? _token;
  bool _isRestoringSession = true;
  String? _restoreError;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _isRestoringSession = true;
      _restoreError = null;
    });
    try {
      final token = await _tokenStore.readToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _isRestoringSession = false);
        return;
      }

      final user = await _authApi.getCurrentUser(token: token);
      if (!mounted) return;
      setState(() {
        _token = token;
        _user = user;
        _isRestoringSession = false;
      });
    } on AuthApiException catch (error) {
      if (error.isUnauthenticated) {
        try {
          await _tokenStore.deleteToken();
        } on PlatformException {
          if (mounted) {
            setState(() {
              _restoreError =
                  'Token tidak valid dan sesi tersimpan tidak dapat dihapus.';
              _isRestoringSession = false;
            });
          }
          return;
        }
        if (mounted) {
          setState(() {
            _token = null;
            _user = null;
            _isRestoringSession = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _restoreError = error.message;
          _isRestoringSession = false;
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _restoreError = 'Sesi tersimpan tidak dapat dibaca dengan aman.';
          _isRestoringSession = false;
        });
      }
    }
  }

  Future<void> _onAuthenticated(AppUser user, String token) async {
    try {
      await _tokenStore.writeToken(token);
    } on PlatformException {
      throw const AuthApiException(
        'Sesi tidak dapat disimpan dengan aman. Coba lagi.',
      );
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      _token = token;
    });
  }

  Future<void> _onLogout() async {
    final token = _token;
    try {
      if (token != null) await _authApi.logout(token);
    } on AuthApiException catch (error) {
      if (!error.isUnauthenticated) rethrow;
    } finally {
      try {
        await _tokenStore.deleteToken();
      } on PlatformException {
        if (mounted) _clearSessionState();
        throw const AuthApiException(
          'Sesi berakhir, tetapi token tersimpan tidak dapat dihapus.',
        );
      }
      if (mounted) _clearSessionState();
    }
  }

  Future<void> _expireSession() async {
    try {
      await _tokenStore.deleteToken();
    } on PlatformException {
      throw const AuthApiException(
        'Sesi berakhir, tetapi token tersimpan tidak dapat dihapus.',
      );
    } finally {
      if (mounted) _clearSessionState();
    }
  }

  void _clearSessionState() {
    setState(() {
      _user = null;
      _token = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }

  Future<WorkoutSessionRecord> _onWorkoutPublished({
    required String title,
    required List<WorkoutSetPayload> entries,
    XFile? photo,
  }) async {
    final token = _token;
    if (token == null) {
      throw const AuthApiException(
        'Sesi berakhir. Masuk kembali untuk memublikasikan.',
      );
    }
    try {
      return await _authApi.publishWorkoutSession(
        token: token,
        title: title,
        entries: entries,
        photo: photo,
      );
    } on AuthApiException catch (error) {
      if (error.isUnauthenticated) await _expireSession();
      rethrow;
    }
  }

  Future<List<WorkoutSessionRecord>> _onLoadWorkoutHistory() async {
    final token = _token;
    if (token == null) {
      throw const AuthApiException(
        'Sesi berakhir. Masuk kembali untuk melihat riwayat.',
      );
    }
    try {
      return await _authApi.getWorkoutSessions(token: token);
    } on AuthApiException catch (error) {
      if (error.isUnauthenticated) await _expireSession();
      rethrow;
    }
  }

  Future<PreviousPerformance?> _onLoadPreviousPerformance({
    required String exerciseName,
  }) async {
    final token = _token;
    if (token == null) {
      throw const AuthApiException(
        'Sesi berakhir. Masuk kembali untuk melihat performa sebelumnya.',
      );
    }
    try {
      return await _authApi.getPreviousPerformance(
        token: token,
        exerciseName: exerciseName,
      );
    } on AuthApiException catch (error) {
      if (error.isUnauthenticated) await _expireSession();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'RepForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _isRestoringSession
          ? const _SessionLoadingScreen()
          : _restoreError != null
          ? _SessionRestoreError(
              message: _restoreError!,
              onRetry: _restoreSession,
            )
          : _user == null
          ? AuthScreen(api: _authApi, onAuthenticated: _onAuthenticated)
          : AppShell(
              user: _user!,
              onLogout: _onLogout,
              onPublishWorkout: _onWorkoutPublished,
              onLoadWorkoutHistory: _onLoadWorkoutHistory,
              onLoadPreviousPerformance: _onLoadPreviousPerformance,
            ),
    );
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _SessionRestoreError extends StatelessWidget {
  const _SessionRestoreError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
            ],
          ),
        ),
      ),
    );
  }
}
