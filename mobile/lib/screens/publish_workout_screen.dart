import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/auth_api.dart';
import '../models/workout_session.dart';

class PublishWorkoutScreen extends StatefulWidget {
  const PublishWorkoutScreen({
    required this.session,
    required this.onPublish,
    super.key,
  });

  final WorkoutSession session;
  final Future<WorkoutSessionRecord> Function({
    required String title,
    required List<WorkoutSetPayload> entries,
    XFile? photo,
  })
  onPublish;

  @override
  State<PublishWorkoutScreen> createState() => _PublishWorkoutScreenState();
}

class _PublishWorkoutScreenState extends State<PublishWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _photo;
  Uint8List? _photoBytes;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = photo;
        _photoBytes = bytes;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Gagal membuka galeri foto.')),
      );
    }
  }

  Future<void> _publish() async {
    if (_isPublishing || !_formKey.currentState!.validate()) return;
    final entries = [
      for (final exercise in widget.session.exercises)
        for (final set in exercise.sets)
          WorkoutSetPayload(
            exerciseName: exercise.name,
            setNumber: set.number,
            reps: int.parse(set.reps),
            weightKg: set.weightKg.trim().isEmpty
                ? null
                : double.parse(set.weightKg),
          ),
    ];

    setState(() => _isPublishing = true);
    try {
      await widget.onPublish(
        title: _titleController.text.trim(),
        entries: entries,
        photo: _photo,
      );
      if (mounted) Navigator.pop(context, true);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish Workout')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                key: const ValueKey<String>('workout-title'),
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Judul workout',
                  hintText: 'Contoh: Leg day',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul workout wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'FOTO WORKOUT (OPSIONAL)',
                style: TextStyle(
                  color: Color(0xFF777A73),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              if (_photoBytes case final bytes?)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(
                    bytes,
                    height: 220,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              else
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3D7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.photo_outlined,
                    size: 44,
                    color: Color(0xFF171A17),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPublishing ? null : _choosePhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(_photo == null ? 'Pilih foto' : 'Ganti foto'),
                    ),
                  ),
                  if (_photo != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Hapus foto',
                      onPressed: _isPublishing
                          ? null
                          : () => setState(() {
                              _photo = null;
                              _photoBytes = null;
                            }),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              Text(
                '${widget.session.exercises.length} latihan · '
                '${widget.session.setCount} set',
                style: const TextStyle(
                  color: Color(0xFF171A17),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final exercise in widget.session.exercises)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '${exercise.name} · '
                    '${exercise.sets.map((set) => set.reps).join('/')} reps',
                    style: const TextStyle(color: Color(0xFF777A73)),
                  ),
                ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _isPublishing ? null : _publish,
                icon: _isPublishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFC9F36A),
                        ),
                      )
                    : const Icon(Icons.publish_rounded),
                label: Text(
                  _isPublishing ? 'Publishing...' : 'Publish workout',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFF171A17),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
