import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/staff.dart';
import '../services/staff_photo_service.dart';
import '../theme/aby_colors.dart';

/// "Ama Mensah" → "AM".
String initialsOf(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .take(2)
    .map((w) => w[0].toUpperCase())
    .join();

/// A person's photo, or their initials on midnight.
class StaffAvatar extends StatelessWidget {
  const StaffAvatar({super.key, required this.staff, this.radius = 18});

  final Staff staff;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: staff.active ? c.primary : c.lineStrong,
      child: Text(
        initialsOf(staff.name),
        style: TextStyle(color: c.onPrimary, fontWeight: FontWeight.w800, fontSize: radius * 0.75),
      ),
    );
    if (!Get.isRegistered<StaffPhotoService>()) return fallback;
    final service = Get.find<StaffPhotoService>();
    return Obx(() {
      final photos = service.photos;
      if (!photos.containsKey(staff.id)) {
        service.load(staff.id);
        return fallback;
      }
      final image = photos[staff.id];
      if (image == null) return fallback;
      return CircleAvatar(radius: radius, backgroundImage: MemoryImage(image));
    });
  }
}
