import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/auth_api.dart';
import '../models/workout_session.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'workout_history_detail_screen.dart';
import 'workout_session_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.user,
    required this.onLogout,
    required this.onPublishWorkout,
    required this.onLoadWorkoutHistory,
    required this.onLoadPreviousPerformance,
    super.key,
  });

  final AppUser user;
  final Future<void> Function() onLogout;
  final Future<WorkoutSessionRecord> Function({
    required String title,
    required List<WorkoutSetPayload> entries,
    XFile? photo,
  })
  onPublishWorkout;
  final Future<List<WorkoutSessionRecord>> Function() onLoadWorkoutHistory;
  final Future<PreviousPerformance?> Function({required String exerciseName})
  onLoadPreviousPerformance;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final WorkoutSession _session = WorkoutSession();
  final _historyKey = GlobalKey<_HistoryScreenState>();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<void> _startWorkout() async {
    if (_session.hasUnsavedSets) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mulai sesi baru?'),
          content: const Text(
            'Latihan pada sesi aktif yang belum disimpan akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Mulai baru'),
            ),
          ],
        ),
      );
      if (shouldDiscard != true || !mounted) return;
    }

    _session.reset();
    setState(() => _selectedIndex = 1);
  }

  void _onWorkoutPublished() {
    setState(() => _selectedIndex = 2);
    _historyKey.currentState?.load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(user: widget.user, onAddWorkout: _startWorkout),
      WorkoutSessionScreen(
        session: _session,
        onPublish: widget.onPublishWorkout,
        onWorkoutPublished: _onWorkoutPublished,
        onLoadPreviousPerformance: widget.onLoadPreviousPerformance,
      ),
      _HistoryScreen(
        key: _historyKey,
        loadHistory: widget.onLoadWorkoutHistory,
      ),
      ProfileScreen(user: widget.user, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HistoryScreen extends StatefulWidget {
  const _HistoryScreen({required this.loadHistory, super.key});

  final Future<List<WorkoutSessionRecord>> Function() loadHistory;

  @override
  State<_HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<_HistoryScreen> {
  List<WorkoutSessionRecord>? _sessions;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final sessions = await widget.loadHistory();
      if (mounted) setState(() => _sessions = sessions);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessions ?? const <WorkoutSessionRecord>[];
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Workout History',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171A17),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading && _sessions == null
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _HistoryError(message: _error!, onRetry: load)
                : sessions.isEmpty
                ? RefreshIndicator(
                    onRefresh: load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Icon(
                          Icons.history_rounded,
                          size: 44,
                          color: Color(0xFF777A73),
                        ),
                        SizedBox(height: 14),
                        Center(
                          child: Text(
                            'Belum ada workout di riwayat.',
                            style: TextStyle(color: Color(0xFF777A73)),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: sessions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _WorkoutHistoryCard(
                        session: sessions[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => WorkoutHistoryDetailScreen(
                              session: sessions[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutHistoryCard extends StatelessWidget {
  const _WorkoutHistoryCard({required this.session, required this.onTap});

  final WorkoutSessionRecord session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(session.publishedAt.toLocal()),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
