import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class ProfilePhoto {
  const ProfilePhoto({
    required this.bytes,
    required this.scale,
    required this.offset,
  });

  final Uint8List bytes;
  final double scale;
  final Offset offset;
}
