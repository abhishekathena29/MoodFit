import 'package:flutter/material.dart';

import '../models/palette.dart';
import '../theme/app_colors.dart';

/// A palette's swatch — a single fill for one-hue schemes, or equal
/// vertical bands for harmonies (complementary, triadic, tetradic) so the
/// combination itself is visible. Unknown or missing palettes render as a
/// faint placeholder.
class PaletteSwatch extends StatelessWidget {
  final String? palette;
  final double size;
  final double radius;

  const PaletteSwatch({super.key, required this.palette, required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    final colors = paletteByKey(palette)?.swatch ?? [AppColors.muted];
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Row(
          children: colors.map((c) => Expanded(child: ColoredBox(color: c))).toList(),
        ),
      ),
    );
  }
}
