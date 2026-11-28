import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/auth_api.dart';
import '../models/profile_photo.dart';
import '../widgets/profile_photo_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.user,
    required this.onLogout,
    required this.loadWorkoutHistory,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.profilePhoto,
    required this.onProfilePhotoChanged,
    super.key,
  });

  final AppUser user;
  final Future<void> Function() onLogout;
  final Future<List<WorkoutSessionRecord>> Function() loadWorkoutHistory;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final ProfilePhoto? profilePhoto;
  final ValueChanged<ProfilePhoto> onProfilePhotoChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late String _name = widget.user.name.trim();
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
      final crop = await showDialog<_PhotoCrop>(
        context: context,
        builder: (context) => _PhotoCropDialog(imageBytes: bytes),
      );
      if (crop == null || !mounted) return;
      widget.onProfilePhotoChanged(
        ProfilePhoto(bytes: bytes, scale: crop.scale, offset: crop.offset),
      );
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
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          children: [
            Text(
              'Profile',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 27),
            _ProfileHeader(
              name: _name.isEmpty ? 'RepForge athlete' : _name,
              email: widget.user.email,
              profilePhoto: widget.profilePhoto,
              onEdit: _editProfile,
            ),
            const SizedBox(height: 30),
            _SectionTitle(
              title: 'Your training',
              trailing: sessions == null
                  ? null
                  : Text(
                      '${sessions.length} total',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
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
              icon: widget.isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              title: 'Appearance',
              subtitle: widget.isDarkMode ? 'Dark theme' : 'Light theme',
              trailing: Switch.adaptive(
                value: widget.isDarkMode,
                activeThumbColor: colors.primary,
                onChanged: widget.onThemeChanged,
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
            Divider(height: 1, color: colors.outlineVariant),
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
                foregroundColor: colors.error,
                side: BorderSide(color: colors.outlineVariant),
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
    required this.profilePhoto,
    required this.onEdit,
  });

  final String name;
  final String email;
  final ProfilePhoto? profilePhoto;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        ProfilePhotoAvatar(photo: profilePhoto, radius: 48),
        const SizedBox(height: 13),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 15),
        OutlinedButton(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.outlineVariant),
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

class _PhotoCrop {
  const _PhotoCrop({required this.scale, required this.offset});

  final double scale;
  final Offset offset;
}

class _PhotoCropDialog extends StatefulWidget {
  const _PhotoCropDialog({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_PhotoCropDialog> createState() => _PhotoCropDialogState();
}

class _PhotoCropDialogState extends State<_PhotoCropDialog> {
  static const _cropSize = 240.0;
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyCrop() {
    final transform = _controller.value;
    Navigator.pop(
      context,
      _PhotoCrop(
        scale: transform.getMaxScaleOnAxis(),
        offset: Offset(
          transform.entry(0, 3) / _cropSize,
          transform.entry(1, 3) / _cropSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Atur foto profil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Geser untuk mengatur posisi dan cubit untuk memperbesar.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ClipOval(
            child: SizedBox(
              width: _cropSize,
              height: _cropSize,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 4,
                constrained: false,
                child: SizedBox(
                  width: _cropSize,
                  height: _cropSize,
                  child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Icon(Icons.zoom_out_map_rounded, color: colors.onSurfaceVariant),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _applyCrop, child: const Text('Pakai foto')),
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
    final colors = Theme.of(context).colorScheme;
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
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            if (index > 0)
              SizedBox(
                height: 38,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colors.outlineVariant,
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
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Text(
                unit!,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
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
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
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
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: colors.onSurfaceVariant),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
      ),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                )),
      onTap: onTap,
    );
  }
}
