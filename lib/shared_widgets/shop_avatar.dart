import 'package:flexiphones/shared_widgets/generalwidgets.dart';
import 'package:flutter/material.dart';

/// A shop's picture (`image_url`) in a circle; when there's no picture, or
/// it fails to load, the shop's first letter on a colour picked from the
/// name. Used everywhere a vendor appears.
class ShopAvatar extends StatelessWidget {
  const ShopAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.border = false,
  });

  final String name;
  final String? imageUrl;
  final double size;

  /// White ring, for avatars sitting on photos or dark cards.
  final bool border;

  static const _tints = [
    [Color(0xFF2E8BFF), Color(0xFF8E5CFF)],
    [Color(0xFFFF9F0A), Color(0xFFFF375F)],
    [Color(0xFF30D158), Color(0xFF0A84FF)],
    [Color(0xFFBF5AF2), Color(0xFFFF6482)],
  ];

  @override
  Widget build(BuildContext context) {
    final n = name.trim();
    final tint = _tints[(n.isEmpty ? 0 : n.codeUnitAt(0)) % _tints.length];
    final letter = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: tint,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        n.isEmpty ? "?" : n[0].toUpperCase(),
        style: ptstyle(size: size * 0.42, weight: 800, color: Colors.white),
      ),
    );
    final url = imageUrl ?? "";
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border ? Border.all(color: Colors.white, width: size * 0.06) : null,
        boxShadow:
            border
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: size * 0.2,
                    offset: Offset(0, size * 0.06),
                  ),
                ]
                : null,
      ),
      child: ClipOval(
        child:
            url.isEmpty
                ? letter
                : Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  // The address changes when the shop changes its picture,
                  // so caching by address is safe.
                  errorBuilder: (_, _, _) => letter,
                  loadingBuilder:
                      (_, child, progress) => progress == null ? child : letter,
                ),
      ),
    );
  }
}
