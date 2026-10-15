import 'package:flutter/material.dart';

import '../data/auth_api.dart';

const _ink = Color(0xFF171A17);
const _muted = Color(0xFF777A73);
const _lime = Color(0xFFC9F36A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.user,
    required this.onLogout,
    required this.onWorkoutLogged,
    super.key,
  });

  final AppUser user;
  final Future<void> Function() onLogout;
  final Future<WorkoutEntry> Function({
    required String exerciseName,
    required int sets,
    required int reps,
    double? weightKg,
  })
  onWorkoutLogged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _workoutFormKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController();
  bool _isLoggingOut = false;
  bool _isSavingWorkout = false;

  @override
  void dispose() {
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_workoutFormKey.currentState!.validate() || _isSavingWorkout) return;

    setState(() => _isSavingWorkout = true);
    try {
      final weight = _weightController.text.trim();
      final entry = await widget.onWorkoutLogged(
        exerciseName: _exerciseController.text.trim(),
        sets: int.parse(_setsController.text),
        reps: int.parse(_repsController.text),
        weightKg: weight.isEmpty ? null : double.parse(weight),
      );
      if (!mounted) return;
      _workoutFormKey.currentState?.reset();
      _exerciseController.clear();
      _weightController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.exerciseName} berhasil dicatat.')),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSavingWorkout = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await widget.onLogout();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  String get _firstName {
    final name = widget.user.name.trim();
    if (name.isEmpty) return 'Atlet';
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _brandHeader(),
                  const SizedBox(height: 44),
                  const Text(
                    'AKUN TERHUBUNG',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selamat datang,\n$_firstName.',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 42,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Setiap progres besar dimulai dari satu sesi.',
                    style: TextStyle(color: _muted, fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  _accountCard(),
                  const SizedBox(height: 28),
                  const Text(
                    'CATAT LATIHAN',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _workoutForm(),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: _lime, size: 25),
                        SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Siap untuk sesi berikutnya?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Akun RepForge-mu sudah siap digunakan.',
                                style: TextStyle(
                                  color: Color(0xFFB6B9B3),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoggingOut ? null : _logout,
                      icon: _isLoggingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Keluar dari akun'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: const BorderSide(color: Color(0xFFDDDED7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            color: _lime,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        const Text(
          'REP',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const Text(
          'FORGE',
          style: TextStyle(
            color: _muted,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _accountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBEBE5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3D7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _firstName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF80AE45)),
        ],
      ),
    );
  }

  Widget _workoutForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBEBE5)),
      ),
      child: Form(
        key: _workoutFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _exerciseController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama latihan',
                hintText: 'Contoh: Squat',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama latihan wajib diisi.';
                }
                if (value.trim().length > 120) {
                  return 'Maksimal 120 karakter.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Set'),
                    validator: (value) => _positiveIntegerError(value, 'Set'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Repetisi'),
                    validator: (value) =>
                        _positiveIntegerError(value, 'Repetisi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Beban (kg, opsional)',
                hintText: 'Kosongkan untuk latihan berat badan',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final weight = double.tryParse(text);
                if (weight == null || weight < 0 || weight > 999999.99) {
                  return 'Masukkan beban 0 kg atau lebih.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _isSavingWorkout ? null : _saveWorkout,
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSavingWorkout
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _lime,
                      ),
                    )
                  : const Text('Simpan latihan'),
            ),
          ],
        ),
      ),
    );
  }

  String? _positiveIntegerError(String? value, String label) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < 1 || number > 1000) {
      return '$label harus antara 1 dan 1000.';
    }
    return null;
  }
}
