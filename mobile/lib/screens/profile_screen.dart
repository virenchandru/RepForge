import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/auth_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.user,
    required this.onLogout,
    required this.loadWorkoutHistory,
    super.key,
  });

  final AppUser user;
  final Future<void> Function() onLogout;
  final Future<List<WorkoutSessionRecord>> Function() loadWorkoutHistory;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late String _name = widget.user.name.trim();
  Uint8List? _profileImage;
  List<WorkoutSessionRecord>? _sessions;
  String? _statsError;
  bool _isLoadingStats = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });
    try {
      final sessions = await widget.loadWorkoutHistory();
      if (mounted) setState(() => _sessions = sessions);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _statsError = error.message);
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _editProfile() async {
    final controller = TextEditingController(text: _name);
    final updatedName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (updatedName == null || updatedName.isEmpty || !mounted) return;
    setState(() => _name = updatedName);
    _showMessage(
      'Name updated for this session. It is not synced to your account.',
    );
  }

  Future<void> _changeProfilePicture() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _profileImage = bytes);
      _showMessage(
        'Profile picture updated for this session. It is not synced to your account.',
      );
    } on PlatformException catch (error) {
      if (mounted) _showMessage(error.message ?? 'Could not open your photos.');
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use RepForge.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB63D1F),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) await _logout();
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await widget.onLogout();
    } on AuthApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  double? get _trainingVolumeKg {
    final sessions = _sessions;
    if (sessions == null) return null;
    final entries = sessions.expand((session) => session.entries).toList();
    if (entries.isEmpty || entries.any((entry) => entry.weightKg == null)) {
      return null;
    }
    return entries.fold<double>(
      0,
      (total, entry) => total + entry.reps * entry.weightKg!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessions;
    final showVolume =
        !_isLoadingStats && _statsError == null && _trainingVolumeKg != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                color: Color(0xFF191B1D),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 27),
            _ProfileHeader(
              name: _name.isEmpty ? 'RepForge athlete' : _name,
              email: widget.user.email,
              imageBytes: _profileImage,
              onEdit: _editProfile,
            ),
            const SizedBox(height: 30),
            _SectionTitle(
              title: 'Your training',
              trailing: sessions == null
                  ? null
                  : Text(
                      '${sessions.length} total',
                      style: const TextStyle(
                        color: Color(0xFF777B80),
                        fontSize: 13,
                      ),
                    ),
            ),
            const SizedBox(height: 13),
            if (_isLoadingStats)
              const _StatsLoading()
            else if (_statsError != null)
              _StatsError(message: _statsError!, onRetry: _loadStats)
            else
              _StatsRow(
                workoutCount: sessions!.length,
                trainingVolumeKg: showVolume ? _trainingVolumeKg : null,
              ),
            const SizedBox(height: 30),
            const _SectionTitle(title: 'Account settings'),
            const SizedBox(height: 9),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit profile',
              subtitle: 'Update your display name',
              onTap: _editProfile,
            ),
            _SettingsTile(
              icon: Icons.photo_camera_outlined,
              title: 'Change profile picture',
              subtitle: 'Choose a photo from your device',
              onTap: _changeProfilePicture,
            ),
            _SettingsTile(
              icon: Icons.mail_outline_rounded,
              title: 'Email address',
              subtitle: widget.user.email,
            ),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'Preferences'),
            const SizedBox(height: 9),
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Notification controls are not available yet',
              onTap: () => _showInfo(
                'Notifications',
                'Notification preferences are not available in this version.',
              ),
            ),
            _SettingsTile(
              icon: Icons.light_mode_outlined,
              title: 'Appearance',
              subtitle: 'Light theme',
              onTap: () => _showInfo(
                'Appearance',
                'RepForge currently uses the light theme.',
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'About'),
            const SizedBox(height: 9),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About RepForge',
              subtitle: 'Strength training, made consistent',
              onTap: () => _showInfo(
                'About RepForge',
                'RepForge helps you record workouts and keep track of your training.',
              ),
            ),
            const _SettingsTile(
              icon: Icons.apps_rounded,
              title: 'App version',
              subtitle: '1.0.0',
            ),
            const SizedBox(height: 25),
            const Divider(height: 1, color: Color(0xFFE9EAEC)),
            const SizedBox(height: 17),
            OutlinedButton.icon(
              onPressed: _isLoggingOut ? null : _confirmLogout,
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: const Text('Keluar dari akun'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB63D1F),
                side: const BorderSide(color: Color(0xFFF0D7D0)),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInfo(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.imageBytes,
    required this.onEdit,
  });

  final String name;
  final String email;
  final Uint8List? imageBytes;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFFFEEE7),
          backgroundImage: imageBytes == null ? null : MemoryImage(imageBytes!),
          child: imageBytes == null
              ? const Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: Color(0xFFDA5A2A),
                )
              : null,
        ),
        const SizedBox(height: 13),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF191B1D),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF777B80), fontSize: 14),
        ),
        const SizedBox(height: 15),
        OutlinedButton(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDA5A2A),
            side: const BorderSide(color: Color(0xFFF0D7D0)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Edit profile',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF202326),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.workoutCount, this.trainingVolumeKg});

  final int workoutCount;
  final double? trainingVolumeKg;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _TrainingStat(value: '$workoutCount', label: 'Workouts'),
      _TrainingStat(value: '$workoutCount', label: 'Training sessions'),
      if (trainingVolumeKg != null)
        _TrainingStat(
          value: _formatVolume(trainingVolumeKg!),
          label: 'Training volume',
          unit: 'kg',
        ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            if (index > 0)
              const SizedBox(
                height: 38,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFE5E6E7),
                ),
              ),
            Expanded(child: stats[index]),
          ],
        ],
      ),
    );
  }

  String _formatVolume(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _TrainingStat extends StatelessWidget {
  const _TrainingStat({required this.value, required this.label, this.unit});

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1D2022),
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Text(
                unit!,
                style: const TextStyle(
                  color: Color(0xFF777B80),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF777B80), fontSize: 11),
        ),
      ],
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 88,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFDA5A2A),
          ),
        ),
      ),
    );
  }
}

class _StatsError extends StatelessWidget {
  const _StatsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFF777B80)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF555A5F), fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF575C61)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF25282B),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF85898E), fontSize: 12),
      ),
      trailing: onTap == null
          ? null
          : const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF9A9DA1),
            ),
      onTap: onTap,
    );
  }
}
