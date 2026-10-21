import 'package:flutter/material.dart';

import '../data/auth_api.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.user, required this.onAddWorkout, super.key});

  final AppUser user;
  final VoidCallback onAddWorkout;

  @override
  Widget build(BuildContext context) {
    final name = user.name.trim();
    final firstName = name.isEmpty ? 'Atlet' : name.split(RegExp(r'\s+')).first;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _BrandHeader(),
          const SizedBox(height: 44),
          const Text(
            'SELAMAT DATANG',
            style: TextStyle(
              color: Color(0xFF777A73),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Siap latihan,\n$firstName?',
            style: const TextStyle(
              color: Color(0xFF171A17),
              fontSize: 42,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Catat setiap set dan terus bangun progresmu.',
            style: TextStyle(
              color: Color(0xFF777A73),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          FilledButton.icon(
            onPressed: onAddWorkout,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Workout'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: const Color(0xFF171A17),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF171A17),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFFC9F36A), size: 25),
                SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'Satu sesi pada satu waktu. Setiap repetisi berarti.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF171A17),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            color: Color(0xFFC9F36A),
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        const Text(
          'REP',
          style: TextStyle(
            color: Color(0xFF171A17),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const Text(
          'FORGE',
          style: TextStyle(
            color: Color(0xFF777A73),
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
