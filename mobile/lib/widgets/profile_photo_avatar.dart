import 'package:flutter/material.dart';

import '../models/profile_photo.dart';

class ProfilePhotoAvatar extends StatelessWidget {
  const ProfilePhotoAvatar({
    required this.photo,
    required this.radius,
    this.accentColor,
    super.key,
  });

  final ProfilePhoto? photo;
  final double radius;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = accentColor ?? colors.primary;
    final size = radius * 2;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: photo == null
            ? ColoredBox(
                color: accent.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, size: radius, color: accent),
              )
            : Transform(
                alignment: Alignment.topLeft,
                transform: Matrix4.identity()
                  ..setEntry(0, 0, photo!.scale)
                  ..setEntry(1, 1, photo!.scale)
                  ..setEntry(0, 3, photo!.offset.dx * size)
                  ..setEntry(1, 3, photo!.offset.dy * size),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Image.memory(photo!.bytes, fit: BoxFit.cover),
                ),
              ),
      ),
    );
  }
}
