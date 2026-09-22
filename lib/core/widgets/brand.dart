import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Climavent belgisi (vektor).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/brand/belgi.svg', width: size, height: size);
}

/// Belgi + "Climavent" yozuvi. Qorong'i fonda oq yozuv.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.height = 32, this.onDark});

  final double height;

  /// null — mavzuga qarab.
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final dark = onDark ?? Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: height),
        SizedBox(width: height * 0.3),
        Image.asset(
          dark ? 'assets/brand/soz-oq.png' : 'assets/brand/soz-qora.png',
          height: height * 0.62,
          filterQuality: FilterQuality.high,
        ),
      ],
    );
  }
}
