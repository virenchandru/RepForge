import 'package:flutter/material.dart';

import '../data/auth_api.dart';
import '../models/profile_photo.dart';
import '../widgets/profile_photo_avatar.dart';
import 'workout_history_detail_screen.dart';

const _homeAccent = Color(0xFFE85D2A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.user,
    required this.onAddWorkout,
    required this.onOpenProfile,
    required this.onSeeAll,
    required this.loadWorkoutHistory,
    this.profilePhoto,
    super.key,
  });

  final AppUser user;
  final VoidCallback onAddWorkout;
  final VoidCallback onOpenProfile;
  final VoidCallback onSeeAll;
  final Future<List<WorkoutSessionRecord>> Function() loadWorkoutHistory;
  final ProfilePhoto? profilePhoto;

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<WorkoutSessionRecord>? _sessions;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final sessions = [...await widget.loadWorkoutHistory()];
      sessions.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      if (mounted) setState(() => _sessions = sessions);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sessions = _sessions ?? const <WorkoutSessionRecord>[];
    final firstName = _firstName(widget.user.name);
    final greeting = _greeting(DateTime.now());
    final currentWeekStart = _weekStart(DateTime.now());
    final currentWeek = sessions.where((session) {
      final date = session.publishedAt.toLocal();
      return !date.isBefore(currentWeekStart) &&
          date.isBefore(currentWeekStart.add(const Duration(days: 7)));
    }).toList();
    final previousWeek = sessions.where((session) {
      final date = session.publishedAt.toLocal();
      return !date.isBefore(
            currentWeekStart.subtract(const Duration(days: 7)),
          ) &&
          date.isBefore(currentWeekStart);
    }).toList();

    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _PersonalHeader(
                greeting: greeting,
                firstName: firstName,
                profilePhoto: widget.profilePhoto,
                onTapProfile: widget.onOpenProfile,
              ),
              const SizedBox(height: 24),
              _StartWorkoutCard(onPressed: widget.onAddWorkout),
              const SizedBox(height: 26),
              _SectionHeader(
                title: 'This week',
                subtitle: _weekLabel(currentWeekStart),
              ),
              const SizedBox(height: 12),
              if (_isLoading && _sessions == null)
                const _DashboardLoading()
              else if (_error != null && _sessions == null)
                _DashboardError(message: _error!, onRetry: refresh)
              else ...[
                _WeeklyStats(
                  sessions: currentWeek,
                  previousWeek: previousWeek,
                  showComparison: sessions.isNotEmpty,
                ),
                const SizedBox(height: 12),
                _WeeklyActivityChart(
                  sessions: currentWeek,
                  weekStart: currentWeekStart,
                ),
                const SizedBox(height: 26),
                if (sessions.isEmpty)
                  _WelcomeEmptyState(onStartWorkout: widget.onAddWorkout)
                else ...[
                  _SectionHeader(
                    title: 'Recent workouts',
                    actionLabel: 'See all',
                    onAction: widget.onSeeAll,
                  ),
                  const SizedBox(height: 10),
                  ...sessions
                      .take(3)
                      .map(
                        (session) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecentWorkoutTile(
                            session: session,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WorkoutHistoryDetailScreen(
                                  session: session,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Personal records'),
                  const SizedBox(height: 10),
                  _PersonalRecords(sessions: sessions),
                ],
              ],
              if (_isLoading && _sessions != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: _homeAccent,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
              if (_error != null && sessions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Showing saved workout data. Pull down to try again.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Athlete' : trimmed.split(RegExp(r'\s+')).first;
  }

  String _greeting(DateTime time) {
    if (time.hour < 12) return 'Good morning';
    if (time.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  String _weekLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    final startText = MaterialLocalizations.of(
      context,
    ).formatShortMonthDay(start);
    final endText = MaterialLocalizations.of(context).formatShortMonthDay(end);
    return '$startText – $endText';
  }
}

class _PersonalHeader extends StatelessWidget {
  const _PersonalHeader({
    required this.greeting,
    required this.firstName,
    required this.profilePhoto,
    required this.onTapProfile,
  });

  final String greeting;
  final String firstName;
  final ProfilePhoto? profilePhoto;
  final VoidCallback onTapProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$firstName.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 29,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Build strength, one session at a time.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Semantics(
          button: true,
          label: 'Open profile',
          child: InkWell(
            onTap: onTapProfile,
            customBorder: const CircleBorder(),
            child: ProfilePhotoAvatar(
              photo: profilePhoto,
              radius: 27,
              accentColor: _homeAccent,
            ),
          ),
        ),
      ],
    );
  }
}

class _StartWorkoutCard extends StatelessWidget {
  const _StartWorkoutCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _homeAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to get stronger?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your next session starts here.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Start workout'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.surface,
                    foregroundColor: _homeAccent,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.fitness_center_rounded,
            size: 52,
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: _homeAccent,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _WeeklyStats extends StatelessWidget {
  const _WeeklyStats({
    required this.sessions,
    required this.previousWeek,
    required this.showComparison,
  });

  final List<WorkoutSessionRecord> sessions;
  final List<WorkoutSessionRecord> previousWeek;
  final bool showComparison;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activeDays = sessions
        .map((session) {
          final date = session.publishedAt.toLocal();
          return DateTime(date.year, date.month, date.day);
        })
        .toSet()
        .length;
    final volume = _totalVolume(sessions);
    final volumeLabel = volume == null ? '—' : '${_formatNumber(volume)} kg';
    final delta = sessions.length - previousWeek.length;
    final comparison = delta == 0
        ? 'Same as last week'
        : delta > 0
        ? '$delta more than last week'
        : '${delta.abs()} fewer than last week';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  icon: Icons.fitness_center_rounded,
                  value: '${sessions.length}',
                  label: 'Workouts',
                ),
              ),
              _StatDivider(),
              Expanded(
                child: _StatCell(
                  icon: Icons.monitor_weight_outlined,
                  value: volumeLabel,
                  label: 'Training volume',
                  compact: true,
                ),
              ),
              _StatDivider(),
              Expanded(
                child: _StatCell(
                  icon: Icons.local_fire_department_outlined,
                  value: '$activeDays',
                  label: 'Active days',
                ),
              ),
            ],
          ),
          if (showComparison) ...[
            const SizedBox(height: 13),
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 11),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  delta > 0
                      ? Icons.trending_up_rounded
                      : delta < 0
                      ? Icons.trending_down_rounded
                      : Icons.trending_flat_rounded,
                  size: 17,
                  color: delta < 0 ? colors.onSurfaceVariant : _homeAccent,
                ),
                const SizedBox(width: 5),
                Text(
                  comparison,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 18, color: _homeAccent),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: compact ? 15 : 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: VerticalDivider(
        width: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart({required this.sessions, required this.weekStart});

  final List<WorkoutSessionRecord> sessions;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final counts = List<int>.filled(7, 0);
    for (final session in sessions) {
      final date = session.publishedAt.toLocal();
      final index = DateTime(
        date.year,
        date.month,
        date.day,
      ).difference(weekStart).inDays;
      if (index >= 0 && index < counts.length) counts[index]++;
    }
    final maxCount = counts.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly activity',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.circle, size: 8, color: _homeAccent),
              const SizedBox(width: 5),
              Text(
                'Workouts',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < 7; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: maxCount == 0
                                    ? 0.08
                                    : counts[index] == 0
                                    ? 0.08
                                    : 0.2 + 0.8 * counts[index] / maxCount,
                                child: Container(
                                  width: 18,
                                  decoration: BoxDecoration(
                                    color: counts[index] == 0
                                        ? colors.outlineVariant.withValues(
                                            alpha: 0.55,
                                          )
                                        : _homeAccent.withValues(
                                            alpha:
                                                0.62 +
                                                0.38 * counts[index] / maxCount,
                                          ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  alignment: Alignment.topCenter,
                                  child: counts[index] == 0
                                      ? null
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            '${counts[index]}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            labels[index],
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

class _RecentWorkoutTile extends StatelessWidget {
  const _RecentWorkoutTile({required this.session, required this.onTap});

  final WorkoutSessionRecord session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateText = MaterialLocalizations.of(
      context,
    ).formatMediumDate(session.publishedAt.toLocal());
    final exerciseCount = session.entries
        .map((entry) => entry.exerciseName)
        .toSet()
        .length;
    final volume = _totalVolume([session]);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _homeAccent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: _homeAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateText  ·  $exerciseCount exercises',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    volume == null ? '—' : '${_formatNumber(volume)} kg',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalRecords extends StatelessWidget {
  const _PersonalRecords({required this.sessions});

  final List<WorkoutSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final weightedEntries = [
      for (final session in sessions)
        for (final entry in session.entries)
          if (entry.weightKg != null && entry.weightKg! > 0)
            (session: session, entry: entry),
    ];

    if (weightedEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: _homeAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Log weights in your workouts to see your personal records here.',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final highest = weightedEntries.reduce(
      (a, b) => a.entry.weightKg! >= b.entry.weightKg! ? a : b,
    );
    final bestByExercise =
        <String, (WorkoutSessionRecord, WorkoutSessionEntry)>{};
    for (final item in weightedEntries) {
      final existing = bestByExercise[item.entry.exerciseName];
      if (existing == null ||
          item.entry.weightKg! > existing.$2.weightKg! ||
          (item.entry.weightKg == existing.$2.weightKg &&
              item.session.publishedAt.isAfter(existing.$1.publishedAt))) {
        bestByExercise[item.entry.exerciseName] = (item.session, item.entry);
      }
    }
    final recentBest = bestByExercise.values.reduce(
      (a, b) => a.$1.publishedAt.isAfter(b.$1.publishedAt) ? a : b,
    );

    return Row(
      children: [
        Expanded(
          child: _RecordCard(
            icon: Icons.fitness_center_rounded,
            label: 'Heaviest lift',
            title: highest.entry.exerciseName,
            value: '${_formatNumber(highest.entry.weightKg!)} kg',
            date: highest.session.publishedAt,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RecordCard(
            icon: Icons.emoji_events_outlined,
            label: 'Latest best',
            title: recentBest.$2.exerciseName,
            value: '${_formatNumber(recentBest.$2.weightKg!)} kg',
            date: recentBest.$1.publishedAt,
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.value,
    required this.date,
  });

  final IconData icon;
  final String label;
  final String title;
  final String value;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateText = MaterialLocalizations.of(
      context,
    ).formatShortDate(date.toLocal());
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _homeAccent),
          const SizedBox(height: 11),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: _homeAccent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateText,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _WelcomeEmptyState extends StatelessWidget {
  const _WelcomeEmptyState({required this.onStartWorkout});

  final VoidCallback onStartWorkout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 19, 18, 17),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _homeAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt_rounded, color: _homeAccent, size: 27),
          ),
          const SizedBox(height: 12),
          Text(
            'Your training story starts here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your first workout to see your weekly activity, progress, and personal records.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 13),
          TextButton.icon(
            onPressed: onStartWorkout,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Start your first workout'),
            style: TextButton.styleFrom(
              foregroundColor: _homeAccent,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Center(child: CircularProgressIndicator(color: _homeAccent)),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

double? _totalVolume(List<WorkoutSessionRecord> sessions) {
  final entries = sessions.expand((session) => session.entries).toList();
  if (entries.isEmpty || entries.any((entry) => entry.weightKg == null)) {
    return null;
  }
  return entries.fold<double>(
    0,
    (total, entry) => total + entry.reps * entry.weightKg!,
  );
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
